# Hướng Dẫn Tích Hợp Mô Hình AI 🤖

## 📋 Tổng Quan
File này hướng dẫn cách tích hợp mô hình AI thực tế của bạn vào ứng dụng Robot AI để phát hiện con người.

## 🔧 Cấu Trúc Hiện Tại

### AIModelService
File: `lib/services/ai_model_service.dart`

Đây là service chính để xử lý mô hình AI với các phương thức:

```dart
class AIModelService {
  // Singleton pattern
  static final AIModelService _instance = AIModelService._internal();
  factory AIModelService() => _instance;
  
  // Khởi tạo mô hình
  Future<bool> initializeModel();
  
  // Xử lý hình ảnh
  Future<String?> processImage(CameraImage cameraImage);
  
  // Giải phóng tài nguyên
  void dispose();
}
```

## 🚀 Cách Tích Hợp Mô Hình Thực Tế

### Bước 1: Thêm Dependencies
Trong `pubspec.yaml`, thêm dependencies cho mô hình AI:

```yaml
dependencies:
  # Cho TensorFlow Lite
  tflite_flutter: ^0.10.4
  tflite_flutter_helper: ^0.3.1
  
  # Cho ML Kit (Google)
  google_ml_kit: ^0.16.3
  
  # Cho custom model loading
  flutter/services: # để load assets
```

### Bước 2: Thêm Model vào Assets
Trong `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/your_model.tflite
    - assets/models/labels.txt
```

### Bước 3: Cập Nhật initializeModel()

Thay thế phần simulation trong `initializeModel()`:

```dart
Future<bool> initializeModel() async {
  try {
    debugPrint("Đang khởi tạo mô hình AI...");
    
    // Ví dụ với TensorFlow Lite
    _interpreter = await Interpreter.fromAsset('assets/models/your_model.tflite');
    
    // Cấu hình input/output tensors
    _inputShape = _interpreter.getInputTensor(0).shape;
    _outputShape = _interpreter.getOutputTensor(0).shape;
    
    // Load labels nếu cần
    _labels = await _loadLabels('assets/models/labels.txt');
    
    _isModelLoaded = true;
    debugPrint("Mô hình AI đã sẵn sàng!");
    return true;
  } catch (e) {
    debugPrint("Lỗi khởi tạo mô hình: $e");
    return false;
  }
}
```

### Bước 4: Cập Nhật _runInference()

Thay thế phần simulation trong `_runInference()`:

```dart
Future<String> _runInference(Uint8List imageData) async {
  try {
    // Preprocess image
    final input = _preprocessImage(imageData);
    
    // Run inference
    final output = List.filled(_outputShape.reduce((a, b) => a * b), 0.0);
    _interpreter.run(input, output);
    
    // Postprocess results
    final result = _postprocessOutput(output);
    
    debugPrint("Kết quả từ mô hình: $result");
    return result;
    
  } catch (e) {
    debugPrint("Lỗi trong quá trình inference: $e");
    return "error";
  }
}
```

## 🛠️ Ví Dụ Tích Hợp Cụ Thể

### Với TensorFlow Lite

```dart
import 'package:tflite_flutter/tflite_flutter.dart';

class AIModelService {
  Interpreter? _interpreter;
  List<String>? _labels;
  
  Future<bool> initializeModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/human_detection.tflite');
      _labels = await _loadLabels('assets/models/labels.txt');
      _isModelLoaded = true;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<String> _runInference(Uint8List imageData) async {
    if (_interpreter == null) return "error";
    
    // Resize image to model input size (e.g., 224x224)
    final input = _resizeImage(imageData, 224, 224);
    
    // Normalize pixel values
    final normalizedInput = _normalizeImage(input);
    
    // Run inference
    final output = List.filled(2, 0.0); // [no_human, human]
    _interpreter!.run([normalizedInput], [output]);
    
    // Interpret results
    final confidence = output[1]; // human confidence
    if (confidence > 0.7) {
      return "human_detected";
    } else if (confidence > 0.3) {
      return "human_far";
    } else {
      return "no_human";
    }
  }
}
```

### Với Google ML Kit

```dart
import 'package:google_ml_kit/google_ml_kit.dart';

class AIModelService {
  PersonDetector? _personDetector;
  
  Future<bool> initializeModel() async {
    try {
      _personDetector = GoogleMlKit.vision.personDetector(
        PersonDetectorOptions(
          mode: PersonDetectorMode.stream,
          enablePoseLandmarks: false,
        ),
      );
      _isModelLoaded = true;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<String?> processImage(CameraImage cameraImage) async {
    if (_personDetector == null) return null;
    
    try {
      final inputImage = _convertToInputImage(cameraImage);
      final persons = await _personDetector!.processImage(inputImage);
      
      if (persons.isEmpty) {
        return "no_human";
      } else if (persons.length == 1) {
        final person = persons.first;
        final size = person.boundingBox.size;
        if (size.width * size.height > 50000) {
          return "human_close";
        } else {
          return "human_far";
        }
      } else {
        return "multiple_humans";
      }
    } catch (e) {
      return "error";
    }
  }
}
```

## 📝 Các Bước Tiếp Theo

### 1. Xóa Simulation Code
Trong `follow_human_screen.dart`, thay thế:
```dart
final result = await _simulateAIProcessing();
```

Bằng:
```dart
final result = await _aiService.processImage(cameraImage);
```

### 2. Cấu Hình Camera Stream
Để có hiệu suất tốt hơn, sử dụng camera stream thay vì takePicture():

```dart
_cameraController!.startImageStream((CameraImage image) async {
  if (!_isProcessing) {
    _isProcessing = true;
    final result = await _aiService.processImage(image);
    if (result != null && mounted) {
      _handleDetectionResult(result);
    }
    _isProcessing = false;
  }
});
```

### 3. Tối Ưu Hiệu Suất
- Giảm resolution camera nếu cần
- Tăng interval giữa các lần xử lý
- Sử dụng isolate cho heavy processing

## 🔄 Test và Debug

### 1. Logging
Thêm các log chi tiết:
```dart
debugPrint("Model input shape: $_inputShape");
debugPrint("Processing time: ${stopwatch.elapsedMilliseconds}ms");
debugPrint("Confidence scores: $confidenceScores");
```

### 2. Error Handling
```dart
try {
  final result = await _aiService.processImage(image);
} catch (e) {
  debugPrint("AI processing error: $e");
  // Fallback to previous detection or default state
}
```

## 📊 Kết Quả Mong Đợi

Sau khi tích hợp thành công, bạn sẽ có:

✅ Real-time human detection từ camera  
✅ Phân loại: no_human, human_detected, human_far, human_close, multiple_humans  
✅ UI feedback tương ứng với kết quả detection  
✅ Smooth animations và status updates  
✅ Optimal performance cho mobile device  

## 🎯 Tips và Best Practices

1. **Model Size**: Giữ model < 10MB cho mobile
2. **Inference Time**: Mục tiêu < 100ms per frame
3. **Memory Usage**: Monitor memory usage với profiler
4. **Battery**: Optimize để tiết kiệm pin
5. **Error Handling**: Luôn có fallback strategy

Chúc bạn tích hợp thành công! 🚀 