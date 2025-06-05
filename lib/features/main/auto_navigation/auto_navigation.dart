import 'package:flutter/material.dart';
import 'package:robot_ai/services/navigation_service.dart';
import 'package:robot_ai/services/map_storage_service.dart';
import 'package:robot_ai/core/widgets/map_widget.dart';
import 'package:robot_ai/core/widgets/status_indicator.dart';
import 'dart:async';

class AutoNavigationPage extends StatefulWidget {
  const AutoNavigationPage({Key? key}) : super(key: key);

  @override
  State<AutoNavigationPage> createState() => _AutoNavigationPageState();
}

class _AutoNavigationPageState extends State<AutoNavigationPage> {
  final NavigationService _navigationService = NavigationService();
  final MapStorageService _storageService = MapStorageService();

  NavigationStatus _currentStatus = NavigationStatus.stopped;
  List<MapPoint> _exploredPoints = [];
  List<Obstacle> _obstacles = [];
  MapPoint? _currentPosition;
  MapPoint? _targetPosition;

  late StreamSubscription _statusSubscription;
  late StreamSubscription _mapSubscription;
  late StreamSubscription _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  @override
  void dispose() {
    _statusSubscription.cancel();
    _mapSubscription.cancel();
    _positionSubscription.cancel();
    _navigationService.dispose();
    super.dispose();
  }

  void _initializeStreams() {
    _statusSubscription = _navigationService.statusStream.listen((status) {
      setState(() {
        _currentStatus = status;
      });
    });

    _mapSubscription = _navigationService.mapStream.listen((points) {
      setState(() {
        _exploredPoints = points;
        _obstacles = _navigationService.obstacles;
      });
    });

    _positionSubscription = _navigationService.positionStream.listen((position) {
      setState(() {
        _currentPosition = position;
        _targetPosition = _navigationService.targetPosition;
      });
    });
  }

  void _startExploration() {
    _navigationService.startExploration();
  }

  void _stopExploration() {
    _navigationService.stopExploration();
  }

  void _stopNavigation() {
    _navigationService.stopNavigation();
  }

  void _resetMap() {
    _navigationService.resetMap();
  }

  void _onMapTap(MapPoint point) {
    if (_currentStatus == NavigationStatus.ready) {
      _navigationService.navigateToPoint(point);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Robot phải hoàn thành khám phá trước khi navigation'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _showSaveMapDialog() async {
    if (_exploredPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có dữ liệu bản đồ để lưu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final textController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2d3a),
        title: const Text(
          'Lưu Bản Đồ',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhập tên cho bản đồ:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Tên bản đồ...',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null) {
      final mapData = _navigationService.getCurrentMapData(result);
      final success = await _storageService.saveMap(mapData);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu bản đồ "$result"'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi lưu bản đồ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showLoadMapDialog() async {
    final savedMaps = await _storageService.getSavedMaps();
    
    if (savedMaps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có bản đồ nào được lưu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedMap = await showDialog<MapData>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2d3a),
        title: const Text(
          'Chọn Bản Đồ',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: savedMaps.length,
            itemBuilder: (context, index) {
              final map = savedMaps[index];
              return ListTile(
                title: Text(
                  map.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Tạo: ${_formatDate(map.createdAt)}\n'
                  '${map.exploredPoints.length} điểm khám phá',
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () => Navigator.pop(context, map),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await _showDeleteConfirmDialog(map.name);
                    if (confirm == true) {
                      await _storageService.deleteMap(map.name);
                      setState(() {}); // Refresh dialog
                      Navigator.pop(context);
                      _showLoadMapDialog(); // Reopen dialog
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (selectedMap != null) {
      _navigationService.loadMap(selectedMap);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tải bản đồ "${selectedMap.name}"'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirmDialog(String mapName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2d3a),
        title: const Text(
          'Xác Nhận Xóa',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc muốn xóa bản đồ "$mapName"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Auto Navigation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1a1a2e),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: StatusIndicator(
              message: _currentStatus.message,
              color: _currentStatus.color,
              icon: _currentStatus.icon,
              isAnimated: _currentStatus == NavigationStatus.exploring ||
                         _currentStatus == NavigationStatus.navigating,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: Column(
          children: [
            // Map area
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(16),
                child: MapWidget(
                  exploredPoints: _exploredPoints,
                  obstacles: _obstacles,
                  currentPosition: _currentPosition,
                  targetPosition: _targetPosition,
                  onMapTap: _onMapTap,
                ),
              ),
            ),

            // Info section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    'Đã khám phá',
                    '${_exploredPoints.length} điểm',
                    Icons.explore,
                    Colors.blue,
                  ),
                  _buildInfoItem(
                    'Chướng ngại',
                    '${_obstacles.length} vật',
                    Icons.warning,
                    Colors.red,
                  ),
                  _buildInfoItem(
                    'Trạng thái',
                    _currentStatus.message,
                    _currentStatus.icon,
                    _currentStatus.color,
                  ),
                ],
              ),
            ),

            // Controls
            Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Main controls
                  Row(
                    children: [
                      Expanded(
                        child: _buildControlButton(
                          onPressed: _currentStatus == NavigationStatus.exploring
                              ? _stopExploration
                              : _startExploration,
                          icon: _currentStatus == NavigationStatus.exploring
                              ? Icons.stop
                              : Icons.explore,
                          label: _currentStatus == NavigationStatus.exploring
                              ? 'Dừng khám phá'
                              : 'Bắt đầu khám phá',
                          color: _currentStatus == NavigationStatus.exploring
                              ? Colors.red
                              : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildControlButton(
                          onPressed: _currentStatus == NavigationStatus.navigating
                              ? _stopNavigation
                              : null,
                          icon: Icons.navigation_outlined,
                          label: 'Dừng navigation',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Map management
                  Row(
                    children: [
                      Expanded(
                        child: _buildControlButton(
                          onPressed: _showSaveMapDialog,
                          icon: Icons.save,
                          label: 'Lưu bản đồ',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildControlButton(
                          onPressed: _showLoadMapDialog,
                          icon: Icons.folder_open,
                          label: 'Tải bản đồ',
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildControlButton(
                          onPressed: _resetMap,
                          icon: Icons.refresh,
                          label: 'Reset',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
} 