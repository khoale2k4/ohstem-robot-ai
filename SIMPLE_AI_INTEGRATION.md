# Hướng Dẫn Tích Hợp AI Đơn Giản 🤖

## 📋 Tổng Quan Hệ Thống

Hệ thống đã được đơn giản hóa với:

### 🎯 3 Trạng Thái Camera
1. **Đang khởi động** (starting) - 🟠 Màu cam  
2. **Đang hoạt động** (active) - 🟢 Màu xanh lá  
3. **Lỗi** (error) - 🔴 Màu đỏ  

### 📄 JSON Response Format
AI model sẽ trả về JSON với format:
```json
{
  "box": [x, y, width, height],  // Tọa độ bounding box (array of int)
  "confident": 85,               // Xác suất là con người (int 0-100)
  "controll": "follow"           // Lệnh điều khiển robot (string)
}
```

## 🔧 Cách Tích Hợp

### Bước 1: Cập Nhật AI Service

Trong file `lib/services/ai_model_service.dart`, thay thế hàm `_runModelInference()`:

```dart
Future<Map<String, dynamic>> _runModelInference(CameraImage cameraImage) async {
  try {
    // TODO: Gọi mô hình AI thực tế của bạn ở đây
    
    // Ví dụ:
    // 1. Preprocess camera image
    final imageData = preprocessImage(cameraImage);
    
    // 2. Run inference
    final result = await yourModelInference(imageData);
    
    // 3. Parse kết quả và tạo JSON response
    return {
      "box": result.boundingBox,        // [x, y, width, height]
      "confident": result.confidence,   // 0-100
      "controll": result.command        // "follow", "search", "stop"
    };
    
  } catch (e) {
    debugPrint("Lỗi inference: $e");
    return {
      "box": [],
      "confident": 0,
      "controll": "stop"
    };
  }
}
```

### Bước 2: Sử dụng Real Camera Stream

Trong file `follow_human_screen.dart`, thay thế simulation bằng real camera stream:

```dart
void _startHumanDetection() {
  if (!_aiService.isModelLoaded || _cameraController == null) {
    return;
  }
  
  // Sử dụng camera stream thay vì timer
  _cameraController!.startImageStream((CameraImage image) async {
    if (!_isProcessing && _isFollowing) {
      _isProcessing = true;
      
      try {
        // Gọi AI service thực tế
        final result = await _aiService.processFrame(image);
        
        if (result != null && mounted) {
          _handleAIResult(result);
        }
      } catch (e) {
        debugPrint("Lỗi xử lý frame: $e");
      } finally {
        _isProcessing = false;
      }
    }
  });
}

void _stopHumanDetection() {
  _cameraController?.stopImageStream();
  setState(() {
    _humanBoundingBox = null;
    _currentCommand = "stop";
    _confidence = 0;
  });
  _pulseController.stop();
}
```

## 📊 Các Lệnh Điều Khiển Robot

### "follow"
- Robot theo dõi người được phát hiện
- Hiển thị bounding box với confidence
- UI: Xanh lá, pulse animation

### "search"  
- Robot tìm kiếm người
- Không có bounding box
- UI: Info overlay hiển thị "searching"

### "stop"
- Robot dừng hoạt động
- Xóa tất cả UI elements
- Trạng thái idle

## 🎨 UI Components

### Status Indicator (góc trên phải)
```dart
StatusIndicator(
  message: _cameraStatus.message,    // "Đang khởi động", "Hoạt động", "Lỗi"
  color: _cameraStatus.color,        // Colors.orange, Colors.green, Colors.red
  icon: _cameraStatus.icon,          // Icons.hourglass_empty, Icons.videocam, Icons.error
  isAnimated: _cameraStatus == CameraStatus.starting,
)
```

### Bounding Box
- Chỉ hiển thị khi có detection (box không rỗng)
- Pulse animation khi active
- Label hiển thị "Human X%" với confidence

### Info Overlay
- Hiển thị command hiện tại
- Hiển thị confidence khi có detection
- Ở góc trên trái, chỉ khi đang follow

## 🚀 Ví Dụ Implementation

### Với TensorFlow Lite
```dart
Future<Map<String, dynamic>> _runModelInference(CameraImage cameraImage) async {
  // Convert CameraImage to input tensor
  final input = await convertCameraImageToTensor(cameraImage);
  
  // Run inference
  final output = await _interpreter.run(input);
  
  // Parse output
  final detections = parseDetections(output);
  
  if (detections.isNotEmpty) {
    final bestDetection = detections.first;
    return {
      "box": [
        bestDetection.x,
        bestDetection.y, 
        bestDetection.width,
        bestDetection.height
      ],
      "confident": (bestDetection.confidence * 100).toInt(),
      "controll": bestDetection.confidence > 0.7 ? "follow" : "search"
    };
  }
  
  return {
    "box": [],
    "confident": 0,
    "controll": "search"
  };
}
```

### Với Custom HTTP API
```dart
Future<Map<String, dynamic>> _runModelInference(CameraImage cameraImage) async {
  // Convert image to base64
  final base64Image = await convertImageToBase64(cameraImage);
  
  // Send to API
  final response = await http.post(
    Uri.parse('https://your-api.com/detect'),
    body: json.encode({'image': base64Image}),
    headers: {'Content-Type': 'application/json'},
  );
  
  // Parse response
  final result = json.decode(response.body);
  
  return {
    "box": result['bounding_box'] ?? [],
    "confident": result['confidence'] ?? 0,
    "controll": result['action'] ?? 'stop'
  };
}
```

## 🔄 Test Flow

1. **Khởi động app** → Status: "Đang khởi động" (cam)
2. **AI model load xong** → Status: "Hoạt động" (xanh)  
3. **Nhấn "Follow"** → Bắt đầu xử lý frames
4. **Phát hiện người** → Hiển thị bounding box + "follow" command
5. **Mất tích người** → Xóa bounding box + "search" command
6. **Nhấn "Stop"** → Dừng tất cả + "stop" command

## ⚡ Performance Tips

1. **Frame Rate**: Xử lý mỗi 500ms thay vì real-time
2. **Resolution**: Sử dụng medium resolution cho camera
3. **Model Size**: Giữ model < 10MB 
4. **Inference Time**: Mục tiêu < 100ms per frame
5. **Error Handling**: Luôn có fallback response

## 🎯 Kết Quả

✅ Giao diện đơn giản, dễ hiểu  
✅ 3 trạng thái camera rõ ràng  
✅ JSON format chuẩn cho AI  
✅ Real-time bounding box display  
✅ Robot command integration ready  
✅ Error handling robust  

Hệ thống giờ đây đơn giản và dễ tích hợp! 🚀 