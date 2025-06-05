# Hướng Dẫn Sử Dụng Auto Navigation 🤖🗺️

## 📋 Tổng Quan

Hệ thống Auto Navigation cho phép robot tự động khám phá môi trường, vẽ bản đồ và điều hướng đến các vị trí được chọn.

## 🎯 Tính Năng Chính

### 🗺️ Khám Phá Tự Động
- Robot tự động di chuyển trong phòng để khám phá
- Vẽ bản đồ real-time các nơi đã đi qua
- Phát hiện và đánh dấu chướng ngại vật
- Tự động dừng khi khám phá đủ (100+ điểm)

### 🎯 Navigation Thông Minh
- Chọn điểm trên bản đồ để robot di chuyển đến
- Path planning tự động
- Tránh chướng ngại vật
- Hiển thị real-time vị trí robot và target

### 💾 Quản Lý Bản Đồ
- Lưu bản đồ vào localStorage với tên tùy chỉnh
- Load lại bản đồ đã lưu
- Xóa bản đồ không cần thiết
- Export/Import bản đồ (JSON format)

## 🎨 Giao Diện

### Status Indicator (góc trên phải)
- **🟠 Đang khám phá** - Robot đang di chuyển tự động
- **🟢 Sẵn sàng** - Có thể chọn điểm để navigation
- **🔵 Đang di chuyển** - Robot đang đến target
- **⚫ Dừng** - Robot không hoạt động

### Map Display
- **🟦 Đường đi** - Path robot đã khám phá
- **🟢 Robot** - Vị trí hiện tại của robot
- **🟠 Target** - Điểm đích được chọn
- **🔴 Chướng ngại** - Các vật cản được phát hiện
- **Grid** - Hệ tọa độ tham chiếu

### Info Panel
- **Đã khám phá**: Số điểm đã đi qua
- **Chướng ngại**: Số vật cản đã phát hiện
- **Trạng thái**: Tình trạng hiện tại của robot

### Controls
#### Khám phá
- **"Bắt đầu khám phá"** - Khởi động quá trình mapping
- **"Dừng khám phá"** - Kết thúc mapping

#### Navigation
- **Tap trên map** - Chọn điểm đích (chỉ khi robot sẵn sàng)
- **"Dừng navigation"** - Hủy di chuyển

#### Quản lý bản đồ
- **"Lưu bản đồ"** - Lưu map hiện tại
- **"Tải bản đồ"** - Load map đã lưu
- **"Reset"** - Xóa toàn bộ map

## 🔄 Workflow

### 1. Khám Phá Bản Đồ
```
1. Nhấn "Bắt đầu khám phá"
2. Robot tự động di chuyển trong phòng
3. Quan sát path được vẽ real-time
4. Chờ robot hoàn thành (hoặc nhấn "Dừng")
5. Status chuyển sang "Sẵn sàng"
```

### 2. Navigation Đến Điểm
```
1. Đảm bảo robot ở trạng thái "Sẵn sàng"
2. Tap vào điểm bất kỳ trên bản đồ
3. Robot tự động di chuyển đến điểm đó
4. Quan sát target point và robot movement
5. Robot tự động dừng khi đến đích
```

### 3. Lưu Bản Đồ
```
1. Hoàn thành khám phá
2. Nhấn "Lưu bản đồ"
3. Nhập tên cho bản đồ
4. Nhấn "Lưu"
5. Bản đồ được lưu trong localStorage
```

### 4. Load Bản Đồ
```
1. Nhấn "Tải bản đồ"
2. Chọn từ danh sách bản đồ đã lưu
3. Bản đồ được load ngay lập tức
4. Robot ở trạng thái "Sẵn sàng" để navigation
```

## 🛠️ Tích Hợp Robot Thực Tế

### Navigation Service Integration
Thay thế simulation trong `NavigationService`:

