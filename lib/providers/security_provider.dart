import 'package:flutter/foundation.dart';
import '../models/security_device.dart';
import '../services/mock_security_service.dart';

class SecurityProvider with ChangeNotifier {
  final _service = MockSecurityService();
  List<SecurityDevice> _devices = [];
  bool _isSystemArmed = false;
  bool _isLoading = false;
  String? _error;
  List<String> _connectedDevices = [];
  
  bool get isSystemArmed => _isSystemArmed;
  List<SecurityDevice> get devices => List.unmodifiable(_devices);
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get connectedDevices => List.unmodifiable(_connectedDevices);

  void toggleSystem() {
    _isSystemArmed = !_isSystemArmed;
    notifyListeners();
  }

  Future<void> refreshDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _devices = await _service.getDevices();
      for (var device in _devices) {
        final isOnline = await _service.checkDeviceStatus(device.id);
        device.isOnline = isOnline;
      }
      _connectedDevices = ['Camera 1', 'Camera 2', 'Motion Sensor 1'];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addDevice(String deviceId) {
    if (!_connectedDevices.contains(deviceId)) {
      _connectedDevices.add(deviceId);
      notifyListeners();
    }
  }

  void removeDevice(String deviceId) {
    if (_connectedDevices.remove(deviceId)) {
      notifyListeners();
    }
  }
}