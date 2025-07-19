import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:ruggine_client/UI/providers/invites_provider.dart';
import 'package:ruggine_client/UI/widgets/ruggine_appbar.dart';
import 'package:ruggine_client/UI/widgets/create_chat_dialog.dart';
import '../../models/chat.dart';
import '../../models/invite.dart';
import '../../models/message.dart';
import '../providers/auth_provider.dart';
import '../providers/chats_provider.dart';
import '../providers/messages_provider.dart';
import '../widgets/invite_user_dialog.dart';



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
                    icon: Icon(Icons.group_add),
                    label: Text("Invita utente in un gruppo"),
                    onPressed: () => handleCreateInvite(context, ref),
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
                      backgroundColor: (invites != null && invites.isNotEmpty)
                          ? Colors.red.shade100
                          : Colors.grey.shade200,
                      foregroundColor: (invites != null && invites.isNotEmpty)
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
                                  content: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: 500, // Reasonable max width
                                      maxHeight: 400, // Set a maximum height
                                    ),
                                    child: SingleChildScrollView(
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
                                                        SizedBox(width: 154),
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
                              child: Stack(
                                children: [
                                  // Main ListTile content
                                  ListTile(
                                    contentPadding: EdgeInsets.fromLTRB(16, 8, 60, 8), // Extra right padding for counter
                                    // se la chat è di gruppo, mostra il nome del gruppo, altrimenti il nome del destinatario
                                    title: Text(
                                      chat.is_group
                                          ? chat.name.toString()
                                          : "Chat con ${
                                            !chat.members.isEmpty
                                                ? (chat.members[0] == (ref.read(authProvider)?.username ?? "")
                                                  ? chat.members[1]
                                                  : chat.members[0])
                                                : "Unknown"

                                      }",
                                    ),
                                    subtitle: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: 20, // Minimum height for subtitle
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              chat.lastMessage == null
                                                  ? "No messages yet"
                                                  :
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
                                              fontSize: 12,
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
                                  // Delete button in top-right corner
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () =>
                                            ref.read(chatProvider.notifier).removeChat(chat.id),
                                        icon: Icon(Icons.close, color: Colors.red, size: 14),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(
                                          minWidth: 24,
                                          minHeight: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // New message counter in center-right
                                  if (chat.newMessages > 0)
                                    Positioned(
                                      right: 8,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          constraints: BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 20,
                                          ),
                                          child: Text(
                                            chat.newMessages > 99 ? '99+' : chat.newMessages.toString(),
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
    showDialog(
      context: context,
      builder: (context) => const CreateChatDialog(),
    );
  }

  void handleCreateInvite(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const InviteUserDialog(),
    );
  }

  Future<void> handleNewMessage(BuildContext context, WidgetRef ref) async {
    // final messagesNotifier = ref.read(msgProvider.notifier);
    // messagesNotifier.updateMessages('1', [
    //   Message(
    //       id: '10',
    //       senderName: 'Zio Pera',
    //       content: 'Ciao, questo è un messaggio di prova!',
    //       timestamp: DateTime.now(),
    //       chatId: '1'
    //   ),
    // ]);
  }
}
