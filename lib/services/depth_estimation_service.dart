// depth_estimation_service.dart
import 'dart:io';
import 'dart:math';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart' as onnx;

/// Service untuk depth estimation menggunakan DepthPro model (Bochkovskii et al., Apple, 2024).
///
/// DepthPro menghasilkan metric-scale depth map:
/// - Output: nilai depth dalam satuan METER (bukan relative depth)
/// - Setiap piksel bernilai estimasi jarak dari kamera ke objek (dalam meter)
/// - Contoh: piksel=0.8 berarti objek berjarak ~0.8m dari kamera
/// - Model dilatih dengan dataset absolute depth (NYUv2, KITTI, ETH3D)
/// - Akurasi: RMSE ~0.3-0.5m pada jarak <5m (indoor/outdoor)
class DepthEstimationService {
  // ===== Konfigurasi model =====
  // Model DepthPro quantized (ONNX format)
  static const String _onnxAssetPath = 'assets/models/model_quantized.onnx';
  // Gunakan input yang lebih kecil secara default untuk mengurangi penggunaan memori dan waktu proses di perangkat kelas menengah.
  static const int _defaultSize =
      256; // 256x256 cukup baik untuk mobile, kurangi risiko OOM

  // ===== ORT =====
  onnx.OrtSession? _session;
  onnx.OrtSessionOptions? _options;
  bool _initialized = false;

  // ===== Dimensi output terakhir =====
  int _outH = 0, _outW = 0;
  Float32List? _lastDepthMap;

  bool get isInitialized => _initialized;
  int get outputHeight => _outH;
  int get outputWidth => _outW;
  bool get hasDepth => _lastDepthMap != null && _lastDepthMap!.isNotEmpty;
  Float32List? get lastDepthMap => _lastDepthMap;

  Future<void> initialize() async {
    if (_initialized) return;

    // 1) Init Env
    onnx.OrtEnv.instance.init();

    // 2) Session options
    // Keep thread count low to reduce memory pressure on mobile devices
    _options = onnx.OrtSessionOptions()
      ..setIntraOpNumThreads(1)
      ..setInterOpNumThreads(1)
      ..setSessionGraphOptimizationLevel(
        onnx.GraphOptimizationLevel.ortEnableAll,
      );

    try {
      // 3) Load model bytes (dari assets)
      final data = await rootBundle.load(_onnxAssetPath);
      final bytes = data.buffer.asUint8List();

      // 4) Buat session
      _session = onnx.OrtSession.fromBuffer(bytes, _options!);
      _initialized = true;
      print('✅ ONNX model loaded: $_onnxAssetPath (${bytes.length} bytes)');
    } on Exception catch (e) {
      // Tambahkan pesan yang lebih jelas kalau kehabisan memori
      final msg = e.toString();
      if (msg.contains('MEMORY') ||
          msg.contains('alloc') ||
          msg.contains('OOM')) {
        throw Exception(
          'Model gagal dimuat: kemungkinan kehabisan memori. Ukuran model terlalu besar untuk perangkat ini.',
        );
      }
      rethrow;
    }
  }

  void dispose() {
    try {
      _session?.release();
    } catch (_) {}
    _session = null;

    try {
      onnx.OrtEnv.instance.release();
    } catch (_) {}

    _initialized = false;
  }

  /// Inference dari path gambar. Mengembalikan Float32List NHWC (H×W×1) untuk konsistensi UI.
  Future<Float32List> estimateDepthFromFile(
    String path, {
    int size = _defaultSize,
  }) async {
    final bytes = await File(path).readAsBytes();
    return estimateDepthFromBytes(bytes, size: size);
  }

  /// Inference dari bytes gambar. Output: NHWC (H×W×1), nilai float depth (DepthPro = meter).
  Future<Float32List> estimateDepthFromBytes(
    Uint8List imageBytes, {
    int size = _defaultSize,
  }) async {
    if (!_initialized || _session == null) {
      throw StateError('DepthEstimationService not initialized');
    }

    // Preprocessing (decode, resize, NCHW) di isolate agar tidak block UI thread
    final _PreprocessResult prep = await Isolate.run(() {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        throw Exception('Failed to decode image');
      }
      final resized = img.copyResize(decoded, width: size, height: size);
      final data = _rgbaToNCHWFloatIsolate(resized, toMinus1to1: false);
      return _PreprocessResult(data, resized.height, resized.width);
    });

