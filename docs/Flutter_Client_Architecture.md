# Flutter Client - Architettura e Struttura

## Panoramica
Il client Flutter di Ruggine è un'applicazione di messaggistica cross-platform che implementa un'architettura pulita e modulare. L'app utilizza il pattern Provider con Riverpod per la gestione dello stato e segue i principi di Clean Architecture.

## Struttura del Progetto

### 📁 Organizzazione delle Directory

```
lib/
├── main.dart                    # Entry point dell'applicazione
├── config.dart                  # Configurazioni per URL API e WebSocket
├── core/                        # Funzionalità centrali
│   ├── const.dart               # Costanti per API paths e chiavi storage
│   ├── storage.dart             # Gestione storage locale e sicuro
│   └── dio_interceptor.dart     # Interceptor per logging HTTP
├── models/                      # Modelli di dati
│   ├── user.dart               # Modello utente
│   ├── chat.dart               # Modello chat/gruppo
│   ├── message.dart            # Modello messaggio
│   ├── invite.dart             # Modello invito gruppo
│   └── *.g.dart                # File generati da Hive
├── data/                       # Layer di accesso ai dati
│   ├── api_client.dart         # Client HTTP per comunicazione con backend
│   ├── auth_repo.dart          # Repository per autenticazione
│   ├── messages_repo.dart      # Repository per messaggi e chat
│   └── invites_repo.dart       # Repository per inviti gruppi
├── UI/                         # Interfaccia utente
│   ├── pages/                  # Pagine dell'applicazione
│   │   ├── login_page.dart
│   │   ├── home_page.dart
│   │   ├── chat_page.dart
│   │   └── settings.dart
│   ├── providers/              # Gestione stato con Riverpod
│   │   ├── auth_provider.dart
│   │   ├── chats_provider.dart
│   │   ├── messages_provider.dart
│   │   ├── invites_provider.dart
│   │   ├── websocket_provider.dart
│   │   ├── theme_provider.dart
│   │   └── message_service.dart
│   └── widgets/                # Widget riutilizzabili
│       └── ruggine_appbar.dart
└── exceptions/                 # Gestione eccezioni custom
```

## 🏗️ Architettura Applicazione

### Pattern Architetturale
- **Clean Architecture**: Separazione chiara tra UI, Business Logic e Data Layer
- **Provider Pattern**: Gestione stato reattivo con Riverpod
- **Repository Pattern**: Astrazione dell'accesso ai dati

### Dipendenze Principali
```yaml
dependencies:
  flutter_riverpod: ^2.6.1      # State management
  dio: ^5.4.0                   # HTTP client
  hive: ^2.2.3                  # Database locale
  go_router: ^16.0.0            # Navigazione
  web_socket_channel: ^3.0.3    # WebSocket
  flutter_secure_storage: ^9.0.0 # Storage sicuro
  window_manager: ^0.3.0        # Gestione finestre desktop
```

## 📄 Dettaglio File e Funzionalità

### 🚀 Entry Point

#### `main.dart`
- **Funzione**: Entry point dell'applicazione
- **Responsabilità**:
  - Inizializzazione Hive database locale
  - Configurazione window manager per desktop
  - Setup routing con GoRouter
  - Configurazione temi Material Design 3
  - Registrazione adapters Hive per modelli

### ⚙️ Configurazione

#### `config.dart`
- **Funzione**: Configurazioni ambiente-specifiche
- **Responsabilità**:
  - URL base API per diverse piattaforme (Android emulator, iOS, Desktop, Web)
  - URL WebSocket per comunicazione real-time
  - Gestione differenze di rete tra emulatori e dispositivi reali

#### `core/const.dart`
- **Funzione**: Costanti globali dell'applicazione
- **Responsabilità**:
  - Percorsi API endpoints
  - Chiavi per storage sicuro e locale
  - Route names per navigazione

#### `core/storage.dart`
- **Funzione**: Gestione storage locale e sicuro
- **Responsabilità**:
  - Storage JWT token in flutter_secure_storage
  - Gestione database Hive per chat, messaggi, inviti
  - Operazioni CRUD su storage locale

### 📊 Modelli di Dati

