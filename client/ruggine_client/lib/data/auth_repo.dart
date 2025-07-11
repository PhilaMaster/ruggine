import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../models/user.dart';
import 'api_client.dart';
import '../core/storage.dart';


class AuthRepo{
  late final ApiClient _apiClient;

  AuthRepo(this._apiClient);

  // Future<String> login(String username, String password) async {
  //   if (kDebugMode) {
  //     print("Attempting to login with username: $username");
  //   }
  //   await _apiClient.login(username, password).then((response) {
  //     if (response.statusCode != 200) {
  //       throw Exception('Login failed with status code: ${response.statusCode}');
  //     }
  //     final token = response.data['token'];
  //     SecureStorage.writeToken(token);
  //   });
  //   return "Login successful";
  // }

  Future<User> login(String username, String password) async {
    if (kDebugMode) {
      print("Attempting to login with username: $username");
    }

    String? token;
    await _apiClient.login(username, password).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Login failed with status code: ${response.statusCode}');
      }
      token = response.data['token'];
      SecureStorage.writeToken(token!);
    });

    if (token == null) throw Exception('Token non trovato');

    // Decodifica JWT per ottenere username e id
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['user_id']?.toString() ?? '';
    final userName = decodedToken['username'] ?? '';

    return User(
      id: userId,
      username: userName,
      // ...altri campi se necessari...
    );
  }

  Future<User?> getCurrentUser() async {
    final token = await SecureStorage.readToken();
    if (token == null) return null;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final userId = decodedToken['user_id']?.toString() ?? '';
    final userName = decodedToken['username'] ?? '';

    return User(
      id: userId,
      username: userName,
      // ...altri campi se necessari...
    );
  }


  Future<void> logout() async {
    await SecureStorage.deleteToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.readToken();
    return token != null;
  }
}