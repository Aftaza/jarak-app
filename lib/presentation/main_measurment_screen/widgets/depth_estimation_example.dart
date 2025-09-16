import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Example widget demonstrating depth estimation with MiDaS model
class DepthEstimationExample extends StatefulWidget {
  const DepthEstimationExample({super.key});

  @override
  _DepthEstimationExampleState createState() => _DepthEstimationExampleState();
}

class _DepthEstimationExampleState extends State<DepthEstimationExample> {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  String _status = 'Loading model...';
  Float32List? _depthMap;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  /// Load the MiDaS model from assets
  Future<void> _loadModel() async {
    try {
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/models/midas_v2.tflite', // Pastikan nama file ini sesuai
        options: options,
      );

      if (_interpreter != null) {
        setState(() {
          _isModelLoaded = true;
          _status = 'Model loaded successfully!';
        });
      } else {
        setState(() {
          _status = 'Failed to load model: Interpreter is null.';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Failed to load model: $e';
      });
      _interpreter = null;
    }
  }

  /// Process an image with the depth estimation model
  Future<Float32List?> _processImage() async {
    if (!_isModelLoaded || _interpreter == null) {
      return null;
    }

    try {
      // Dapatkan informasi tentang input dan output tensor
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      // Siapkan input dummy yang memiliki dimensi sesuai dengan model.
      final inputShape = inputTensor.shape;
      final int height = inputShape[1];
      final int width = inputShape[2];
      final int channels = inputShape[3];

      // Buat Float32List dengan ukuran yang benar
      final input = Float32List(height * width * channels);
      for (int i = 0; i < input.length; i++) {
        input[i] = i / input.length;
      }

      // Bungkus input dalam List<Object>
      final inputList = [input.reshape([1, height, width, channels])];

      // Alokasikan memori untuk output
      final output = Float32List(outputTensor.shape.reduce((a, b) => a * b));

      // Jalankan inferensi
      _interpreter!.run(inputList, output.reshape(outputTensor.shape));

      return output;
    } catch (e) {
      debugPrint('Error processing image: $e');
      return null;
    }
  }

  /// Visualize depth map
  Widget _buildDepthVisualization(Float32List? depthMap) {
    if (depthMap == null || depthMap.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(
          child: Text('No depth data available'),
        ),
      );
    }
    
    return Container(
      height: 256,
      width: 256,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      child: CustomPaint(
        painter: DepthMapPainter(depthMap),
        size: const Size(256, 256),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Depth Estimation Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MiDaS Depth Estimation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(_status),
            const SizedBox(height: 16),
            if (_isModelLoaded) ...[
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _status = 'Processing image...';
                    _depthMap = null;
                  });
                  
                  final depthMap = await _processImage();
                  
                  setState(() {
                    if (depthMap != null) {
                      _status = 'Image processed successfully!';
                      _depthMap = depthMap;
                    } else {
                      _status = 'Failed to process image.';
                    }
                  });
                },
                child: const Text('Process Sample Image'),
              ),
              const SizedBox(height: 16),
              Text(
                'Depth Visualization:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildDepthVisualization(_depthMap),
              const SizedBox(height: 16),
            ] else ...[
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 16),
            Text(
              'How it works:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '1. The MiDaS model estimates depth for each pixel in the image.\n'
              '2. Depth values are used to calculate relative distances.\n'
              '3. A custom painter visualizes these depth values using a color gradient.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter to visualize depth maps
class DepthMapPainter extends CustomPainter {
  final Float32List depthMap;
  static const int mapSize = 256;

  const DepthMapPainter(this.depthMap);

  @override
  void paint(Canvas canvas, Size size) {
    if (depthMap.isEmpty) return;

    final paint = Paint();
    
    final cellWidth = size.width / mapSize;
    final cellHeight = size.height / mapSize;
    
    double minDepth = depthMap.reduce((a, b) => a < b ? a : b);
    double maxDepth = depthMap.reduce((a, b) => a > b ? a : b);
    
    final range = maxDepth - minDepth;
    
    for (int y = 0; y < mapSize; y++) {
      for (int x = 0; x < mapSize; x++) {
        final index = y * mapSize + x;
        if (index >= depthMap.length) continue;
        
        final depthValue = depthMap[index];
        final normalizedDepth = (range > 0) ? (depthValue - minDepth) / range : 0.0;
        
        final invertedDepth = 1.0 - normalizedDepth;
        
        final color = Color.fromRGBO(
          (invertedDepth * 255).toInt(),
          0,
          (normalizedDepth * 255).toInt(),
          1.0,
        );
        
        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(
            x * cellWidth,
            y * cellHeight,
            cellWidth,
            cellHeight,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as DepthMapPainter).depthMap != depthMap;
  }
}