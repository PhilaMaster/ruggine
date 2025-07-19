import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruggine_client/UI/providers/auth_provider.dart';
import 'package:ruggine_client/UI/providers/chats_provider.dart';
import 'package:ruggine_client/UI/providers/message_service.dart';
import 'package:ruggine_client/models/chat.dart';

class CreateChatDialog extends ConsumerStatefulWidget {
  const CreateChatDialog({super.key});

  @override
  ConsumerState<CreateChatDialog> createState() => _CreateChatDialogState();
}

class _CreateChatDialogState extends ConsumerState<CreateChatDialog> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _participantController = TextEditingController();
  final List<String> _participants = [];
  bool _isGroup = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _usernameController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  void _addParticipant() {
    final username = _participantController.text.trim();
    if (username.isNotEmpty && !_participants.contains(username)) {
      setState(() {
        _participants.add(username);
        _participantController.clear();
      });
    }
  }

  void _removeParticipant(String username) {
    setState(() {
      _participants.remove(username);
    });
  }

  Future<void> _createChat() async {
    if (_formKey.currentState!.validate()) {
      final curUser = ref
          .read(authProvider);

      final newChat = Chat(
        id: '-1',
        // Placeholder ID, will be set by the server
        lastSender: "",
        lastMessage: "",
        lastTime: DateTime.now(),
        newMessages: 0,
        name: _isGroup ? _groupNameController.text.trim() : null,
        created_by: curUser!.username,
        members: _isGroup
            ? [curUser.username, ..._participants]
            : [curUser.username, _usernameController.text.trim()],
        is_group: _isGroup ,
        created_at: DateTime.now(),
      );
      await ref.read(chatProvider.notifier).newChat(newChat).then(
              (okInvites) {
            //show what invites were sent
            if (okInvites.isNotEmpty) {
              MessageService.show(
                'Chat creata e inviti inviati con successo: ${okInvites.join(', ')}',
              );
            }else{
              MessageService.show(
                'Chat creata con successo senza inviti, invita partecipanti in seguito.',
              );
            }
          }
      );
      Navigator.of(context).pop();
      // Show success message
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crea nuova chat'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle per scegliere tra chat singola e gruppo
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Chat singola'),
                      value: false,
                      groupValue: _isGroup,
                      onChanged: (value) {
                        setState(() {
                          _isGroup = value!;
                          // Reset dei campi quando si cambia tipo
                          _groupNameController.clear();
                          _usernameController.clear();
                          _participantController.clear();
                          _participants.clear();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Gruppo'),
                      value: true,
                      groupValue: _isGroup,
                      onChanged: (value) {
                        setState(() {
                          _isGroup = value!;
                          // Reset dei campi quando si cambia tipo
                          _groupNameController.clear();
                          _usernameController.clear();
                          _participantController.clear();
                          _participants.clear();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Campi condizionali in base al tipo di chat
              if (_isGroup) ...[
                // Campo nome gruppo
                TextFormField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome del gruppo',
                    hintText: 'Inserisci il nome del gruppo',
                    prefixIcon: Icon(Icons.group),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Il nome del gruppo è obbligatorio';
                    }
                    if (value.trim().length < 3) {
                      return 'Il nome deve essere di almeno 3 caratteri';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo per aggiungere partecipanti
                const Text(
                  'Partecipanti:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _participantController,
                        decoration: const InputDecoration(
                          labelText: 'Username partecipante',
                          hintText: 'Inserisci username',
                          prefixIcon: Icon(Icons.person_add),
                          border: OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (_) => _addParticipant(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addParticipant,
                      child: const Text('Aggiungi'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lista partecipanti aggiunti
                if (_participants.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partecipanti aggiunti (${_participants.length}):',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _participants.map((username) {
                            return Chip(
                              label: Text(username),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => _removeParticipant(username),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ] else ...[
                  // Campo per chat singola
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username destinatario',
                      hintText: 'Inserisci username dell\'utente',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'username è obbligatorio';
                      }
                      if (value.trim().length < 3) {
                        return 'L\'username deve essere di almeno 3 caratteri';
                      }
                      return null;
                    },
                  ),
                ],

              const SizedBox(height: 16),

              // Descrizione informativa
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isGroup
                            ? 'Verrà creato un nuovo gruppo con i partecipanti selezionati. Potrai aggiungere o rimuovere membri in seguito.'
                            : 'Verrà creata una chat privata con l\'utente specificato.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
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
          onPressed: _createChat,
          child: Text(_isGroup ? 'Crea gruppo' : 'Crea chat'),
        ),
      ],
    );
  }
}
