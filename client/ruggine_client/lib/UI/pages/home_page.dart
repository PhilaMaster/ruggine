import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruggine_client/UI/widgets/ruggine_appbar.dart';
import '../../models/chat.dart';
import '../../models/invite.dart';
import '../providers/auth_provider.dart';
import '../providers/chats_provider.dart';



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
    final chats = ref.watch(chatProvider);
    // final num = ref.watch(stateProvider.select((state) => state.number));

    // MOCK DATI
    final mockInvites = [
      MockInvite(groupName: "Gruppo Rust"),
      MockInvite(groupName: "Flutter Devs"),
    ];

    // Responsive: larghezza massima su desktop/tablet
    final isWide = MediaQuery.of(context).size.width > 600;
    final maxWidth = isWide ? 500.0 : double.infinity;

    return Scaffold(
      appBar: buildRuggineAppBar(context, ref), //ruggine appbar
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Pulsante per creare gruppo
                SizedBox(
                  width: double.infinity,
                  child: isWide?
                  ElevatedButton.icon(
                    icon: Icon(Icons.group_add),
                    label: Text("Crea gruppo"),
                    onPressed: () => handleCreateGroup(context, ref),
                  ):null,
                ),
                SizedBox(height: 12),
                // Pulsante inviti con badge numerico
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Stack(
                      children: [
                        Icon(Icons.mail),
                        if (mockInvites.isNotEmpty)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                '${mockInvites.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: Text("Inviti"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mockInvites.isNotEmpty ? Colors.red.shade100 : null,
                      foregroundColor: mockInvites.isNotEmpty ? Colors.red.shade900 : null,
                    ),
                    onPressed: () {
                      // Mock: mostra pagina inviti
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                              title: Text("Inviti"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: mockInvites
                                    .map((invite) => ListTile(
                                      leading: Icon(Icons.group),
                                      title: Text(invite.groupName),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ElevatedButton(
                                            child: Text("Accetta"),
                                            onPressed: () {
                                              Navigator.of(ctx).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text("Invito accettato per ${invite.groupName} (ovviamente non è vero)")),
                                              );
                                            },
                                          ),
                                          SizedBox(width: 8),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey.shade300,
                                              foregroundColor: Colors.black,
                                            ),
                                            child: Text("Rifiuta"),
                                            onPressed: () {
                                              Navigator.of(ctx).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text("Invito rifiutato per ${invite.groupName} (ovviamente non è vero)")),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ))
                                    .toList(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text("Chiudi"),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 24),
                // Lista chat
                Expanded(
                    child: chats == null
                        ? const Center(child: CircularProgressIndicator())
                        : chats.isEmpty
                        ? const Center(child: Text("Nessuna chat disponibile"))
                        : ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats.elementAt(index);
                        String formattedTime = TimeOfDay.fromDateTime(chat.lastTime).format(context);
                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: Card(
                              child: ListTile(
                                title: Text("Chat #${chat.id}"),
                                subtitle: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${chat.lastSender}: ${chat.lastMessage}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      formattedTime,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    IconButton(onPressed: () =>
                                        ref.read(chatProvider.notifier).removeChat(chat.id),
                                        icon: Icon(Icons.delete, color: Colors.red)),
                                  ],
                                ),
                                isThreeLine: false,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                          title: Text("Chat #${chat.id}"),
                                          content: Text(
                                              "Ultimo messaggio da ${chat.lastSender} alle $formattedTime:\n${chat.lastMessage}\n\nQuesto dovrebbe aprire la relativa chat e caricare i messaggi"
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              child: Text("Chiudi"),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    )
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: isWide
          ? null
          : FloatingActionButton(
        onPressed: () => handleCreateGroup(context, ref),
        tooltip: 'Crea gruppo',
        child: Icon(Icons.group_add),
      ),
    );
  }

  void handleCreateGroup(BuildContext context, WidgetRef ref) {
    final chatz = ref.read(chatProvider.notifier);
    chatz.addChat(
      Chat(
        id: (chatz.length + 1).toString(),
        lastSender: "Zio Pera",
        lastMessage: "Ciao, questo è un messaggio di prova!",
        lastTime: DateTime.now(),
      ),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
            title: Text("Crea gruppo"),
            content: Text("Zio pera!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text("OK"),
              ),
            ],
          ),
    );
  }
}
