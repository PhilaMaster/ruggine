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
}