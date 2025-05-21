// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:robot_ai/services/bluetooth_service.dart';

class BleCommunicatorPage extends StatefulWidget {
  const BleCommunicatorPage({super.key});

  @override
  State<BleCommunicatorPage> createState() => _BleCommunicatorPageState();
}

class _BleCommunicatorPageState extends State<BleCommunicatorPage> {
  late BluetoothService bluetoothService;
  final String _testMessage = "Test Message";
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    // Delay để đảm bảo build hoàn tất trước khi gọi startScan
    Future.microtask(() {
      bluetoothService = Provider.of<BluetoothService>(context, listen: false);
      bluetoothService.startScan();
    });
  }

  @override
  void dispose() {
    bluetoothService.stopScan();
    super.dispose();
  }

  void _connectAndSendMessage(DiscoveredDevice device) async {
    await bluetoothService.disconnect();
    setState(() {
      _isConnecting = true;
    });

    // Hiển thị loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Đang kết nối..."),
          ],
        ),
      ),
    );

    await bluetoothService.connectToDevice(device);

    // Chờ một chút để đảm bảo kết nối đã hoàn tất
    await Future.delayed(const Duration(milliseconds: 3500));

    final success = await bluetoothService.sendMessage(_testMessage);

    // Đóng dialog loading
    Navigator.pop(context);

    setState(() {
      _isConnecting = false;
    });

    // Hiển thị thông báo và chuyển trang nếu thành công
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kết nối thành công!"),
          backgroundColor: Colors.green,
        ),
      );

      // Chuyển sang trang tiếp theo
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushNamed(context, '/control');
        // Thay thế '/control_page' bằng route của trang tiếp theo mà bạn muốn chuyển đến
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kết nối thất bại. Vui lòng thử lại."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm thiết bị'),
        actions: [
          StreamBuilder<String>(
            stream: bluetoothService.connectionStatusStream,
            builder: (context, snapshot) {
              final bool isScanning = snapshot.data != null ? true : false;
              return IconButton(
                icon: Icon(isScanning ? Icons.stop : Icons.refresh),
                onPressed: isScanning
                    ? () => bluetoothService.stopScan()
                    : () => bluetoothService.startScan(),
                tooltip: isScanning ? 'Dừng quét' : 'Quét lại',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicator khi đang scan
          StreamBuilder<String>(
            stream: bluetoothService.connectionStatusStream,
            builder: (context, snapshot) {
              final bool isScanning = snapshot.data != null ? true : false;
              return Container(
                color: Colors.blue.shade50,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    if (isScanning)
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 8),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    Text(
                      isScanning
                          ? 'Đang quét thiết bị Bluetooth...'
                          : 'Nhấn vào thiết bị để kết nối',
                      style: TextStyle(
                        color: isScanning
                            ? Colors.blue.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Danh sách thiết bị
          Expanded(
            child: StreamBuilder<List<DiscoveredDevice>>(
              stream: bluetoothService.devicesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final devices = snapshot.data ?? [];

                if (devices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bluetooth_searching,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy thiết bị nào',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => bluetoothService.startScan(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Quét lại'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: devices.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isConnected =
                        bluetoothService.connectedDevice?.id == device.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(
                          isConnected
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth,
                          color: isConnected ? Colors.blue : Colors.grey,
                          size: 32,
                        ),
                        title: Text(
                          device.name.isEmpty
                              ? "Thiết bị không xác định"
                              : device.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${device.id}'),
                            Text('RSSI: ${device.rssi} dBm'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: _isConnecting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _isConnecting
                            ? null
                            : () => _connectAndSendMessage(device),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
