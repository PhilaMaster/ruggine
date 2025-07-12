import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

PreferredSizeWidget buildRuggineAppBar(BuildContext context, WidgetRef ref) {
  final auth = ref.watch(authProvider.notifier);
  return AppBar(
    title: const Text("Home"),
    actions: [
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          context.push('/settings');
        },
      ),
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () {
          auth.logout();
        },
      ),
    ],
  );
}