#### `models/user.dart`
```dart
class User {
  final String id;
  final String username;
  final String email;
}
```
- **Funzione**: Rappresenta un utente dell'applicazione
- **Annotazioni Hive**: Serializzazione locale
- **Metodi**: `fromJson()`, `toJson()` per API communication

#### `models/chat.dart`
```dart
class Chat {
  final String id;
  final String? name;           // Nome gruppo (null per chat private)
  final bool is_group;         // Flag gruppo/privata
  final List<String> members;  // Lista membri
  final String lastSender;
  final String? lastMessage;
  final DateTime lastTime;
  final int newMessages;      // Contatore messaggi non letti
}
```
- **Funzione**: Rappresenta una chat o gruppo
- **Caratteristiche**:
  - Supporto chat private e gruppi
  - Tracking ultimo messaggio e contatore non letti
  - Metadati creazione (creatore, data)

#### `models/message.dart`
```dart
class Message {
  final String id;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String chatId;
}
```
- **Funzione**: Rappresenta un singolo messaggio
- **Caratteristiche**:
  - Timestamping automatico
  - Associazione alla chat di appartenenza

#### `models/invite.dart`
```dart
class Invite {
  final String id;
  final String groupName;
  final String? senderName;
}
```
- **Funzione**: Rappresenta un invito a unirsi a un gruppo
- **Caratteristiche**: Informazioni minime per decisione utente

### 🌐 Data Layer

#### `data/api_client.dart`
- **Funzione**: Client HTTP principale per comunicazione con backend Rust
- **Responsabilità**:
  - Configurazione Dio con base URL e timeout
  - Gestione automatica autenticazione (JWT in header)
  - Interceptor per logging richieste in debug mode
  - Metodi per tutti gli endpoint API:
    - Autenticazione (login, register)
    - Chat operations (get, send messages)
    - Inviti (get, accept, decline)

#### `data/auth_repo.dart`
- **Funzione**: Repository per operazioni di autenticazione
- **Responsabilità**:
  - Login/logout utenti
  - Gestione token JWT
  - Validazione stato autenticazione
  - Storage sicuro credenziali

#### `data/messages_repo.dart` (ChatsRepo)
- **Funzione**: Repository per chat e messaggi
- **Responsabilità**:
  - Caricamento chat locali da Hive
  - Sincronizzazione con backend
  - Invio messaggi via API
  - Storage locale chat e messaggi
  - Gestione contatori messaggi non letti

#### `data/invites_repo.dart`
- **Funzione**: Repository per gestione inviti gruppi
- **Responsabilità**:
  - Recupero inviti pending da API
  - Accettazione/rifiuto inviti
  - Invio nuovi inviti (future implementation)

### 🎨 UI Layer

#### Pagine

##### `UI/pages/login_page.dart`
- **Funzione**: Pagina di autenticazione
- **Features**:
  - Form login con username/password
  - Gestione errori con snackbar
  - Navigazione automatica post-login

##### `UI/pages/home_page.dart`
- **Funzione**: Dashboard principale dell'applicazione
- **Features**:
  - Lista chat ordinate per timestamp
  - Badge contatori messaggi non letti
  - Gestione inviti con dialog modale
  - Responsive design (desktop/mobile)
  - Floating action button per mobile
  - Bottoni azioni mock per testing

##### `UI/pages/chat_page.dart`
- **Funzione**: Interfaccia chat singola
- **Features**:
  - Lista messaggi con scroll automatico
  - Bubble design differenziato per mittente
  - Input field con invio tramite bottone/Enter
  - Loading state durante inizializzazione
  - Auto-scroll a nuovi messaggi
  - Reset contatore messaggi non letti

##### `UI/pages/settings.dart`
- **Funzione**: Pagina impostazioni utente
- **Features**:
  - Toggle tema scuro/chiaro
  - Impostazioni notifiche
  - Informazioni app e utente
  - Logout

#### Provider (State Management)

##### `UI/providers/auth_provider.dart`
- **Funzione**: Gestione stato autenticazione globale
- **Stato**: `User?` (null = non autenticato)
- **Metodi**:
  - `login()`: Autenticazione utente
  - `logout()`: Logout e cleanup
  - `_checkLogin()`: Verifica stato al startup

