import 'package:flutter/material.dart';
import 'package:robot_ai/services/bluetooth_service.dart';

class BluetoothServiceProvider extends ChangeNotifier {
  BluetoothService _bluetoothService = BluetoothService();

  BluetoothService get service => _bluetoothService;

  Future<void> disposeService() async {
    await _bluetoothService.dispose();
    super.dispose();
  }
}
