import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';



class _HomePageState {
  int number = 42;

  _HomePageState(){
    number = 42;
  }
  _HomePageState copyWith({
    int? number,
  }) {
    return _HomePageState()
      ..number = number ?? this.number;
  }
}

class HomePageStateNotifier extends StateNotifier<_HomePageState> {
  HomePageStateNotifier() : super(_HomePageState());

  void generateNumber() {
    state = state.copyWith(
      number: state.number + 1,
    );
  }
}

final stateProvider = StateNotifierProvider<HomePageStateNotifier, _HomePageState>((ref) {
  return HomePageStateNotifier();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider.notifier);
    final num = ref.watch(stateProvider.select((state) => state.number));

    return Scaffold(
      appBar: AppBar(
        title: Text("Test page logged in"),
        actions: [
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
          'Number: ${num}',
          style: TextStyle(fontSize: 32)
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(stateProvider.notifier).generateNumber(),
        tooltip: 'Generate Number',
        child: Icon(Icons.refresh),
      ),
          );
  }
}