##### `UI/providers/chats_provider.dart`
- **Funzione**: Gestione stato lista chat
- **Stato**: `List<Chat>?`
- **Metodi**:
  - `loadLocalChats()`: Carica chat da storage locale
  - `loadNewChats()`: Sincronizza con backend
  - `addChat()`: Aggiunge nuova chat
  - `newMessage()`: Aggiorna ultima attività chat
  - `resetUnreadCount()`: Reset contatore non letti
  - `sortChats()`: Ordinamento per timestamp

##### `UI/providers/messages_provider.dart`
- **Funzione**: Gestione messaggi chat corrente
- **Stato**: `List<Message>?`
- **Metodi**:
  - `loadLocalMessages()`: Carica messaggi da Hive
  - `sendMessage()`: Invia nuovo messaggio
  - `receiveMessage()`: Riceve messaggio da WebSocket
  - `updateMessages()`: Sostituisce lista messaggi

##### `UI/providers/invites_provider.dart`
- **Funzione**: Gestione inviti gruppi
- **Stato**: `List<Invite>?`
- **Metodi**:
  - `loadInvites()`: Carica inviti da API
  - `receiveInvite()`: Riceve nuovo invito
  - `acceptInvite()`: Accetta e crea chat
  - `declineInvite()`: Rifiuta invito
  - `sortInvites()`: Ordinamento alfabetico

##### `UI/providers/websocket_provider.dart`
- **Funzione**: Gestione connessione WebSocket real-time
- **Stato**: `WebSocketState` (status + error)
- **Responsabilità**:
  - Connessione automatica post-login
  - Riconnessione automatica su disconnect
  - Routing messaggi ai provider appropriati
  - Gestione messaggi e inviti in tempo reale

##### `UI/providers/theme_provider.dart`
- **Funzione**: Gestione tema applicazione
- **Stato**: `ThemeMode` (light/dark/system)
- **Persistenza**: SharedPreferences

##### `UI/providers/message_service.dart`
- **Funzione**: Servizio globale per notifiche UI
- **Responsabilità**: Gestione Snackbar per messaggi informativi

#### Widget

##### `UI/widgets/ruggine_appbar.dart`
- **Funzione**: AppBar standardizzata dell'applicazione
- **Features**:
  - Titolo dinamico
  - Bottoni settings e logout
  - Stile consistente

### 📡 Comunicazione Real-time

#### WebSocket Flow
1. **Connessione**: Automatica post-login con JWT
2. **Messaggi**: Formato JSON con tipo e payload
3. **Routing**: WebSocketProvider distribuisce ai provider appropriati
4. **Riconnessione**: Automatica su disconnessione

#### Tipi Messaggi WebSocket
```dart
{
  "type": "new_message",
  "payload": {
    "id": "msg_id",
    "senderName": "username",
    "content": "text",
    "timestamp": "ISO_date",
    "chatId": "chat_id"
  }
}

{
  "type": "new_invite",
  "payload": {
    "id": "invite_id",
    "groupName": "Group Name",
    "senderName": "inviter"
  }
}
```

### 💾 Storage Strategy

#### Locale (Hive)
- **Chat**: Lista completa per accesso offline
- **Messaggi**: Per chat corrente
- **Inviti**: Cache temporanea

#### Sicuro (flutter_secure_storage)
- **JWT Token**: Per autenticazione persistente

#### Condiviso (SharedPreferences)
- **Preferenze UI**: Tema, notifiche

### 🔄 Navigazione

#### Route Structure
```dart
GoRouter(
  routes: [
    '/login'           -> LoginPage
    '/'                -> HomePage  
    '/settings'        -> SettingsPage
    '/chat/:chatId'    -> ChatPage
  ]
)
```

#### Protezione Route
- **Redirect automatico**: `/login` se non autenticato
- **Estado persistence**: Mantenimento navigazione post-login

### 🎯 Pattern di Design Utilizzati

1. **Repository Pattern**: Astrazione data sources
2. **Provider Pattern**: State management reattivo  
3. **Observer Pattern**: Reactive UI updates
4. **Singleton Pattern**: API client instances
5. **Factory Pattern**: Model creation da JSON

### 🔧 Gestione Errori

- **API Errors**: Catch e display via MessageService
- **Storage Errors**: Fallback e logging
- **WebSocket Errors**: Riconnessione automatica
- **UI Errors**: Graceful degradation

