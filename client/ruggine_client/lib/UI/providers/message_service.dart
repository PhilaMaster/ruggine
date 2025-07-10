import 'package:flutter/material.dart';

class MessageService {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show(String message) {
    final messenger = messengerKey.currentState;
    if (messenger != null) {
      messenger.showSnackBar(SnackBar(content: Text(message), duration: Duration(seconds: 5)));
    }
  }
}