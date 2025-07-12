import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ruggine_client/UI/pages/chat_page.dart';
import 'package:ruggine_client/core/const.dart';
import 'package:window_manager/window_manager.dart';

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
      GoRoute(path: '/chat/:chatId', builder: (context, state) {
        final chatId = state.pathParameters['chatId'];
        if (chatId == null) {
          return const Center(child: Text('Chat ID is missing'));
        }
        final chat = state.extra as Chat?;
        if (chat == null) {
          return const Center(
            child: Text('Chat not found or not provided'),
          );
        }
        return ChatPage(chat: chat);
      }),
    ],
  );
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure window constraints for desktop platforms
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600), // Default window size
      minimumSize: Size(400, 500), // Minimum window size
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

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