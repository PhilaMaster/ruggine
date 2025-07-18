// lib/core/config.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:dio/dio.dart';

class AppConfig {
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://192.168.126.87:8080/'; // Use your LAN IP for web
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/'; // Android emulator
    } else if (Platform.isIOS) {
      return 'http://localhost:8080/'; // iOS simulator
    } else {
      return 'http://localhost:8080/'; // Fallback for desktop
    }
  }

  static String get webSocketUrl {
    if (kIsWeb) {
      return 'ws://192.168.126.87:8080/ws'; // Use your LAN IP for web
    } else if (Platform.isAndroid) {
      return 'ws://10.0.2.2:8080/ws'; // Android emulator
    } else if (Platform.isIOS) {
      return 'ws://localhost:8080/ws'; // iOS simulator
    } else {
      return 'ws://localhost:8080/ws'; // Fallback for desktop
    }
  }

  // Test di connettività per diagnosticare problemi di rete
  static Future<void> testConnectivity() async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    final url = apiBaseUrl;

    if (kDebugMode) {
      print('=== CONNECTIVITY TEST ===');
      print('Testing connection to: $url');
      print('Platform: ${Platform.operatingSystem}');
      print('isAndroid: ${Platform.isAndroid}');
      print('isWeb: $kIsWeb');
    }

    try {
      // Test basic HTTP connectivity
      final response = await dio.get(
        '${url}auth/login',
        options: Options(
          validateStatus: (status) => true, // Accept any status for testing
        ),
      );

      if (kDebugMode) {
        print('Connection SUCCESS!');
        print('Status: ${response.statusCode}');
        print('Headers: ${response.headers}');
        print('========================');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Connection FAILED!');
        print('Error: $e');
        print('Error type: ${e.runtimeType}');
        if (e is DioException) {
          print('DioException type: ${e.type}');
          print('DioException message: ${e.message}');
        }
        print('========================');
      }
    }
  }
}
