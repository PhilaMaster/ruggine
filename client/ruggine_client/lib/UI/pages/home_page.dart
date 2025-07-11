import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruggine_client/UI/pages/settings.dart';
import '../providers/auth_provider.dart';



class _HomePageState {
  int? number;

  _HomePageState();

  void generateNumber() {
    number = 42; // Simple logic to generate a number
  }
}

final stateProvider = StateProvider<_HomePageState>((ref) => _HomePageState());


class HomePage extends ConsumerWidget {
  const HomePage({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider.notifier);
    final state = ref.watch(stateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Test page logged in"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              auth.logout();
            },
          )
        ],
      ),
      body: Center(
        child: Text(
          state.number?.toString() ?? 'Press the button!',
          style: TextStyle(fontSize: 32),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.generateNumber,
        tooltip: 'Generate Number',
        child: Icon(Icons.refresh),
      ),
          );
  }
}
