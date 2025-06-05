import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Navigation state
  NavigationStatus _status = NavigationStatus.stopped;
  NavigationStatus get status => _status;

  // Map data
  final List<MapPoint> _exploredPoints = [];
  final List<Obstacle> _obstacles = [];
  MapPoint? _currentPosition;
  MapPoint? _targetPosition;

  // Streams
  final StreamController<NavigationStatus> _statusController = StreamController<NavigationStatus>.broadcast();
  final StreamController<List<MapPoint>> _mapController = StreamController<List<MapPoint>>.broadcast();
  final StreamController<MapPoint?> _positionController = StreamController<MapPoint?>.broadcast();

  Stream<NavigationStatus> get statusStream => _statusController.stream;
  Stream<List<MapPoint>> get mapStream => _mapController.stream;
  Stream<MapPoint?> get positionStream => _positionController.stream;

  // Getters
  List<MapPoint> get exploredPoints => List.unmodifiable(_exploredPoints);
  List<Obstacle> get obstacles => List.unmodifiable(_obstacles);
  MapPoint? get currentPosition => _currentPosition;
  MapPoint? get targetPosition => _targetPosition;

  Timer? _explorationTimer;
  Timer? _navigationTimer;

  /// Bắt đầu khám phá tự động
  Future<void> startExploration() async {
    if (_status == NavigationStatus.exploring) return;

    _updateStatus(NavigationStatus.exploring);
    _currentPosition = const MapPoint(x: 0, y: 0, timestamp: 0);
    _positionController.add(_currentPosition);

    // Simulation exploration - thay thế bằng logic thực tế
    _explorationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _simulateExploration();
    });

    debugPrint("Bắt đầu khám phá bản đồ");
  }

  /// Dừng khám phá
  void stopExploration() {
    _explorationTimer?.cancel();
    _updateStatus(NavigationStatus.ready);
    debugPrint("Dừng khám phá");
  }

  /// Navigation đến điểm được chọn
  Future<void> navigateToPoint(MapPoint target) async {
    if (_status == NavigationStatus.exploring) {
      stopExploration();
    }

    _targetPosition = target;
    _updateStatus(NavigationStatus.navigating);

    // Simulation navigation - thay thế bằng logic thực tế
    _navigationTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      _simulateNavigation();
    });

    debugPrint("Bắt đầu di chuyển đến: (${target.x}, ${target.y})");
  }

  /// Dừng navigation
  void stopNavigation() {
    _navigationTimer?.cancel();
    _targetPosition = null;
    _updateStatus(NavigationStatus.ready);
    debugPrint("Dừng navigation");
  }

  /// Reset bản đồ
  void resetMap() {
    _exploredPoints.clear();
    _obstacles.clear();
    _currentPosition = null;
    _targetPosition = null;
    _updateStatus(NavigationStatus.stopped);
    _mapController.add(_exploredPoints);
    _positionController.add(_currentPosition);
    debugPrint("Reset bản đồ");
  }

  /// Load bản đồ từ data
  void loadMap(MapData mapData) {
    _exploredPoints.clear();
    _obstacles.clear();
    
    _exploredPoints.addAll(mapData.exploredPoints);
    _obstacles.addAll(mapData.obstacles);
    
    _mapController.add(_exploredPoints);
    _updateStatus(NavigationStatus.ready);
    debugPrint("Loaded map: ${mapData.name}");
  }

  /// Lấy dữ liệu bản đồ hiện tại
  MapData getCurrentMapData(String name) {
    return MapData(
      name: name,
      exploredPoints: List.from(_exploredPoints),
      obstacles: List.from(_obstacles),
      createdAt: DateTime.now(),
    );
  }

  /// Simulation exploration - thay thế bằng data thực từ robot
  void _simulateExploration() {
    if (_currentPosition == null) return;

    // Random movement
    final random = Random();
    final deltaX = (random.nextDouble() - 0.5) * 20;
    final deltaY = (random.nextDouble() - 0.5) * 20;

    final newX = (_currentPosition!.x + deltaX).clamp(-200.0, 200.0);
    final newY = (_currentPosition!.y + deltaY).clamp(-200.0, 200.0);

    _currentPosition = MapPoint(
      x: newX,
      y: newY,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    // Thêm điểm đã khám phá
    _exploredPoints.add(_currentPosition!);

    // Random obstacles
    if (random.nextDouble() < 0.1) {
      _obstacles.add(Obstacle(
        x: newX + random.nextDouble() * 10,
        y: newY + random.nextDouble() * 10,
        radius: 5 + random.nextDouble() * 10,
      ));
    }

    _positionController.add(_currentPosition);
    _mapController.add(_exploredPoints);

    // Auto stop after exploring enough
    if (_exploredPoints.length > 100) {
      stopExploration();
    }
  }

  /// Simulation navigation - thay thế bằng path planning thực tế
  void _simulateNavigation() {
    if (_currentPosition == null || _targetPosition == null) return;

    final dx = _targetPosition!.x - _currentPosition!.x;
    final dy = _targetPosition!.y - _currentPosition!.y;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance < 5) {
      // Reached target
      stopNavigation();
      return;
    }

    // Move towards target
    final speed = 3.0;
    final moveX = (dx / distance) * speed;
    final moveY = (dy / distance) * speed;

    _currentPosition = MapPoint(
      x: _currentPosition!.x + moveX,
      y: _currentPosition!.y + moveY,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _positionController.add(_currentPosition);
  }

  void _updateStatus(NavigationStatus newStatus) {
    _status = newStatus;
    _statusController.add(_status);
  }

  void dispose() {
    _explorationTimer?.cancel();
    _navigationTimer?.cancel();
    _statusController.close();
    _mapController.close();
    _positionController.close();
  }
}

