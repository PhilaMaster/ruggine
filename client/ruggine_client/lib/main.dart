import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ruggine_client/UI/providers/chats_provider.dart';
import 'package:ruggine_client/core/const.dart';

import 'UI/pages/home_page.dart';
import 'UI/pages/login_page.dart';
import 'UI/pages/settings.dart';
import 'UI/providers/auth_provider.dart';
import 'UI/providers/message_service.dart';
import 'UI/providers/theme_provider.dart';
import 'models/chat.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  final isLoggedIn = auth != null;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (kDebugMode) {
        print(state.uri.toString());
      }
      final location = state.uri.toString();
      if (!isLoggedIn && location != '/login') return '/login';
      if (isLoggedIn && location == '/login') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => HomePage()),
      GoRoute(path: route_home, builder: (_, __) => HomePage()),
      GoRoute(path: route_login, builder: (_, __) => LoginPage()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    ],
  );
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ChatAdapter());
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Ruggine Chat',
      routerConfig: router,
      scaffoldMessengerKey: MessageService.messengerKey,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}