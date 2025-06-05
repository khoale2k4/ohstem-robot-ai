import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class AIModelService {
  static final AIModelService _instance = AIModelService._internal();
  factory AIModelService() => _instance;
  AIModelService._internal();

  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

  // TensorFlow Lite variables
  late Interpreter _interpreter;
  late List<int> _inputShape;
  late List<int> _outputShape;
  // YOLO-specific parameters
  final int _inputSize = 640; // YOLOv10 tiny input size
  final double _confidenceThreshold = 0.5;
  final double _iouThreshold = 0.5;

  /// Khởi tạo mô hình AI
  Future<bool> initializeModel() async {
    try {
      debugPrint("Đang khởi tạo mô hình AI...");

      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
          'assets/yolov10n_float32.tflite',
          options: options);

      _inputShape = _interpreter.getInputTensor(0).shape;
      _outputShape = _interpreter.getOutputTensor(0).shape;

      _isModelLoaded = true;
      debugPrint("Mô hình AI đã sẵn sàng!");
      return true;
    } catch (e) {
      debugPrint("Lỗi khởi tạo mô hình: $e");
      return false;
    }
  }

  /// Xử lý frame camera và trả về JSON
  Future<Map<String, dynamic>?> processFrame(XFile xfile) async {
    if (!_isModelLoaded) {
      debugPrint("Mô hình chưa được khởi tạo!");
      return null;
    }

    try {
      // Run real inference
      return await _runYOLOv10Inference(xfile);
    } catch (e) {
      debugPrint("Lỗi xử lý frame: $e");
      return null;
    }
  }

  /// Simulated inference for testing - remove when implementing real model
  Future<Map<String, dynamic>> _simulateInference() async {
    await Future.delayed(Duration(milliseconds: 100));

    // Simulate random detection
    if (DateTime.now().millisecond % 3 == 0) {
      return {
        "box": [100, 150, 200, 300], // x, y, width, height
        "confident": 85,
        "controll": "follow"
      };
    } else {
      return {"box": [], "confident": 0, "controll": "search"};
    }
  }

  Future<Float32List> _convertXFileToInputTensor(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception("Không thể decode image từ XFile");
    }

    // Resize ảnh về đúng kích thước input
    final resized =
        img.copyResize(image, width: _inputSize, height: _inputSize);

    // Convert to Float32List và normalize về [0,1]
    final input = Float32List(_inputSize * _inputSize * 3);
    int index = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[index++] = img.getRed(pixel) / 255.0;
        input[index++] = img.getGreen(pixel) / 255.0;
        input[index++] = img.getBlue(pixel) / 255.0;
      }
    }

    return input;
  }

  Future<img.Image> XFile2Image(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception("Không thể decode image từ XFile");
    }

    return image;
  }

  List<List<List<double>>> _reshapeOutput(Float32List output, List<int> shape) {
    if (shape.length != 3) throw ArgumentError("Chỉ hỗ trợ output 3 chiều");

    final batchSize = shape[0];
    final features = shape[1];
    final anchors = shape[2];

    final reshaped = List.generate(
        batchSize,
        (i) => List.generate(
            features,
            (j) => List.generate(anchors,
                (k) => output[i * features * anchors + j * anchors + k])));

    return reshaped;
  }

  Future<Map<String, dynamic>> _runYOLOv10Inference(XFile xfile) async {
    try {
      final inputTensor = await _convertXFileToInputTensor(xfile);

      // Chuẩn bị output buffer - cách đúng để tạo output tensor
      final output = Float32List(_outputShape.reduce((a, b) => a * b));

      // Chạy inference
      _interpreter.run(inputTensor.buffer, output.buffer);

      // Reshape output nếu cần (ví dụ cho YOLOv10 output shape [1, 84, 8400])
      final reshapedOutput = _reshapeOutput(output, _outputShape);

      final detections = _processYOLOv10Output(reshapedOutput);
      final finalDetections = _nonMaxSuppression(detections);

      if (finalDetections.isNotEmpty) {
        final bestDetection = finalDetections.first;
        return {
          "box": [
            bestDetection['x'].toInt(),
            bestDetection['y'].toInt(),
            bestDetection['width'].toInt(),
            bestDetection['height'].toInt()
          ],
          "confident": (bestDetection['confidence'] / 100).toInt(),
          "controll": bestDetection['confidence'] > _confidenceThreshold
              ? "follow"
              : "search"
        };
      } else {
        return {"box": [], "confident": 0, "controll": "search"};
      }
    } catch (e) {
      debugPrint("Lỗi trong quá trình inference: $e");
      return {"box": [], "confident": 0, "controll": "search"};
    }
  }

  List<Map<String, dynamic>> _processYOLOv10Output(List output) {
    final detections = <Map<String, dynamic>>[];

    // Giả sử output có shape [1, 84, 8400] (điển hình cho YOLOv8/v10)
    // Bạn cần điều chỉnh theo đúng output shape của model
    final numClasses = 80; // Số class COCO
    final numAnchors = output[0][0].length;

    for (int i = 0; i < numAnchors; i++) {
      final confidence = output[0][4][i];
      if (confidence > _confidenceThreshold) {
        // Lấy class có xác suất cao nhất
        double maxProb = 0;
        int classId = 0;
        for (int j = 0; j < numClasses; j++) {
          final prob = output[0][5 + j][i] * confidence;
          if (prob > maxProb) {
            maxProb = prob;
            classId = j;
          }
        }

        if (maxProb > _confidenceThreshold) {
          detections.add({
            'x': output[0][0][i] * _inputSize,
            'y': output[0][1][i] * _inputSize,
            'width': output[0][2][i] * _inputSize,
            'height': output[0][3][i] * _inputSize,
            'confidence': maxProb,
            'class': classId,
          });
        }
      }
    }

    return detections;
  }

  List<Map<String, dynamic>> _nonMaxSuppression(
      List<Map<String, dynamic>> detections) {
    if (detections.isEmpty) return [];

    // Sort by confidence (highest first)
    detections.sort((a, b) => b['confidence'].compareTo(a['confidence']));

    final selected = <Map<String, dynamic>>[];
    final suppressed = <bool>[
      for (int i = 0; i < detections.length; i++) false
    ];

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;

      selected.add(detections[i]);

      // Suppress overlapping boxes
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        final iou = _calculateIoU(detections[i], detections[j]);
        if (iou > _iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return selected;
  }

  double _calculateIoU(Map<String, dynamic> box1, Map<String, dynamic> box2) {
    final x1 = box1['x'];
    final y1 = box1['y'];
    final w1 = box1['width'];
    final h1 = box1['height'];

    final x2 = box2['x'];
    final y2 = box2['y'];
    final w2 = box2['width'];
    final h2 = box2['height'];

    // Calculate intersection
    final xLeft = (x1 > x2) ? x1 : x2;
    final yTop = (y1 > y2) ? y1 : y2;
    final xRight = (x1 + w1 < x2 + w2) ? x1 + w1 : x2 + w2;
    final yBottom = (y1 + h1 < y2 + h2) ? y1 + h1 : y2 + h2;

    if (xRight <= xLeft || yBottom <= yTop) return 0.0;

    final intersection = (xRight - xLeft) * (yBottom - yTop);
    final union = w1 * h1 + w2 * h2 - intersection;

    return intersection / union;
  }

  void dispose() {
    if (_isModelLoaded) {
      _interpreter.close();
    }
    debugPrint("AI Model Service disposed");
  }
}

enum CameraStatus {
  starting, // đang khởi động
  active, // đang hoạt động
  error, // lỗi
}

/// Extension để get màu sắc cho status
extension CameraStatusExtension on CameraStatus {
  Color get color {
    switch (this) {
      case CameraStatus.starting:
        return Colors.orange;
      case CameraStatus.active:
        return Colors.green;
      case CameraStatus.error:
        return Colors.red;
    }
  }

  String get message {
    switch (this) {
      case CameraStatus.starting:
        return 'Đang khởi động';
      case CameraStatus.active:
        return 'Hoạt động';
      case CameraStatus.error:
        return 'Lỗi';
    }
  }

  IconData get icon {
    switch (this) {
      case CameraStatus.starting:
        return Icons.hourglass_empty;
      case CameraStatus.active:
        return Icons.videocam;
      case CameraStatus.error:
        return Icons.error;
    }
  }
}
