import 'package:flutter/foundation.dart';
import '../models/security_device.dart';
import '../services/security_service.dart';

class SecurityProvider extends ChangeNotifier {
  final SecurityService _service;
  List<SecurityDevice> _devices = [];
  bool _isLoading = false;
  String? _error;
  
  SecurityProvider(this._service);
  
  List<SecurityDevice> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> addDevice(SecurityDevice device) async {
    _devices.add(device);
    await _checkDeviceStatus(device);
    notifyListeners();
  }
  
  Future<void> _checkDeviceStatus(SecurityDevice device) async {
    final isOnline = await _service.checkDeviceStatus(device);
    final index = _devices.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      _devices[index].isOnline = isOnline;
      notifyListeners();
    }
  }
  
  Future<void> refreshDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      for (var device in _devices) {
        await _checkDeviceStatus(device);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}