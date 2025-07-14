// lib/core/config.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

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
}
