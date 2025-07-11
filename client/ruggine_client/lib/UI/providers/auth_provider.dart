import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api_client.dart';
import '../../data/auth_repo.dart';
import '../../models/user.dart';

final authRepositoryProvider = Provider<AuthRepo>((ref) {
  return AuthRepo(ApiClient());
});

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<User?> {
  final AuthRepo repo;

  AuthNotifier(this.repo) : super(null) {
    _checkLogin();
  }

  void _checkLogin() async {
    final user = await repo.getCurrentUser();
    state = user;
  }

  Future<void> login(String username, String password) async {
    try {
      final user = await repo.login(username, password);
      state = user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    await repo.logout();
    state = null;
  }
}
