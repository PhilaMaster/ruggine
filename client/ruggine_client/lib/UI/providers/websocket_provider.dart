import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruggine_client/UI/providers/invites_provider.dart';
import 'package:ruggine_client/core/storage.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../config.dart';
import '../../models/invite.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import 'auth_provider.dart';
import 'messages_provider.dart';

enum WebSocketStatus { disconnected, connecting, connected, error }

class WebSocketState {
  final WebSocketStatus status;
  final String? errorMessage;

  WebSocketState({
    required this.status,
    this.errorMessage,
  });

  WebSocketState copyWith({
    WebSocketStatus? status,
    String? errorMessage,
  }) {
    return WebSocketState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

final webSocketProvider = StateNotifierProvider<WebSocketNotifier, WebSocketState>((ref) {
  return WebSocketNotifier(ref);
});

class WebSocketNotifier extends StateNotifier<WebSocketState> {
  final Ref ref;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 2;
  static const Duration reconnectDelay = Duration(seconds: 3);
  static const Duration pingInterval = Duration(seconds: 30);

  WebSocketNotifier(this.ref) : super(WebSocketState(status: WebSocketStatus.disconnected)) {}

  Future<void> connect() async {
    final user = ref.read(authProvider);
    if (user == null) {
      state = state.copyWith(
        status: WebSocketStatus.error,
        errorMessage: 'Utente non autenticato',
      );
      return;
    }

    if (_channel != null) {
      await disconnect();
    }

    try {
      state = state.copyWith(status: WebSocketStatus.connecting);
      final token = await ref.read(authProvider.notifier).token;
      // Sostituisci con l'URL del tuo WebSocket
      final uri = Uri(
        scheme: 'ws',
        host: Uri.parse(AppConfig.webSocketUrl).host,
        port: Uri.parse(AppConfig.webSocketUrl).port,
        path: '/ws',
        queryParameters: {'token': token},
        fragment: null,
      );
      if (kDebugMode) {
        print('Connessione WebSocket a: $uri');
      }
      _channel = IOWebSocketChannel.connect(uri,
          headers: {
            'Authorization': 'Bearer $token',
          });

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
      );

      state = state.copyWith(
        status: WebSocketStatus.connected,
        errorMessage: null,
      );
      _startPingTimer();

    } catch (e) {
      _onError(e);
    }
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();

    await _subscription?.cancel();
    await _channel?.sink.close();

    _subscription = null;
    _channel = null;

    state = state.copyWith(status: WebSocketStatus.disconnected);
  }

  void _onMessage(dynamic data) {
    try {
      final message = jsonDecode(data);
      // Gestisci solo messaggi in arrivo
      switch (message['type']) {
        case 'new_message':
          _handleNewMessage(message);
          break;
        case 'group_invite':
          _handleGroupInvite(message);
          break;
        case 'ping':
          // Rispondi al ping se necessario
          if (kDebugMode) {
            print('Ping ricevuto, nessuna azione necessaria');
          }
          break;
        default:
          if (kDebugMode) {
            print('Tipo di messaggio WebSocket sconosciuto: ${message['type']}');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Errore nel parsing del messaggio WebSocket: $e');
      }
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = Message.fromJson(data['message']);
      final chatId = data['chat_id'] as String?;
      ref.read(msgProvider.notifier).newMessage(chatId, message);
    } catch (e) {
      if (kDebugMode) {
        print('Errore nel gestire nuovo messaggio: $e');
      }
    }
  }

  void _handleGroupInvite(Map<String, dynamic> data) {
    // Gestisci nuovi inviti ai gruppi
    if (data['invite'] == null) {
      print('Invito non valido: ${data['invite']}');
      return;
    }
    final invite = Invite.fromJson(data['invite']);
    ref.read(invitesProvider.notifier).receiveInvite(invite);
  }

  void _onError(error) {
    print('Errore WebSocket: $error');
    state = state.copyWith(
      status: WebSocketStatus.error,
      errorMessage: error.toString(),
    );
    _scheduleReconnect();
  }

  void _onDisconnected() {
    print('WebSocket disconnesso');
    state = state.copyWith(status: WebSocketStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    print("tenativo di riconnessione: ${_reconnectAttempts + 1}/$maxReconnectAttempts");
    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      _reconnectTimer = Timer(reconnectDelay, () {
        if (ref.read(authProvider) != null) {
          connect();
        }
      });
    }
    else{
      print('Raggiunto il numero massimo di tentativi di riconnessione');
      state = state.copyWith(
        status: WebSocketStatus.error,
        errorMessage: 'Raggiunto il numero massimo di tentativi di riconnessione',
      );
      _reconnectTimer?.cancel();
    }
  }

  void _startPingTimer() {
    _pingTimer = Timer.periodic(pingInterval, (timer) {
      if (_channel != null && state.status == WebSocketStatus.connected) {
        _channel!.sink.add(jsonEncode({'type': 'ping'}));
      }
    });
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  // Stato della connessione
  bool get isConnected => state.status == WebSocketStatus.connected;
  bool get isConnecting => state.status == WebSocketStatus.connecting;
  bool get hasError => state.status == WebSocketStatus.error;
}
