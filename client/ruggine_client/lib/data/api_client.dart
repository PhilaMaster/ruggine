import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/storage.dart';
import '../core/const.dart';

class ApiClient {
  late final Dio dio;

  ApiClient(){
    dio = Dio(BaseOptions(
      baseUrl: apibase,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.readToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
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

  Future<Response> getInvites() {
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
    return Future<Response<dynamic>>.value(
      Response(
        requestOptions: RequestOptions(path: 'path accept invite'),
        data: {'status': 'accepted', 'inviteId': inviteId},
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
            'senderId': 'Reba',
            'content': 'Hello, how are you?',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
          },
          {
            'id': '2',
            'senderId': 'John',
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
    return Future<Response<dynamic>>.value(
      Response(
        requestOptions: RequestOptions(path: 'path send message'),
        data: {
          'id' : 3,
          'senderName': 'pasquale', // Replace with actual user name
          'content': content,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }
}