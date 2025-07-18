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
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.readToken();
        if (kDebugMode) {
          print('=== HTTP REQUEST ===');
          print('Method: ${options.method}');
          print('Path: ${options.path}');
          print('Base URL: ${options.baseUrl}');
          print('Full URL: ${options.uri}');
          print('Headers: ${options.headers}');
          print('Data: ${options.data}');
          print('===================');
        }
        if (token != null) {
          if (kDebugMode) {
            print('Adding Authorization header with token: $token');
          }
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('=== HTTP RESPONSE ===');
          print('Status Code: ${response.statusCode}');
          print('Status Message: ${response.statusMessage}');
          print('Headers: ${response.headers}');
          print('Data: ${response.data}');
          print('====================');
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print('=== HTTP ERROR ===');
          print('Error Message: ${error.message}');
          print('Error Type: ${error.type}');
          print('Status Code: ${error.response?.statusCode}');
          print('Response Data: ${error.response?.data}');
          print('Request URL: ${error.requestOptions.uri}');
          print('==================');
        }
        return handler.next(error);
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

  Future<Response> getInvites(String uid) async {
  try {
    final response = await dio.get(apipath_invites);
    return response;
  } catch (e) {
    if (kDebugMode) {
      print('Error getting invites: $e');
    }
    rethrow;
  }
}

/*
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
*/

  Future<Response> acceptInvite(String groupId) async {
    try {
      final response = await dio.post(
        apipath_accept_invite,
        queryParameters: {'group_id': int.parse(groupId)},
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting invite: $e');
      }
      rethrow;
    }
  }               

  Future<Response> declineInvite(String groupId) async {
    try {
        // eliminare un invito non ritorna alcun body
        await dio.delete(
        apipath_invites,
        queryParameters: {'group_id': int.parse(groupId)},
      );
      return Future<Response<dynamic>>.value(
        Response(
          requestOptions: RequestOptions(path: 'path decline invite'),
          data: {'status': 'declined', 'inviteId': groupId},
        ),  
      );  
    } catch (e) {
      if (kDebugMode) {
        print('Error declining invite: $e');
      }
      rethrow;
    }
  }

  Future<Response> sendInvite(String groupName, String receiverName) async {
    try {
      if (kDebugMode) {
        print("Sending invite to group: $groupName for receiver: $receiverName");
      }
      final response = await dio.post(
        apipath_invites,
        data: {
          'group_name': groupName,
          'receiver_name': receiverName,
        },
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
          },
        ),
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending invite: $e');
      }
      rethrow;
    }
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
      return await dio.get(
        apipath_new_messages
      );
    }
    // Convert local timestamp to UTC before sending to server
    final utcTimestamp = lastUpdate.toUtc();
    return dio.get(
      apipath_new_messages,
      queryParameters: {
        'since': utcTimestamp.toIso8601String(),
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

  Future<Response> newChat(String name) async {
    if (kDebugMode) {
      print("Creating new chat with name: $name");
    }
    return dio.post(
      apipath_new_chat,
      data: {
        'name': name,
      },
      options: Options(
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      ),
    );
  }
}