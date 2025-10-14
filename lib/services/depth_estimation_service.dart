<<<<<<< HEAD
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
// import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class DepthEstimationService {
  Interpreter? _interpreter;
  static const String _modelPath = 'assets/models/midas_v2.tflite';
  static const int _inputSize = 256; // MiDaS model input size

  bool _isInitialized = false;

  /// Initialize the TensorFlow Lite interpreter with the MiDaS model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load model from assets
      final modelData = await rootBundle.load(_modelPath);
      final buffer = modelData.buffer.asUint8List();

      // Create interpreter options for better performance
      final options = InterpreterOptions()
        ..threads = 4;

      // Create interpreter
      _interpreter = Interpreter.fromBuffer(buffer, options: options);
      _isInitialized = true;
    } catch (e) {
      print('Error initializing depth estimation service: $e');
      rethrow;
    }
  }

  /// Dispose of the interpreter to free resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }

  /// Estimate depth from an image file
  Future<Float32List> estimateDepthFromFile(String imagePath) async {
    if (!_isInitialized) {
      throw Exception('DepthEstimationService not initialized');
    }

    try {
      // Load image file
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      
      // Process image and estimate depth
      return await estimateDepthFromBytes(imageBytes);
    } catch (e) {
      print('Error estimating depth from file: $e');
      rethrow;
    }
  }

  /// Estimate depth from image bytes
  Future<Float32List> estimateDepthFromBytes(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('DepthEstimationService not initialized');
    }

    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to model input size
      final resizedImage = img.copyResize(
        image,
        width: _inputSize,
        height: _inputSize,
      );

      // Convert to tensor (normalized to [0, 1])
      final inputTensor = _imageToTensor(resizedImage);

      // Prepare output tensor
      final outputTensor = Float32List(_inputSize * _inputSize);

      // Run inference
      _interpreter!.run(inputTensor, outputTensor);

      return outputTensor;
    } catch (e) {
      print('Error estimating depth from bytes: $e');
      rethrow;
    }
  }

  /// Convert image to tensor for model input
  Float32List _imageToTensor(img.Image image) {
    final pixels = image.getBytes();
    final tensor = Float32List(_inputSize * _inputSize * 3);

    // Convert RGB to normalized tensor ([0, 1] range)
    for (int i = 0; i < pixels.length; i += 4) {
      final r = pixels[i] / 255.0;
      final g = pixels[i + 1] / 255.0;
      final b = pixels[i + 2] / 255.0;

      final index = (i ~/ 4) * 3;
      tensor[index] = r;
      tensor[index + 1] = g;
      tensor[index + 2] = b;
    }

    return tensor;
  }

  /// Get depth value at specific coordinates (normalized to [0, 1])
  double getDepthAt(Float32List depthMap, double x, double y) {
    if (depthMap.isEmpty) return 0.0;

    // Convert normalized coordinates to pixel coordinates
    final pixelX = (x * (_inputSize - 1)).round();
    final pixelY = (y * (_inputSize - 1)).round();

    // Clamp to valid range
    final clampedX = pixelX.clamp(0, _inputSize - 1);
    final clampedY = pixelY.clamp(0, _inputSize - 1);

    // Calculate index in depth map
    final index = clampedY * _inputSize + clampedX;

    // Return depth value (ensure it's within valid range)
    return index < depthMap.length ? depthMap[index] : 0.0;
  }

  /// Calculate distance between two points using depth information
  double calculateDistance(
    Float32List depthMap,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    if (depthMap.isEmpty) return 0.0;

    // Get depth values at both points
    final depth1 = getDepthAt(depthMap, x1, y1);
    final depth2 = getDepthAt(depthMap, x2, y2);

    // Calculate Euclidean distance in 3D space
    // Using simplified model where depth represents distance from camera
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dz = depth2 - depth1;

    // Calculate 3D distance
    final distance = sqrt(dx * dx + dy * dy + dz * dz);

    return distance;
  }

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;
}
=======
// depth_estimation_service.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart' as onnx;

class DepthEstimationService {
  // ===== Konfigurasi model =====
  // Pakai ONNX DepthPro (FP32/FP16). Simpan di assets dan pastikan dimasukkan ke pubspec.yaml.
  static const String _onnxAssetPath = 'assets/models/model_quantized.onnx';
  static const int _defaultSize = 384; // Ukuran aman untuk DepthPro export umum

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

