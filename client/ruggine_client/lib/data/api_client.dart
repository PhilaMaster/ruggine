import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ruggine_client/models/chat.dart';
import '../core/storage.dart';
import '../core/const.dart';
import '../core/dio_interceptor.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiClient {
  late final Dio dio;
  late final WebSocketChannel webSocket;

  ApiClient([Ref? ref]){
    dio = Dio(BaseOptions(
      baseUrl: apibase,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.readToken();
        if (kDebugMode) {
          print('Requesting: ${options.method} ${options.path}');
        }
        if (token != null) {
          if (kDebugMode) {
            print('Adding Authorization header with token: $token');
          }
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
    // Aggiungi l'interceptor per gestire 401/403
    if (ref != null) {
      dio.interceptors.add(AuthInterceptor(ref));
    }
  }

  Future<Response> login(String username, String pword){
    var x = dio.options.baseUrl;
    if (kDebugMode){
      print('Logging in at $x$apipath_login  with email: $username');
    }
    return dio.post(apipath_login, data: {
      'username': username,
      'password': pword,
    });
  }

  Future<Response> register(String email, String pword){
    return dio.post(apipath_register, data: {
      'email': email,
      'password': pword,
    });
  }

  Future<Response> getUser() {
    return dio.get(apipath_user);
  }

  Future<Response> getChats() {
    //for now return fake chats
    return Future<Response<dynamic>>.value(
      Response(
        requestOptions: RequestOptions(path: 'path chats'),
        data: [
          {
            'id': '1',
            'lastSender': 'Reba',
            'lastMessage': 'Hello from Reba',
            'lastTime': DateTime.now().toIso8601String(),
          },
          {
            'id': '2',
            'lastSender': 'John',
            'lastMessage': 'Hello from John',
            'lastTime': DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
          },
        ],
      ),
    );
  }

  Future<Response> getInvites(String uid) {
    //for now return fake invites
    return Future<Response<dynamic>>.value(
      Response(
        requestOptions: RequestOptions(path: 'path invites'),
        data: [
          {
            'groupName': 'The Sussoni',
            'id': '1',
            'senderName': 'Reba',
          },
          {
            'groupName': 'The Cumarans',
            'id': '2',
            'senderName': 'Sandro',
          },
        ],
      ),
    );
  }

  Future<Response> acceptInvite(String inviteId) {
    // Simulate accepting an invite
    if (kDebugMode) {
      print("Accepting invite: $inviteId");
    }
    //assume group info are returned
    final chatInfo = Chat(
      id: inviteId,
      lastSender: 'Reba',
      lastMessage: 'Welcome to the group!',
      lastTime: DateTime.now(),
      newMessages: 0,
      name: 'The Sussoni',
      created_by: 'Reba',
      members: ['Reba', 'Sandro', 'John'],
      is_group: true,
      created_at: DateTime.now(),
    );
    return Future<Response<dynamic>>.value(
      Response(
        requestOptions: RequestOptions(path: 'path accept invite'),
        data: chatInfo.toJson(),
      ),
    );
  }

  Future<Response> declineInvite(String inviteId) {
    // Simulate declining an invite
    if (kDebugMode) {
      print("Declining invite: $inviteId");
    }
    return Future<Response<dynamic>>.value(
      Response(
        requestOptions: RequestOptions(path: 'path decline invite'),
        data: {'status': 'declined', 'inviteId': inviteId},
      ),
    );
  }

  Future<Response> sendInvite(String groupName) {
    // Simulate sending an invite
    if (kDebugMode) {
      print("Sending invite to group: $groupName");
    }
    return Future<Response<dynamic>>.value(
      Response(
        requestOptions: RequestOptions(path: 'path send invite'),
        data: {'status': 'sent', 'groupName': groupName},
      ),
    );
  }

  Future<Response> getMessages(String chatId) {
    //for now return fake messages
    return Future<Response<dynamic>>.value(
      Response(
        requestOptions: RequestOptions(path: 'path messages'),
        data: [
          {
            'id': '1',
            'senderName': 'Reba',
            'content': 'Hello, how are you?',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
          },
          {
            'id': '2',
            'senderName': 'John',
            'content': 'I am fine, thank you! How about you?',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 3)).toIso8601String(),
          },
        ],
      ),
    );
  }

  Future<Response> sendMessage(String chatId, String content) {
    // Simulate sending a message
    if (kDebugMode) {
      print("Sending message to chat $chatId: $content");
    }
    return dio.post(
        apipath_send_msg,
        data: {
          'chat_id': int.parse(chatId),
          'content': content,
        },
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
          },
        )
    );
  }

  Future<void> initSocket(String token) async {
    if (kDebugMode) {
      print("Initializing WebSocket with token: $token");
    }
    webSocket = WebSocketChannel.connect(
        Uri.parse(websocketUrl),
        );
    await webSocket.ready;
  }

  Future<Response> getNewMessages(DateTime? lastUpdate) async {
    if (lastUpdate == null) {
      return dio.get(
        apipath_new_messages
      );
    }
    return dio.get(
      apipath_new_messages,
      queryParameters: {
        'since': lastUpdate.toIso8601String(),
      },
    );
  }

  Future<Response> getChatInfo(String chatId) async {
    if (kDebugMode) {
      print("Fetching chat info for chat ID: $chatId");
    }
    final response = await dio.get(
      '$apipath_chat_info',
      queryParameters: {'chat_id': chatId},
    );
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to load chat info');
    }
  }
}