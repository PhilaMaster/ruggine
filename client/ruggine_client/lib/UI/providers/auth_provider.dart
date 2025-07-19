import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruggine_client/UI/providers/messages_provider.dart';
import '../../data/api_client.dart';
import '../../data/auth_repo.dart';
import '../../models/user.dart';
import 'websocket_provider.dart';
import 'chats_provider.dart';
import 'invites_provider.dart';

final authRepositoryProvider = Provider<AuthRepo>((ref) {
  return AuthRepo(ApiClient(ref));
});

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthNotifier(repo, ref);
});

class AuthNotifier extends StateNotifier<User?> {
  final AuthRepo repo;
  final Ref ref;

  AuthNotifier(this.repo, this.ref) : super(null) {
    _checkLogin();
  }

  void _checkLogin() async {
    final user = await repo.getCurrentUser();
    if (user == null) {
      await logout();
    } else {
      state = user;
      // Inizializza WebSocket e recupera messaggi se l'utente è già autenticato
      await _initializeUserSession(user.id);
    }
  }

  Future<String?> get token {
    return repo.getToken();
  }

  String? get currentUsername => state?.username;
  String? get currentUserId => state?.id;

  Future<void> login(String username, String password) async {
    final user = await repo.login(username, password);
    if (user == null) {
      await logout();
    } else {
      state = user;
      // Inizializza WebSocket e recupera messaggi dopo login riuscito
      await _initializeUserSession(user.id);
    }
  }

  Future<void> logout() async {
    // Disconnetti WebSocket prima del logout
    await _cleanupUserSession();
    await repo.logout();
    state = null;
  }

  // Inizializza WebSocket e recupera dati dell'utente
  Future<void> _initializeUserSession(String uid) async {
    try {
      // Il WebSocket si connetterà automaticamente grazie al listener nel WebSocketNotifier
      //TODO start websocket connection
      //TODO load stored invites
      await ref.read(chatProvider.notifier).loadLocalChats(uid);
      await ref.read(msgProvider.notifier).loadNewMessages(uid);
      if (kDebugMode) {
        print('Inizializzazione sessione utente: ${state?.username}');
      }
      // Recupera gli inviti pending
      ref.read(invitesProvider.notifier).loadInvites(uid);
      // Inizializza WebSocket con il token
      ref.read(webSocketProvider.notifier).connect(uid);
    } catch (e) {
      // Gestisci errori di inizializzazione
      print('Errore durante l\'inizializzazione della sessione: $e');
    }
  }

  // Pulisce risorse quando l'utente si disconnette
  Future<void> _cleanupUserSession() async {
    try {
      ref.watch(chatProvider.notifier).cleanup();
      ref.watch(msgProvider.notifier).cleanup();
      ref.watch(invitesProvider.notifier).cleanup();
      ref.watch(webSocketProvider.notifier).disconnect();
    } catch (e) {
      if (kDebugMode) {
        print('Errore durante la pulizia della sessione: $e');
      }
    }
  }
}