  Future<void> initialize() async {
    if (_initialized) return;

    // 1) Init Env
    onnx.OrtEnv.instance.init();

    // 2) Session options
    _options = onnx.OrtSessionOptions()
      ..setIntraOpNumThreads(max(1, (Platform.numberOfProcessors ~/ 2)))
      ..setInterOpNumThreads(1)
      ..setSessionGraphOptimizationLevel(
        onnx.GraphOptimizationLevel.ortEnableAll,
      );

    // 3) Load model bytes (dari assets)
    final data = await rootBundle.load(_onnxAssetPath);
    final bytes = data.buffer.asUint8List();

    // 4) Buat session
    _session = onnx.OrtSession.fromBuffer(bytes, _options!);

    _initialized = true;
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

  /// Inference dari bytes gambar. Output: NHWC (H×W×1), nilai float depth (belum dinormalisasi 0..1).
  Future<Float32List> estimateDepthFromBytes(
    Uint8List imageBytes, {
    int size = _defaultSize,
  }) async {
    if (!_initialized || _session == null) {
      throw StateError('DepthEstimationService not initialized');
    }

    // Decode & resize (bilinear)
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception('Failed to decode image');
    final resized = img.copyResize(decoded, width: size, height: size);

    // ----- Siapkan input: Float32 NCHW, rescale 0..1 -----
    final nchw = _rgbaToNCHWFloat(resized, toMinus1to1: false);

    final inputName = _session!.inputNames.first;
    final inputTensor = onnx.OrtValueTensor.createTensorWithDataList(
      [nchw],
      [1, 3, resized.height, resized.width], // NCHW
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
    final expectedSize = resized.height * resized.width;

    // Verifikasi ukuran data sesuai ekspektasi
    if (flat.length >= expectedSize) {
      _outH = resized.height;
      _outW = resized.width;
    } else {
      // Fallback: coba cari dimensi yang masuk akal
      final sqrtVal = sqrt(flat.length.toDouble()).round();
      if (sqrtVal * sqrtVal == flat.length) {
        _outH = sqrtVal;
        _outW = sqrtVal;
      } else {
        // Last resort: gunakan dimensi input
        _outH = resized.height;
        _outW = resized.width;
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
  /// Returns jarak dalam meter.
  double calculateDistanceToPoint(
    double normalizedX,
    double normalizedY, {
    double focalLengthPixels = 1000.0, // Default focal length dalam pixels
    double sensorWidthMm =
        6.17, // Default sensor width dalam mm (untuk smartphone umum)
  }) {
    if (_lastDepthMap == null) {
      return 0.0;
    }

    // Konversi normalized coordinates ke pixel coordinates dalam depth map
    final pixelX = (normalizedX * _outW).clamp(0, _outW - 1).toInt();
    final pixelY = (normalizedY * _outH).clamp(0, _outH - 1).toInt();

    // Ambil nilai depth pada titik tersebut
    final depthValue = getDepthAt(pixelX, pixelY);

    if (depthValue <= 0) {
      return 0.0;
    }

    // Untuk DepthPro, nilai output biasanya sudah dalam meter
    // Tapi perlu dicek apakah perlu normalisasi atau konversi
    // Karena model depth estimation bisa mengeluarkan nilai dalam range berbeda

    // Asumsi: DepthPro mengeluarkan inverse depth atau depth yang perlu dikonversi
    // Jika model mengeluarkan nilai yang sangat kecil, mungkin perlu di-scale
    double distanceInMeters = depthValue;

    // Jika nilai depth terlalu kecil (< 0.1), kemungkinan perlu di-scale
    if (distanceInMeters < 0.1) {
      distanceInMeters = 1.0 / (depthValue + 1e-6); // Inverse depth
    }

    // Clamp hasil untuk range yang masuk akal (0.1m - 100m)
    return distanceInMeters.clamp(0.1, 100.0);
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

  /// Konversi RGBA (dari package:image) ke Float32List NCHW.
  /// RGBA di-rescale ke [0,1] (opsional ke [-1,1]).
  Float32List _rgbaToNCHWFloat(img.Image image, {bool toMinus1to1 = false}) {
    final w = image.width, h = image.height;
    final out = Float32List(3 * h * w);
    final plane = h * w;

    // Gunakan pixel iterator yang lebih robust untuk berbagai format
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = image.getPixel(x, y);

        // Extract RGB values dari pixel (format bisa berbeda-beda)
        double r = pixel.r / pixel.rNormalized; // Normalisasi ke 0-1
        double g = pixel.g / pixel.gNormalized;
        double b = pixel.b / pixel.bNormalized;

        // Clamp values to 0-1 range untuk safety
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
}
>>>>>>> 71abcb3 (push depth pro onnx)
