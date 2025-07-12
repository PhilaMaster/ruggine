import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruggine_client/UI/providers/invites_provider.dart';
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
    final invites = ref.watch(invitesProvider);
    // final num = ref.watch(stateProvider.select((state) => state.number));

    // Responsive: larghezza massima su desktop/tablet
    final isWide = MediaQuery.of(context).size.width > 600;
    final maxWidth = isWide ? 500.0 : double.infinity;

    return Scaffold(
      appBar: buildRuggineAppBar(context, ref, "Home"), //ruggine appbar
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
                SizedBox(
                  width: double.infinity,
                  child: isWide?
                  ElevatedButton.icon(
                    icon: Icon(Icons.send_sharp),
                    label: Text("Ricevi falso invito da Zio Pera"),
                    onPressed: () => ref.read(invitesProvider.notifier).receiveInvite(
                          Invite(
                            groupName: "Gruppo di Zio Pera",
                            id: "fake-invite-id",
                            senderName: 'Zio Pera',
                          ),
                        ),
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
                        if (invites != null && invites.isNotEmpty)
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
                                '${invites.length}',
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
                      backgroundColor: (invites != null && invites!.isNotEmpty)
                          ? Colors.red.shade100
                          : Colors.grey.shade200,
                      foregroundColor: (invites != null && invites!.isNotEmpty)
                          ? Colors.red.shade900
                          : Colors.grey.shade600,
                    ),
                    onPressed: () {
                      // Mock: mostra pagina inviti
                      showDialog(
                        context: context,
                        builder: (ctx) => Consumer(
                              builder: (context, ref, child) {
                                final dialogInvites = ref.watch(invitesProvider);
                                return AlertDialog(
                                  title: Text("Inviti"),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: dialogInvites != null && dialogInvites.isNotEmpty
                                          ? dialogInvites
                                          .map((invite) => Card(
                                            margin: EdgeInsets.symmetric(vertical: 4.0),
                                            child: Padding(
                                              padding: EdgeInsets.all(12.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.group, size: 20),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          invite.groupName,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w500,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 12),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.green,
                                                          foregroundColor: Colors.white,
                                                          padding: EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8
                                                          ),
                                                        ),
                                                        child: Text("Accetta"),
                                                        onPressed: () {
                                                          ref.read(invitesProvider.notifier).acceptInvite(invite.id);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text("Invito accettato per ${invite.groupName}")),
                                                          );
                                                        },
                                                      ),
                                                      SizedBox(width: 8),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.grey.shade300,
                                                          foregroundColor: Colors.black,
                                                          padding: EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8
                                                          ),
                                                        ),
                                                        child: Text("Rifiuta"),
                                                        onPressed: () {
                                                          ref.read(invitesProvider.notifier).declineInvite(invite.id);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text("Invito rifiutato per ${invite.groupName}")),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ))
                                          .toList()
                                          : [
                                        Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Text(
                                            "Nessun invito disponibile",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 16,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: Text("Chiudi"),
                                    ),
                                  ],
                                );
                              },
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
                            constraints: BoxConstraints(
                              maxWidth: maxWidth,
                              minHeight: 72, // Minimum acceptable height
                            ),
                            child: Card(
                              child: ListTile(
                                title: Text("Chat #${chat.id}"),
                                subtitle: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: 20, // Minimum height for subtitle
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3, // Give more space to message text
                                        child: Text(
                                          "${chat.lastSender}: ${chat.lastMessage}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 4), // Reduced spacing
                                      Container(
                                        constraints: BoxConstraints(
                                          minWidth: 45, // Minimum width for time
                                          maxWidth: 60, // Maximum width for time
                                        ),
                                        child: Text(
                                          formattedTime,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12, // Slightly smaller font
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                      SizedBox(width: 2), // Minimal spacing
                                      Container(
                                        constraints: BoxConstraints(
                                          minWidth: 40, // Fixed width for icon button
                                          maxWidth: 40,
                                        ),
                                        child: IconButton(
                                          onPressed: () =>
                                              ref.read(chatProvider.notifier).removeChat(chat.id),
                                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                          padding: EdgeInsets.all(4), // Reduced padding
                                          constraints: BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                isThreeLine: false,
                                onTap: () {
                                  context.push('/chat/${chat.id}', extra: chat);
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
