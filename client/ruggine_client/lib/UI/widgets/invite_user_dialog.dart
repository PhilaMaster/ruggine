import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruggine_client/UI/providers/chats_provider.dart';
import 'package:ruggine_client/UI/providers/invites_provider.dart';
import 'package:ruggine_client/UI/providers/message_service.dart';

class InviteUserDialog extends ConsumerStatefulWidget {
  const InviteUserDialog({super.key});

  @override
  ConsumerState<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends ConsumerState<InviteUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _groupNameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      final groupName = _groupNameController.text.trim();

      try {
        // chiama il metodo per inviare l'invito
        await ref.read(invitesProvider.notifier).sendInvite(username, groupName);

        MessageService.show('Invito inviato con successo a $username per il gruppo $groupName');
        Navigator.of(context).pop();
      } catch (e) {
        MessageService.show('Errore nell\'inviare l\'invito: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invita utente al gruppo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nome utente',
                  hintText: 'Inserisci il nome dell\'utente da invitare',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Il nome utente è obbligatorio';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome del gruppo',
                  hintText: 'Inserisci il nome del gruppo',
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Il nome del gruppo è obbligatorio';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _sendInvite,
          child: const Text('Invia invito'),
        ),
      ],
    );
  }
}
