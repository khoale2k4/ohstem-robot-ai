// lib/features/manual_control/presentation/manual_control_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:robot_ai/features/main/manual_control/presentation/widgets/joysticks.dart';
import 'package:robot_ai/features/main/manual_control/presentation/widgets/tracking_status.dart';

class ManualControlPage extends StatefulWidget {
  const ManualControlPage({Key? key}) : super(key: key);

  @override
  State<ManualControlPage> createState() => _ManualControlPageState();
}

class _ManualControlPageState extends State<ManualControlPage> {
  Offset _leftJoystickValue = Offset.zero;
  final TrackingStatus _trackingStatus = TrackingStatus.tracking;
  Timer? _rotateTimer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Control'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child:
                      _buildJoystickIndicator('Movement', _leftJoystickValue),
                ),
                TrackingStatusWidget(status: _trackingStatus),
              ],
            ),
            const Spacer(),
            LeftJoystick(
              onDirectionChanged: (value) {
                setState(() => _leftJoystickValue = value);
                _sendMovementCommand();
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRotateButton(Icons.rotate_left, 'left'),
                const SizedBox(width: 32),
                _buildRotateButton(Icons.rotate_right, 'right'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoystickIndicator(String label, Offset value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: X=${value.dx.toStringAsFixed(2)}, Y=${value.dy.toStringAsFixed(2)}',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildRotateButton(IconData icon, String direction) {
    return GestureDetector(
      onTapDown: (_) => _startRotation(direction),
      onTapUp: (_) => _stopRotation(),
      onTapCancel: _stopRotation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  void _startRotation(String direction) {
    _sendRotationCommand(direction); // gọi ngay khi bắt đầu
    _rotateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _sendRotationCommand(direction);
    });
  }

  void _sendMovementCommand() {
    debugPrint('Movement: ${_leftJoystickValue}');
    // sendMessage(context, message, _ble, _writeCharacteristic)
  }

  void _sendRotationCommand(String direction) {
    debugPrint('Rotate $direction');
    // Gửi lệnh quay trái/phải
  }

  void _stopRotation() {
    _rotateTimer?.cancel();
    _rotateTimer = null;
  }
}
