import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruggine_client/core/const.dart';

import 'UI/pages/home_page.dart';
import 'UI/pages/login_page.dart';
import 'UI/pages/settings.dart';
import 'UI/providers/auth_provider.dart';
import 'UI/providers/theme_provider.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isLoggedIn = user != null;
    final themeMode = ref.watch(themeNotifierProvider);

    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        print(state.uri.toString());
        if (!isLoggedIn && state.uri.toString() != '/login') return '/login';
        if (isLoggedIn && state.uri.toString() == '/login') return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => HomePage()),
        GoRoute(path: route_home, builder: (_, __) => HomePage()),
        GoRoute(path: route_login, builder: (_, __) => LoginPage()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      ],
    );

    return MaterialApp.router(
      title: 'Ruggine Chat',
      routerConfig: router,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