/// Enum cho trạng thái navigation
enum NavigationStatus {
  stopped,      // Dừng
  exploring,    // Đang khám phá
  ready,        // Sẵn sàng navigation
  navigating,   // Đang di chuyển đến target
}

/// Extension cho NavigationStatus
extension NavigationStatusExtension on NavigationStatus {
  String get message {
    switch (this) {
      case NavigationStatus.stopped:
        return 'Dừng';
      case NavigationStatus.exploring:
        return 'Đang khám phá';
      case NavigationStatus.ready:
        return 'Sẵn sàng';
      case NavigationStatus.navigating:
        return 'Đang di chuyển';
    }
  }

  Color get color {
    switch (this) {
      case NavigationStatus.stopped:
        return Colors.grey;
      case NavigationStatus.exploring:
        return Colors.blue;
      case NavigationStatus.ready:
        return Colors.green;
      case NavigationStatus.navigating:
        return Colors.orange;
    }
  }

  IconData get icon {
    switch (this) {
      case NavigationStatus.stopped:
        return Icons.stop;
      case NavigationStatus.exploring:
        return Icons.explore;
      case NavigationStatus.ready:
        return Icons.check_circle;
      case NavigationStatus.navigating:
        return Icons.navigation;
    }
  }
}

/// Data classes
class MapPoint {
  final double x;
  final double y;
  final int timestamp;

  const MapPoint({
    required this.x,
    required this.y,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'timestamp': timestamp,
  };

  factory MapPoint.fromJson(Map<String, dynamic> json) => MapPoint(
    x: json['x']?.toDouble() ?? 0.0,
    y: json['y']?.toDouble() ?? 0.0,
    timestamp: json['timestamp'] ?? 0,
  );
}

class Obstacle {
  final double x;
  final double y;
  final double radius;

  const Obstacle({
    required this.x,
    required this.y,
    required this.radius,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'radius': radius,
  };

  factory Obstacle.fromJson(Map<String, dynamic> json) => Obstacle(
    x: json['x']?.toDouble() ?? 0.0,
    y: json['y']?.toDouble() ?? 0.0,
    radius: json['radius']?.toDouble() ?? 5.0,
  );
}

class MapData {
  final String name;
  final List<MapPoint> exploredPoints;
  final List<Obstacle> obstacles;
  final DateTime createdAt;

  const MapData({
    required this.name,
    required this.exploredPoints,
    required this.obstacles,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'exploredPoints': exploredPoints.map((p) => p.toJson()).toList(),
    'obstacles': obstacles.map((o) => o.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory MapData.fromJson(Map<String, dynamic> json) => MapData(
    name: json['name'] ?? '',
    exploredPoints: (json['exploredPoints'] as List?)
        ?.map((p) => MapPoint.fromJson(p))
        .toList() ?? [],
    obstacles: (json['obstacles'] as List?)
        ?.map((o) => Obstacle.fromJson(o))
        .toList() ?? [],
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );
} 