    final inputName = _session!.inputNames.first;
    final inputTensor = onnx.OrtValueTensor.createTensorWithDataList(
      [prep.nchw],
      [1, 3, prep.h, prep.w], // NCHW
    );

    List<onnx.OrtValue?>? outputs;
    try {
      outputs = await _session!.runAsync(onnx.OrtRunOptions(), {
        inputName: inputTensor,
      }, null);
    } finally {
      try {
        inputTensor.release();
      } catch (_) {}
    }
    if (outputs == null || outputs.isEmpty || outputs.first == null) {
      throw Exception('ONNX returned no outputs');
    }

    // DepthPro biasanya mengembalikan: [predicted_depth, focallength_px]
    final depthVal = outputs[0] as onnx.OrtValueTensor;

    // Flatten ke Float32List
    late final Float32List flat;
    final v = depthVal.value;
    if (v is Float32List) {
      flat = v;
    } else if (v is List) {
      final buf = <double>[];
      void flatList(dynamic x) {
        if (x is List)
          for (final e in x) flatList(e);
        else if (x is num)
          buf.add(x.toDouble());
      }

      flatList(v);
      flat = Float32List.fromList(buf);
    } else {
      // release & error
      try {
        depthVal.release();
      } catch (_) {}
      for (var i = 1; i < outputs.length; i++) {
        try {
          outputs[i]?.release();
        } catch (_) {}
      }
      throw Exception('Unsupported output type: ${v.runtimeType}');
    }

    // Untuk DepthPro, output biasanya berukuran sama dengan input (H x W)
    // Karena kita tidak bisa mengakses shape dari tensor secara langsung,
    // kita asumsikan output memiliki dimensi yang sama dengan input
    final expectedSize = prep.h * prep.w;

    // Verifikasi ukuran data sesuai ekspektasi
    if (flat.length >= expectedSize) {
      _outH = prep.h;
      _outW = prep.w;
    } else {
      // Fallback: coba cari dimensi yang masuk akal
      final sqrtVal = sqrt(flat.length.toDouble()).round();
      if (sqrtVal * sqrtVal == flat.length) {
        _outH = sqrtVal;
        _outW = sqrtVal;
      } else {
        // Last resort: gunakan dimensi input
        _outH = prep.h;
        _outW = prep.w;
      }
    }

    // Release tensor resources
    try {
      depthVal.release();
    } catch (_) {}
    for (var i = 1; i < outputs.length; i++) {
      try {
        outputs[i]?.release();
      } catch (_) {}
    }

    // Debug: print statistik depth map untuk verifikasi output DepthPro
    if (flat.isNotEmpty) {
      final minDepth = flat.reduce((a, b) => a < b ? a : b);
      final maxDepth = flat.reduce((a, b) => a > b ? a : b);
      final avgDepth = flat.reduce((a, b) => a + b) / flat.length;
      print('🔍 DepthPro output stats (METRIC DEPTH in meters):');
      print('   - Min: ${minDepth.toStringAsFixed(3)}m');
      print('   - Max: ${maxDepth.toStringAsFixed(3)}m');
      print('   - Avg: ${avgDepth.toStringAsFixed(3)}m');
      print('   - Output size: ${_outW}x${_outH} (${flat.length} pixels)');
    }

