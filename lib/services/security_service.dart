import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/security_status.dart';

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  @override
  String toString() => message;
}

class SecurityService {
  final String gadgetIp;
  final http.Client _client;
  
  SecurityService({
    required this.gadgetIp,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<SecurityStatus> checkPersonStatus() async {
    try {
      final response = await _client.get(
        Uri.parse('http://$gadgetIp/person_status'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Update camera timestamps to current time when we receive data
        if (jsonData['cameras'] is List) {
          final now = DateTime.now().millisecondsSinceEpoch;
          for (var camera in jsonData['cameras']) {
            if (camera is Map<String, dynamic>) {
              camera['lastSeen'] = now;  // Update timestamp to current time
            }
          }
        }
        
        return SecurityStatus.fromJson(jsonData);
      }
      throw SecurityException('Failed to fetch status');
    } catch (e) {
      throw SecurityException('Network error: $e');
    }
  }

  Future<bool> checkConnection() async {
    try {
      final response = await _client.get(
        Uri.parse('http://$gadgetIp/ping'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

}
