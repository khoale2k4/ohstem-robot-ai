import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:robot_ai/core/widgets/follow_controls.dart';
import 'package:robot_ai/core/widgets/status_indicator.dart';
import 'package:robot_ai/services/ai_model_service.dart';
import 'dart:async';

import 'package:robot_ai/services/bluetooth_service.dart';

class FollowHumanPage extends StatefulWidget {
  const FollowHumanPage({Key? key}) : super(key: key);

  @override
  State<FollowHumanPage> createState() => _FollowHumanPageState();
}

class _FollowHumanPageState extends State<FollowHumanPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isFollowing = false;
  AIModelService? aiModelService;
  bool _isCameraInitialized = false;
  Rect? _humanBoundingBox;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  CameraStatus _cameraStatus = CameraStatus.starting;

  Timer? _detectionTimer;
  bool _isProcessing = false;

  // Robot control
  String _currentCommand = "stop";
  int _confidence = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Initialize pulse animation for detection box
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _initializeSystem();
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _pulseController.dispose();
    _cameraController?.dispose();
    aiModelService?.dispose();
    super.dispose();
  }

  Future<void> _initializeSystem() async {
    setState(() {
      _cameraStatus = CameraStatus.starting;
    });
    aiModelService = Provider.of<AIModelService>(context, listen: false);

    final modelInitialized = await aiModelService?.initializeModel();
    if (modelInitialized == null || !modelInitialized) {
      setState(() {
        _cameraStatus = CameraStatus.error;
      });
      return;
    }
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraStatus = CameraStatus.active;
        });
      }
    } catch (e) {
      debugPrint("Camera error: $e");
      setState(() {
        _cameraStatus = CameraStatus.error;
      });
    }
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
      if (_isFollowing) {
        _startHumanDetection();
      } else {
        _stopHumanDetection();
      }
    });
  }

  void _startHumanDetection() {
    if (aiModelService == null || _cameraController == null) {
      debugPrint("AI model hoặc camera chưa sẵn sàng");
      return;
    }

    // Bắt đầu xử lý frame định kỳ
    _detectionTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _processCurrentFrame();
    });
  }

  Future<void> _processCurrentFrame() async {
    if (_isProcessing || !_isFollowing || _cameraController == null) {
      return;
    }

    _isProcessing = true;

    try {
      final image = await _cameraController!.takePicture();
      final result = await aiModelService?.processFrame(image);

      print("Ai result: $image");
      print("AI result: $result");
      if (result != null && mounted) {
        _handleAIResult(result);
      }
    } catch (e) {
      debugPrint("Lỗi xử lý frame: $e");
    } finally {
      _isProcessing = false;
    }
  }

  // Simulation - thay thế bằng _aiService.processFrame(cameraImage)
  // Future<Map<String, dynamic>?> _simulateFrameProcessing() async {
  //   await Future.delayed(const Duration(milliseconds: 100));

  //   // Giả lập kết quả từ AI
  //   final hasHuman = DateTime.now().millisecond % 4 != 0;

  //   if (hasHuman) {
  //     return {
  //       "box": [150, 200, 200, 300], // x, y, width, height
  //       "confident": 85,
  //       "controll": "follow"
  //     };
  //   } else {
  //     return {"box": [], "confident": 0, "controll": "search"};
  //   }
  // }

  void _handleAIResult(Map<String, dynamic> result) {
    final box = result['box'] as List<dynamic>?;
    final confident = result['confident'] as int? ?? 0;
    final controll = result['controll'] as String? ?? 'stop';

    setState(() {
      _confidence = confident;
      _currentCommand = controll;

      if (box != null && box.isNotEmpty && box.length >= 4) {
        // Tạo bounding box từ kết quả AI
        _humanBoundingBox = Rect.fromLTWH(
          box[0].toDouble(),
          box[1].toDouble(),
          box[2].toDouble(),
          box[3].toDouble(),
        );
        _pulseController.repeat(reverse: true);
      } else {
        _humanBoundingBox = null;
        _pulseController.stop();
      }
    });

    // Gửi lệnh điều khiển robot
    _sendRobotCommand(controll);
  }

  void _sendRobotCommand(String command) {
    debugPrint("Robot command: $command");
    // TODO: Gửi lệnh thực tế đến robot qua Bluetooth/WiFi
    switch (command) {
      case 'follow':
        debugPrint("Robot đang theo dõi người (confidence: $_confidence%)");
        break;
      case 'search':
        debugPrint("Robot đang tìm kiếm người");
        break;
      case 'stop':
        debugPrint("Robot dừng");
        break;
    }
  }

  void _stopHumanDetection() {
    _detectionTimer?.cancel();
    setState(() {
      _humanBoundingBox = null;
      _currentCommand = "stop";
      _confidence = 0;
      _isFollowing = false;
    });
    _pulseController.stop();
  }

  void _stopRobot() {
    // setState(() {
    //   _isFollowing = false;
    //   _currentCommand = "stop";
    //   _stopHumanDetection();
    // });
    // debugPrint("Robot stopped manually");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Follow Human',
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
              message: _cameraStatus.message,
              color: _cameraStatus.color,
              icon: _cameraStatus.icon,
              isAnimated: _cameraStatus == CameraStatus.starting,
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
        child: Stack(
          children: [
            // Camera preview
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _isCameraInitialized && _cameraController != null
                      ? CameraPreview(_cameraController!)
                      : _buildLoadingView(),
                ),
              ),
            ),

            // Human detection box
            if (_humanBoundingBox != null)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Positioned.fromRect(
                    rect: _humanBoundingBox!,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            // Confidence label
                            Positioned(
                              top: -25,
                              left: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Human $_confidence%',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Info overlay
            if (_isFollowing)
              Positioned(
                top: 100,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Command: $_currentCommand',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_confidence > 0)
                        Text(
                          'Confidence: $_confidence%',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: FollowControls(
                  isFollowing: _isFollowing,
                  onToggleFollow: _toggleFollow,
                  onStopPressed: _stopRobot,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_cameraStatus.color),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              _cameraStatus.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
