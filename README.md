# Manuale utente
## Descrizione del progetto
Ruggine è un'applicazione di chat multipiattaforma composta da un backend in Rust e un client Flutter. L'applicazione supporta messaggi privati, chat di gruppo e inviti.
## Requisiti di sistema
- Backend: Rust (versione 1.70+), Diesel CLI
- Client: Flutter SDK (versione 3.0+), Dart SDK
- Database: SQLite
- Sistema operativo: Windows, macOS, Linux, Android, iOS (testato solo su Windows e *...*)

## Installazione

### Backend
1. Naviga nella cartella del progetto:
   ```bash
   cd backend
    ```
2. Installa le dipendenze:
    ```bash
   cargo build
   ```
3. Avvia il server:
    ```bash
   cargo run
   ```

### Client

1. Naviga nella cartella del client:
   ```bash
   cd client/ruggine_client
   ```
2. Installa le dipendenze:
   ```bash
    flutter pub get
    ```
3. Avvia l'applicazione:
   ```bash
   flutter run
   ```

## Utilizzo dell'applicazione
è possibile utilizzare le seguenti funzionalità:
### Registrazione e login
- Registrare un nuovo account o effettuare il login
- L'autenticazione viene gestita tramite token JWT
### Messaggi privati
- Creare una chat con un utente tramite il suo username
- Digitare il messaggio e premere invio
- I messaggi vengono sincronizzati in tempo reale
### Chat di gruppo
- Creare un nuovo gruppo o unirsi a uno esistente
- Inviare messaggi al gruppo
- Gestire i membri del gruppo
### Inviti di gruppo
- Inviare inviti ad altri utenti
- Accettare o rifiutare gli inviti ricevuti

## API Reference
Per sviluppatori: consultare il file ```API_GUIDE.md``` e la collection Postman ```Ruggine Chat API.postman_collection.json``` per testare le API.

# Manuale del progettista
## Architettura generale del sistema
Il progetto ruggine implementa un sistema di chat multipiattaforma basato su un'architettura client-server. Il backend è sviluppato in Rust per garantire performance elevate e sicurezza della memoria, mentre il client utilizza Flutter per la portabilità multipiattaforma.
## Backend - Architettura del server
### Struttura modulare
Il server è organizzato in moduli specializzati:


- Handler: Gestisce le richieste HTTP e WebSocket
- Models: Definisce le strutture dati del dominio
- Middleware: Implementa autenticazione e validazione
- Utility: Funzioni di supporto per logging e configurazione

### Gestione della concorrenza
Il server utilizza il framework Actix Web che implementa un modello di concorrenza basato su:


- Actor system: Ogni connessione è gestita da un attore indipendente
- Async/await: Programmazione asincrona per I/O non bloccanti
- Thread pool: Pool di thread per elaborazioni CPU-intensive

### Strutture dati principali
- User: Gestione utenti con autenticazione JWT
- Message: Messaggi punto-punto con timestamp, valido sia per chat private che di gruppo
- Chat: Identifica una chat (sia private che di gruppo) e ne mantiene le informazioni principali
- GroupInvite: Sistema di inviti con stati (pending, accepted, rejected)

### Persistenza dati
Utilizza SQLite con Diesel ORM per:
- Migrazione automatica dello schema
- Query type-safe compilate
- Connection pooling per ottimizzare le performance

## Client - Architettura Flutter
### Organizzazione del codice
- Core: Logica di business e servizi
- Data: Layer di accesso ai dati e API
- Models: Rappresentazione dei dati lato client
- UI: Interface utente reattiva
- Exceptions: Gestione centralizzata degli errori

### Gestione dello stato
Implementa pattern BLoC (Business Logic Component) per:
- Separazione tra logica di business e UI
- Gestione reattiva degli eventi
- Testing semplificato dei componenti

### Comunicazione client-server
Protocolli utilizzati
- HTTP/HTTPS: API REST per operazioni CRUD
- WebSocket: Comunicazione bidirezionale real-time, per notifica i client in seguito a ricezione di messaggi e inviti
- JSON: Formato di scambio dati standardizzato
### Autenticazione e sicurezza
- JWT tokens: Autenticazione stateless con refresh token
- CORS: Controllo accessi cross-origin configurabile
- Input validation: Sanitizzazione dati in ingresso sia client che server

### Scalabilità e performance
#### Ottimizzazioni server
- Connection pooling: Riutilizzo connessioni database
- Lazy loading: Caricamento dati su richiesta
- Batch operations: Elaborazione in lotti per efficiency
#### Ottimizzazioni client
- Pagination: Caricamento incrementale messaggi
- Caching: Memorizzazione locale messaggi e chat
- Background sync: Sincronizzazione in background

### Safety
#### Backend Safety (Rust)
Utilizzando Rust come linguaggio di programmazione per il nostro server abbiamo come garanzie:
- Memory safety garantita: previene buffer overflow, memory leaks e data races a compile-time
- Ownership system: Gestione automatica della memoria senza garbage collection
- Error handling con Result<T,E>: Gestione esplicita degli errori senza eccezioni impreviste
- Pattern matching esaustivo: Controllo completo di tutti i casi possibili
- Lifetime management: Prevenzione di dangling pointers e use-after-free
#### Frontend Safety (Flutter/Dart)
- Null safety: Prevenzione di null pointer exceptions a compile-time
- State immutabilità: Utilizzo di Riverpod con stato immutabile per prevenire modifiche accidentali
- Type safety: Sistema di tipi forte per prevenire errori di tipo
- Exception handling strutturato: Try-catch blocks per gestione controllata degli errori
- Input validation: Controlli sui dati utente prima dell'elaborazione
- Safe navigation: Operatori ?. e ?? per accesso sicuro ai dati
#### Data Safety
- Salvataggio automatico locale: Persistenza dei dati nel database locale
- Validazione payload: Controllo dei dati in ingresso e uscita
- Cleanup automatico: Pulizia dello stato dell'applicazione (cleanup() method)

### Estensibilità futura
L'architettura modulare permette facilmente:
- Aggiunta nuovi tipi di messaggi (file, media, emoji)
- Implementazione cifratura end-to-end
- Integrazione servizi esterni (notifiche push)
- Scaling orizzontale con load balancing
- Migrazione a database distribuiti (PostgreSQL, MongoDB)
