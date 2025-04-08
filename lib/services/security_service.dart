// lib/services/security_service.dart

// Description :
// This file contains the SecurityService class which is responsible for :
// - Checking the person status.
// - Checking the connection.

// Importing Dart Convert Package.
import 'dart:convert';

// Importing HTTP Package.
import 'package:http/http.dart' as http;

// Importing Security Status Model.
import '../models/security_status.dart';

// Security Exception Class.
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  @override
  String toString() => message;
}

// Security Service Class.
class SecurityService {
  // Gadget IP.
  final String gadgetIp;

  // Client.
  final http.Client _client;
  
  // Constructor.
  SecurityService({
    required this.gadgetIp,
    http.Client? client,
  }) : _client = client ?? http.Client();

  // Check Person Status.
  Future<SecurityStatus> checkPersonStatus() async {
    try {
      // Get The Person Status.
      final response = await _client.get(
        Uri.parse('http://$gadgetIp/person_status'),
      ).timeout(const Duration(seconds: 5));
      
      // If The Status Code Is 200.
      if (response.statusCode == 200) {
        // Decode The Response.
        final jsonData = json.decode(response.body);
        
        // Update Camera Timestamps To Current Time When We Receive Data.
        if (jsonData['cameras'] is List) {
          final now = DateTime.now().millisecondsSinceEpoch;
          for (var camera in jsonData['cameras']) {
            if (camera is Map<String, dynamic>) {
              camera['lastSeen'] = now;  // Update Timestamp To Current Time.
            }
          }
        }
        
        return SecurityStatus.fromJson(jsonData);
      }
      throw SecurityException('Failed To Fetch Status');
    } catch (e) {
      throw SecurityException('Network Error: $e');
    }
  }

  // Check Connection.
  Future<bool> checkConnection() async {
    try {
      // Get The Connection.
      final response = await _client.get(
        Uri.parse('http://$gadgetIp/ping'),
      ).timeout(const Duration(seconds: 5));

      // If The Status Code Is 200.
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