```dart
// Trong _simulateExploration()
void _simulateExploration() {
  // TODO: Thay thế bằng data thực từ robot sensors
  
  // Lấy vị trí từ IMU/Encoders
  final robotPosition = getRobotPosition();
  
  // Lấy sensor data cho obstacle detection
  final obstacles = getLidarObstacles();
  
  // Cập nhật map
  _currentPosition = robotPosition;
  _exploredPoints.add(robotPosition);
  _obstacles.addAll(obstacles);
  
  // Broadcast updates
  _positionController.add(_currentPosition);
  _mapController.add(_exploredPoints);
}

// Trong _simulateNavigation()
void _simulateNavigation() {
  // TODO: Thay thế bằng path planning thực tế
  
  // Tính toán path đến target
  final path = calculatePath(_currentPosition, _targetPosition);
  
  // Gửi lệnh đến robot
  sendMovementCommand(path.nextMove);
  
  // Cập nhật vị trí từ feedback
  _currentPosition = getRobotPosition();
  _positionController.add(_currentPosition);
}
```

### Robot Commands Integration
```dart
void _sendRobotCommand(String command, dynamic data) {
  switch (command) {
    case 'start_exploration':
      // Bật chế độ khám phá tự động
      robotService.startAutoExploration();
      break;
      
    case 'navigate_to':
      // Điều hướng đến tọa độ
      final target = data as MapPoint;
      robotService.navigateToPosition(target.x, target.y);
      break;
      
    case 'stop':
      // Dừng robot
      robotService.stopMovement();
      break;
  }
}
```

## 📊 Data Structure

### MapPoint
```json
{
  "x": 150.5,           // Tọa độ X (double)
  "y": 200.3,           // Tọa độ Y (double)
  "timestamp": 1640995200000  // Thời gian (milliseconds)
}
```

### Obstacle
```json
{
  "x": 180.0,           // Tọa độ trung tâm X
  "y": 220.0,           // Tọa độ trung tâm Y
  "radius": 15.5        // Bán kính vật cản
}
```

### MapData (Saved Maps)
```json
{
  "name": "Phòng khách",
  "exploredPoints": [/* array of MapPoint */],
  "obstacles": [/* array of Obstacle */],
  "createdAt": "2024-01-01T10:30:00.000Z"
}
```

## 🎯 Performance Tips

### 1. Exploration Optimization
- Điều chỉnh `Timer.periodic` frequency (default: 500ms)
- Giới hạn số điểm lưu trữ để tránh lag
- Optimize rendering với `shouldRepaint` logic

### 2. Storage Optimization
- Compress map data trước khi lưu
- Implement lazy loading cho large maps
- Set limit cho số bản đồ có thể lưu

### 3. UI Performance
- Use `StreamBuilder` thay vì `setState` nhiều lần
- Implement map viewport để chỉ render visible area
- Cache painted elements

## ⚡ Customization Options

### Map Scale & Zoom
```dart
// Trong MapPainter
final scale = 2.0; // Tăng để zoom in
final centerX = size.width / 2;
final centerY = size.height / 2;
```

### Colors & Styling
```dart
// Exploration path
final pathPaint = Paint()
  ..color = Colors.blue.withOpacity(0.6)
  ..strokeWidth = 2;

// Robot color
final robotPaint = Paint()
  ..color = Colors.green;

// Obstacle color
final obstaclePaint = Paint()
  ..color = Colors.red.withOpacity(0.7);
```

### Exploration Parameters
```dart
// Exploration area limits
final newX = (currentX + deltaX).clamp(-300.0, 300.0);
final newY = (currentY + deltaY).clamp(-300.0, 300.0);

// Auto stop condition
if (_exploredPoints.length > 150) {
  stopExploration();
}
```

## 🚀 Kết Quả

✅ **Auto Exploration** - Robot tự động khám phá môi trường  
✅ **Real-time Mapping** - Vẽ bản đồ trong thời gian thực  
✅ **Smart Navigation** - Điều hướng thông minh đến điểm chọn  
✅ **Map Persistence** - Lưu/load bản đồ từ localStorage  
✅ **Obstacle Detection** - Phát hiện và tránh chướng ngại vật  
✅ **Professional UI** - Giao diện đẹp, dễ sử dụng  
✅ **Scalable Architecture** - Dễ tích hợp với robot thực tế  

Hệ thống Auto Navigation giờ đây hoàn chỉnh và sẵn sàng cho việc tích hợp robot thực tế! 🎉 