import 'package:flutter/foundation.dart';
import '../models/security_device.dart';
import '../services/mock_security_service.dart';

class SecurityProvider extends ChangeNotifier {
  final MockSecurityService _service;
  List<SecurityDevice> _devices = [];
  bool _isLoading = false;
  String? _error;
  
  SecurityProvider(this._service);
  
  List<SecurityDevice> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _devices = await _service.getDevices();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> refreshDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      for (var device in _devices) {
        final isOnline = await _service.checkDeviceStatus(device);
        device.isOnline = isOnline;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}