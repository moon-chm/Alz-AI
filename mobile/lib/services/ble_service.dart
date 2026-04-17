import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {
  static const HR_SERVICE = "0000180d-0000-1000-8000-00805f9b34fb";
  static const HR_CHAR = "00002a37-0000-1000-8000-00805f9b34fb";
  static const BAT_SERVICE = "0000180f-0000-1000-8000-00805f9b34fb";
  static const BAT_CHAR = "00002a19-0000-1000-8000-00805f9b34fb";

  BluetoothDevice? _watch;
  final _hrController = StreamController<int>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  bool _connected = false;
  DateTime? _disconnectedAt;

  Stream<int> get heartRateStream => _hrController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _connected;

  // Auto scan and connect on startup
  Future<void> initialize() async {
    if (!await FlutterBluePlus.isSupported) return;
    await _startScan();
  }

  Future<void> _startScan() async {
    await FlutterBluePlus.startScan(
      withServices: [Guid(HR_SERVICE)],
      timeout: Duration(seconds: 15),
    );

    FlutterBluePlus.scanResults.listen((results) {
      if (results.isNotEmpty && !_connected) {
        FlutterBluePlus.stopScan();
        _connect(results.first.device);
      }
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: true);
      _watch = device;
      _connected = true;
      _connectionController.add(true);
      await _subscribeToHR();
      _monitorConnection();
    } catch (e) {
      _connected = false;
      // Retry after 30 seconds
      Future.delayed(Duration(seconds: 30), _startScan);
    }
  }

  Future<void> _subscribeToHR() async {
    if (_watch == null) return;
    List<BluetoothService> services = await _watch!.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == HR_SERVICE) {
        for (var char in service.characteristics) {
          if (char.uuid.toString() == HR_CHAR) {
            await char.setNotifyValue(true);
            char.onValueReceived.listen((value) {
              if (value.length >= 2) {
                int hr = value[1]; // HR value per GATT spec
                _hrController.add(hr);
              }
            });
          }
        }
      }
    }
  }

  void _monitorConnection() {
    _watch?.connectionState.listen((state) {
      _connected = state == BluetoothConnectionState.connected;
      _connectionController.add(_connected);
      if (!_connected) {
        _disconnectedAt = DateTime.now();
        // Retry connection every 60 seconds
        Future.delayed(Duration(seconds: 60), _startScan);
      }
    });
  }

  Future<int> getBatteryLevel() async {
    if (_watch == null || !_connected) return -1;
    try {
      List<BluetoothService> services = await _watch!.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == BAT_SERVICE) {
          for (var char in service.characteristics) {
            if (char.uuid.toString() == BAT_CHAR) {
              List<int> value = await char.read();
              return value.isNotEmpty ? value[0] : -1;
            }
          }
        }
      }
    } catch (e) {
      return -1;
    }
    return -1;
  }

  Duration? get disconnectedDuration {
    if (_connected || _disconnectedAt == null) return null;
    return DateTime.now().difference(_disconnectedAt!);
  }

  void dispose() {
    _hrController.close();
    _connectionController.close();
    _watch?.disconnect();
  }
}