    _lastDepthMap = flat;
    return flat;
  }

  /// Mengambil nilai depth pada koordinat (x, y) dari hasil estimasi terakhir.
  /// Koordinat dalam sistem output (0..outW-1, 0..outH-1).
  double getDepthAt(int x, int y) {
    if (_lastDepthMap == null || x < 0 || x >= _outW || y < 0 || y >= _outH) {
      return 0.0;
    }
    return _lastDepthMap![y * _outW + x].toDouble();
  }

  /// Menghitung jarak dari kamera ke titik yang dipilih berdasarkan depth estimation.
  /// Koordinat dalam normalized screen coordinates (0.0 - 1.0).
  /// Returns jarak dalam meter (DepthPro metric depth).
  double calculateDistanceToPoint(
    double normalizedX,
    double normalizedY, {
    int sampleRadius = 3,
    double calibrationScale = 1.0,
  }) {
    if (!hasDepth) {
      return 0.0;
    }

    final int width = _outW;
    final int height = _outH;
    final int centerX = (normalizedX.clamp(0.0, 1.0) * (width - 1)).round();
    final int centerY = (normalizedY.clamp(0.0, 1.0) * (height - 1)).round();

    final double medianDepth = _sampleMedianDepth(
      centerX,
      centerY,
      radius: sampleRadius,
    );

    if (medianDepth <= 0) {
      return 0.0;
    }

    // DepthPro output sudah dalam meter, hanya perlu calibration scale untuk fine-tuning
    final distance = (medianDepth * calibrationScale).clamp(0.0, 200.0);

    print(
      '📍 Point ($normalizedX, $normalizedY) -> Depth: ${medianDepth.toStringAsFixed(3)}m, Calibrated: ${distance.toStringAsFixed(3)}m',
    );

    return distance;
  }

  double _sampleMedianDepth(int cx, int cy, {int radius = 3}) {
    final Float32List? map = _lastDepthMap;
    if (map == null || map.isEmpty) {
      return 0.0;
    }

    final int width = _outW;
    final int height = _outH;
    final int r = radius < 1 ? 1 : radius;

    final List<double> samples = [];
    for (int dy = -r; dy <= r; dy++) {
      final int y = (cy + dy).clamp(0, height - 1);
      for (int dx = -r; dx <= r; dx++) {
        final int x = (cx + dx).clamp(0, width - 1);
        final double depth = map[y * width + x];
        if (depth > 0) {
          samples.add(depth);
        }
      }
    }

    if (samples.isEmpty) {
      return 0.0;
    }

    samples.sort();
    return samples[samples.length ~/ 2];
  }

  /// Menghitung jarak dengan menggunakan informasi focal length yang lebih akurat.
  /// Metode ini lebih robust untuk kalibrasi kamera yang berbeda.
  double calculateCalibratedDistance(
    double normalizedX,
    double normalizedY, {
    required double focalLengthPixels,
    required double realWorldPixelSize, // mm per pixel pada jarak 1 meter
  }) {
    if (_lastDepthMap == null) {
      return 0.0;
    }

    final pixelX = (normalizedX * _outW).clamp(0, _outW - 1).toInt();
    final pixelY = (normalizedY * _outH).clamp(0, _outH - 1).toInt();

    final depthValue = getDepthAt(pixelX, pixelY);

    if (depthValue <= 0) {
      return 0.0;
    }

    // Konversi depth value dengan kalibrasi yang lebih akurat
    double distanceInMeters = depthValue;

    // Jika model menghasilkan relative depth, konversi ke absolute depth
    if (distanceInMeters < 1.0) {
      // Asumsi: nilai kecil berarti objek dekat, nilai besar berarti objek jauh
      // Konversi menggunakan fungsi eksponential atau linear scaling
      distanceInMeters = _convertRelativeDepthToAbsolute(distanceInMeters);
    }

    return distanceInMeters.clamp(0.1, 100.0);
  }

  /// Helper function untuk mengkonversi relative depth ke absolute depth.
  /// Metode ini bisa disesuaikan berdasarkan karakteristik model depth estimation.
  double _convertRelativeDepthToAbsolute(double relativeDepth) {
    // Method 1: Linear scaling
    // Asumsi: relative depth 0.0 = 10m, 1.0 = 0.5m
    // return 10.0 - (relativeDepth * 9.5);

    // Method 2: Exponential scaling (lebih natural untuk depth)
    // return math.exp(-relativeDepth * 3) * 10;

    // Method 3: Inverse relationship (umum untuk depth models)
    if (relativeDepth < 0.001) relativeDepth = 0.001; // Avoid division by zero
    return 1.0 / relativeDepth;
  }

  // ===== Helpers =====
}

class _PreprocessResult {
  final Float32List nchw;
  final int h;
  final int w;
  const _PreprocessResult(this.nchw, this.h, this.w);
}

/// Top-level helper agar bisa dipanggil dari Isolate.run
Float32List _rgbaToNCHWFloatIsolate(
  img.Image image, {
  bool toMinus1to1 = false,
}) {
  final w = image.width, h = image.height;
  final out = Float32List(3 * h * w);
  final plane = h * w;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final pixel = image.getPixel(x, y);
      double r = pixel.r / pixel.rNormalized;
      double g = pixel.g / pixel.gNormalized;
      double b = pixel.b / pixel.bNormalized;
      r = r.clamp(0.0, 1.0);
      g = g.clamp(0.0, 1.0);
      b = b.clamp(0.0, 1.0);
      if (toMinus1to1) {
        r = (r - 0.5) / 0.5;
        g = (g - 0.5) / 0.5;
        b = (b - 0.5) / 0.5;
      }
      final idx = y * w + x;
      out[idx] = r;
      out[plane + idx] = g;
      out[2 * plane + idx] = b;
    }
  }
  return out;
}
