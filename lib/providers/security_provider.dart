import 'package:flutter/foundation.dart';
import '../models/security_device.dart';
import '../services/mock_security_service.dart';
import '../services/notification_service.dart';

class SecurityProvider with ChangeNotifier {
  final _service = MockSecurityService();
  final _notificationService = NotificationService();
  List<SecurityDevice> _devices = [];
  bool _isSystemArmed = false;
  bool _isLoading = false;
  String? _error;
  bool _personDetected = false;

  SecurityProvider() {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _notificationService.initialize();
    _notificationService.startPolling();
  }

  bool get isSystemArmed => _isSystemArmed;
  List<SecurityDevice> get devices => List.unmodifiable(_devices);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get personDetected => _personDetected;

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
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _notificationService.stopPolling();
    super.dispose();
  }
}