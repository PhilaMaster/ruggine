import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import '../core/storage.dart';


class AuthRepo{
  late final ApiClient _apiClient;

  AuthRepo(this._apiClient);

  Future<String?> login(String username, String password) async {
    if (kDebugMode) {
      print("Attempting to login with username: $username");
    }
    try {
      await _apiClient.login(username, password).then((response) {
        if (kDebugMode) {
          print("Login successful, response: ${response.data}");
        }
        final token = response.data['token'];
        SecureStorage.writeToken(token);
      }).catchError((error) {
        throw Exception("Login failed");
      });
    }on DioException catch (err) {
      if (kDebugMode) {
        print("${err.response?.data['error']}");
      }
      return err.response?.data['error'];
    }
    catch (e) {
      if (kDebugMode) {
        print("An unexpected error occurred: ${e.toString()}");
      }
      return "An unexpected error occurred: $e";
    }
    return null;
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.readToken();
    return token != null;
  }
}