---

## 🚀 Implementazione Inviti Gruppi - Roadmap

### Stato Attuale
L'implementazione degli inviti è **parzialmente completata**:

✅ **Completato Backend:**
- Database table `group_invitation` 
- Modelli Rust (`GroupInvitation`, `GroupInvitationRequest`)
- Service layer per inviti (`group_invitation.rs`)
- Endpoint API completi:
  - `GET /groupInvites` - Ottieni inviti dell'utente
  - `POST /groupInvites` - Crea nuovo invito  
  - `DELETE /groupInvites` - Cancella invito
  - `POST /groupInvites/accept` - Accetta invito

✅ **Completato Frontend:**
- Modello `Invite` con serializzazione Hive
- `InvitesRepo` con metodi API (ma con mock)
- `InvitesProvider` per state management
- UI per visualizzazione e gestione inviti
- Ricezione inviti via WebSocket

❌ **Da Implementare:**
- **Rimuovere mock da ApiClient**
- **Integrare endpoint reali backend**
- **Gestire errori API reali** 
- **Testing integrazione completa**

---

### 🔧 Passi per Rimuovere i Mock e Implementare API Reali

#### Fase 1: Aggiornamento ApiClient (1-2 ore)

##### 1.1 Aggiornare endpoint negli constants
```dart
// lib/core/const.dart - Aggiungere nuovi endpoint
const String apipath_invites = "groupInvites";
const String apipath_accept_invite = "groupInvites/accept";
const String apipath_send_invite = "groupInvites";
```

##### 1.2 Sostituire metodi mock in ApiClient
```dart
// lib/data/api_client.dart - Sostituire metodi esistenti

// PRIMA (Mock):
Future<Response> getInvites(String uid) {
  return Future<Response<dynamic>>.value(
    Response(/* mock data */)
  );
}

// DOPO (API Reale):
Future<Response> getInvites(String uid) async {
  try {
    final response = await dio.get(apipath_invites);
    return response;
  } catch (e) {
    if (kDebugMode) {
      print('Error getting invites: $e');
    }
    rethrow;
  }
}

Future<Response> acceptInvite(String groupId) async {
  try {
    final response = await dio.post(
      apipath_accept_invite,
      queryParameters: {'group_id': int.parse(groupId)},
    );
    return response;
  } catch (e) {
    if (kDebugMode) {
      print('Error accepting invite: $e');
    }
    rethrow;
  }
}

Future<Response> declineInvite(String groupId) async {
  try {
    final response = await dio.delete(
      apipath_invites,
      queryParameters: {'group_id': int.parse(groupId)},
    );
    return response;
  } catch (e) {
    if (kDebugMode) {
      print('Error declining invite: $e');
    }
    rethrow;
  }
}

Future<Response> sendInvite(String groupId, String receiverUsername) async {
  try {
    final response = await dio.post(
      apipath_send_invite,
      data: {
        'chat_id': int.parse(groupId),
        'receiver_id': int.parse(receiverUsername), // Assumendo ID utente
      },
    );
    return response;
  } catch (e) {
    if (kDebugMode) {
      print('Error sending invite: $e');
    }
    rethrow;
  }
}
```

#### Fase 2: Aggiornamento Model Invite (30 minuti)

##### 2.1 Adattare modello alle API reali
```dart
// lib/models/invite.dart - Aggiornare per matching con backend

@HiveType(typeId: 2)
class Invite {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String groupName;

  @HiveField(2)
  final String? senderName;

  // Nuovi campi dal backend
  @HiveField(3)
  final int groupId;

  @HiveField(4)
  final int senderId;

  @HiveField(5)
  final int receiverId;

  Invite({
    required this.id,
    required this.groupName,
    this.senderName,
    required this.groupId,
    required this.senderId,
    required this.receiverId,
  });

  // Aggiornare factory constructor per backend response
  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      id: json['id'].toString(),
      groupId: json['group_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      groupName: json['group_name'] ?? 'Gruppo Sconosciuto',
      senderName: json['sender_username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'group_name': groupName,
      'sender_username': senderName,
    };
  }
}
```

#### Fase 3: Aggiornamento InvitesRepo (1 ora)

