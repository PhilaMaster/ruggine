import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api_client.dart';
import '../../data/auth_repo.dart';

final authRepositoryProvider = Provider<AuthRepo>((ref) {
  return AuthRepo(ApiClient());
});

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<bool> {
  final AuthRepo repo;

  AuthNotifier(this.repo) : super(false) {
    _checkLogin();
  }

  void _checkLogin() async {
    state = await repo.isLoggedIn();
  }

  Future<void> login(String username, String password) async {
    try{
      await repo.login(username, password);
      state = true;
    }catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  void logout() async {
    await repo.logout();
    state = false;
  }
}
