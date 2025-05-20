import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:robot_ai/core/providers/bluetooth_service.dart';
import 'package:robot_ai/services/bluetooth_service.dart';

class BleCommunicatorPage extends StatefulWidget {
  const BleCommunicatorPage({super.key});

  @override
  State<BleCommunicatorPage> createState() => _BleCommunicatorPageState();
}

class _BleCommunicatorPageState extends State<BleCommunicatorPage> {
  late dynamic bluetoothService;
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    bluetoothService.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Communicator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => bluetoothService.startScan(),
                    child: const Text("Scan Devices"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => bluetoothService.stopScan(),
                    child: const Text("Stop Scan"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<String>(
              stream: bluetoothService.connectionStatusStream,
              builder: (context, snapshot) {
                return Text("Connection Status: ${snapshot.data ?? 'Unknown'}");
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<DiscoveredDevice?>(
              stream: bluetoothService.devicesStream
                  .map((devices) => bluetoothService.connectedDevice),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Column(
                    children: [
                      Text(
                          "Connected to: ${snapshot.data?.name ?? snapshot.data?.id}"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => bluetoothService.disconnect(),
                        child: const Text("Disconnect"),
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message to send',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final success = await bluetoothService.sendMessage(
                  _messageController.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? "✅ Sent successfully" : "❌ Failed to send"),
                  ),
                );
              },
              child: const Text("Send Message"),
            ),
            const SizedBox(height: 16),
            const Text("Discovered Devices:", style: TextStyle(fontSize: 18)),
            Expanded(
              child: StreamBuilder<List<DiscoveredDevice>>(
                stream: bluetoothService.devicesStream,
                builder: (context, snapshot) {
                  final devices = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return Card(
                        child: ListTile(
                          title: Text(device.name.isEmpty
                              ? "Unknown Device"
                              : device.name),
                          subtitle: Text(device.id),
                          trailing:
                              bluetoothService.connectedDevice?.id == device.id
                                  ? const Icon(Icons.bluetooth_connected)
                                  : null,
                          onTap: () => bluetoothService.connectToDevice(device),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