##### 3.1 Gestire response reali e errori
```dart
// lib/data/invites_repo.dart - Implementazione robusta

class InvitesRepo {
  final ApiClient _apiClient;

  InvitesRepo(this._apiClient);

  Future<List<Invite>> getInvites(String uid) async {
    try {
      final response = await _apiClient.getInvites(uid);
      
      if (response.statusCode == 200) {
        final List<dynamic> invitesJson = response.data;
        return invitesJson.map((json) => Invite.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load invites: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error getting invites: $e");
      }
      throw Exception('Error getting invites: $e');
    }
  }

  Future<Chat> acceptInvite(String groupId) async {
    try {
      final response = await _apiClient.acceptInvite(groupId);
      
      if (response.statusCode == 204) {
        // API ritorna 204 No Content per successo
        // Dobbiamo ottenere info gruppo separatamente
        final chatInfoResponse = await _apiClient.getChatInfo(groupId);
        return Chat.fromJson(chatInfoResponse.data);
      } else {
        throw Exception('Failed to accept invite: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error accepting invite: $e");
      }
      throw Exception('Error accepting invite: $e');
    }
  }

  Future<void> declineInvite(String groupId) async {
    try {
      final response = await _apiClient.declineInvite(groupId);
      
      if (response.statusCode == 204) {
        if (kDebugMode) {
          print("Invite declined successfully");
        }
      } else {
        throw Exception('Failed to decline invite: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error declining invite: $e");
      }
      throw Exception('Error declining invite: $e');
    }
  }

  Future<void> sendInvite(String groupId, String receiverUsername) async {
    try {
      final response = await _apiClient.sendInvite(groupId, receiverUsername);
      
      if (response.statusCode == 201) {
        if (kDebugMode) {
          print("Invite sent successfully");
        }
      } else {
        throw Exception('Failed to send invite: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error sending invite: $e");
      }
      throw Exception('Error sending invite: $e');
    }
  }
}
```

#### Fase 4: Aggiornamento InvitesProvider (30 minuti)

##### 4.1 Gestire stati di loading e errori
```dart
// lib/UI/providers/invites_provider.dart - Migliorare error handling

class InvitesNotifier extends StateNotifier<List<Invite>?> {
  final InvitesRepo _repo;
  final ChatsNotifier _chatsNotifier;
  bool _isLoading = false;

  InvitesNotifier(this._repo, this._chatsNotifier) : super(null);

  bool get isLoading => _isLoading;

  Future<void> loadInvites(String uid) async {
    try {
      _isLoading = true;
      final invites = await _repo.getInvites(uid);
      state = sortInvites(invites);
    } catch (e) {
      if (kDebugMode) {
        print("Error loading invites: $e");
      }
      // Mantieni stato precedente in caso di errore
    } finally {
      _isLoading = false;
    }
  }

  Future<void> acceptInvite(String groupId) async {
    try {
      final chat = await _repo.acceptInvite(groupId);
      
      // Rimuovi invito dalla lista
      state = state?.where((invite) => invite.groupId.toString() != groupId).toList();
      
      // Aggiungi chat alla lista chat
      _chatsNotifier.addChat(chat);
      
      if (kDebugMode) {
        print("Invite accepted and chat added");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error accepting invite: $e");
      }
      rethrow; // Propaga errore per gestione UI
    }
  }

  Future<void> declineInvite(String groupId) async {
    try {
      await _repo.declineInvite(groupId);
      
      // Rimuovi invito dalla lista
      state = state?.where((invite) => invite.groupId.toString() != groupId).toList();
      
      if (kDebugMode) {
        print("Invite declined");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error declining invite: $e");
      }
      rethrow; // Propaga errore per gestione UI
    }
  }
}
```

#### Fase 5: Aggiungere getChatInfo in ApiClient (30 minuti)

```dart
// lib/data/api_client.dart - Aggiungere metodo mancante

Future<Response> getChatInfo(String chatId) async {
  try {
    final response = await dio.get(
      'chatInfo',
      queryParameters: {'chat_id': chatId},
    );
    return response;
  } catch (e) {
    if (kDebugMode) {
      print('Error getting chat info: $e');
    }
    rethrow;
  }
}
```

#### Fase 6: Aggiornamento UI per Gestione Errori (1 ora)

