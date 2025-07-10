import 'package:flutter/foundation.dart';

import 'api_client.dart';
import '../core/storage.dart';


class AuthRepo{
  late final ApiClient _apiClient;

  AuthRepo(this._apiClient);

  Future<String> login(String username, String password) async {
    if (kDebugMode) {
      print("Attempting to login with username: $username");
    }
    await _apiClient.login(username, password).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Login failed with status code: ${response.statusCode}');
      }
      final token = response.data['token'];
      SecureStorage.writeToken(token);
    });
    return "Login successful";
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.readToken();
    return token != null;
  }
}