##### 6.1 Migliorare HomePage per gestire errori
```dart
// lib/UI/pages/home_page.dart - Aggiungere error handling nel dialog inviti

Widget _buildInvitesDialog(List<Invite> invites) {
  return AlertDialog(
    title: const Text('Inviti ai Gruppi'),
    content: SizedBox(
      width: 300,
      height: 400,
      child: ListView.builder(
        itemCount: invites.length,
        itemBuilder: (context, index) {
          final invite = invites[index];
          return Card(
            child: ListTile(
              title: Text(invite.groupName),
              subtitle: Text('Da: ${invite.senderName ?? 'Sconosciuto'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      try {
                        await ref.read(invitesProvider.notifier)
                            .acceptInvite(invite.groupId.toString());
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invito accettato!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Errore: ${e.toString()}')),
                          );
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      try {
                        await ref.read(invitesProvider.notifier)
                            .declineInvite(invite.groupId.toString());
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invito rifiutato')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Errore: ${e.toString()}')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Chiudi'),
      ),
    ],
  );
}
```

#### Fase 7: Testing e Debugging (2-3 ore)

##### 7.1 Test checklist
- [ ] Caricamento inviti all'avvio app
- [ ] Accettazione invito aggiunge chat correttamente  
- [ ] Rifiuto invito rimuove dalla lista
- [ ] Gestione errori di rete
- [ ] WebSocket per nuovi inviti funziona
- [ ] Sincronizzazione storage locale

##### 7.2 Debug comuni
```dart
// Aggiungere logging dettagliato per debug
if (kDebugMode) {
  print('API Response Status: ${response.statusCode}');
  print('API Response Data: ${response.data}');
  print('Current invites state: ${state?.length ?? 0} items');
}
```

---

### 🚨 Note Importanti

#### Mapping Dati Backend ↔ Frontend
- **Backend**: Usa ID numerici (`group_id`, `sender_id`, `receiver_id`)
- **Frontend**: Modello `Invite` deve gestire conversioni String ↔ int
- **Chat Info**: Serve chiamata separata `/chatInfo` dopo accettazione

#### Gestione Errori HTTP
```dart
// Codici stato da gestire:
// 200 - OK (GET invites)
// 201 - Created (POST send invite)  
// 204 - No Content (POST accept, DELETE decline)
// 400 - Bad Request (validazione failed)
// 401 - Unauthorized (token invalido)
// 403 - Forbidden (permessi insufficienti)
// 404 - Not Found (invito non esiste)
// 500 - Internal Server Error
```

#### Sicurezza
- **JWT Token**: Automaticamente incluso negli header da Dio interceptor
- **Validazione server-side**: Backend valida tutti i permessi
- **Rate limiting**: Considerare nella gestione errori

#### Performance
- **Cache locale**: Hive per persistenza inviti offline
- **Loading states**: UI reattiva durante operazioni API
- **Error recovery**: Retry automatico per errori temporanei

---

---

---

### ⚡ Quick Start Development

#### Setup Ambiente
```bash
# Flutter setup
flutter pub get
flutter pub run build_runner build

# Run app
flutter run -d windows
```

#### Testing Flow Completo Post-Implementazione
```bash
# 1. Avvia backend Rust
cd backend
cargo run

# 2. Avvia client Flutter
cd client/ruggine_client
flutter run

# 3. Test sequence:
# - Login con utente esistente
# - Verifica caricamento inviti reali
# - Testa accettazione/rifiuto inviti
# - Controlla sincronizzazione WebSocket
# - Verifica persistenza locale
```

#### Mock vs Real API - Checklist di Verifica
```dart
// Prima dell'implementazione (Mock):
✅ UI funziona con dati fake
✅ Stati loading simulati
✅ Error handling basilare

// Dopo implementazione (Real API):
✅ Endpoint backend rispondono correttamente
✅ Parsing JSON da backend funziona
✅ Error handling HTTP completo
✅ Sincronizzazione storage locale
✅ WebSocket per real-time updates
✅ Performance accettabile
```

Questa architettura garantisce una base solida per un'applicazione di messaggistica scalabile e maintainer, con chiara separazione delle responsabilità e pattern consolidati. L'implementazione degli inviti con API reali richiede principalmente la rimozione dei mock e l'integrazione degli endpoint già disponibili nel backend.
