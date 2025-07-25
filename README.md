# Ruggine Chat Application

## Project Description
Ruggine is a multiplatform chat application consisting of a Rust backend and a Flutter client. The application supports private messages, group chats, and invitations.

## System Requirements
- Backend: Rust (version 1.70+), Diesel CLI
- Client: Flutter SDK (version 3.0+), Dart SDK
- Database: SQLite
- Operating Systems: Windows, macOS, Linux, Android, iOS (tested on Windows and Linux)

## Installation

### Backend Setup
1. Navigate to the project directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   cargo build
   ```
3. Start the server:
   ```bash
   cargo run
   ```

### Client Setup
1. Navigate to the client directory:
   ```bash
   cd client/ruggine_client
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## Application Usage

The following features are available:

### Login
- Log in to an existing one (registration form in flutter is to be implemented)
   - you are provided with two test account admin:admin, admin2:admin
   - otherwise you can register a new user using the api, submitting a POST request through postman at baseUrl/auth/register
- Authentication is handled via JWT tokens

### Private Messages
- Create a chat with a user using their username
- Type your message and press enter
- Messages are synchronized in real-time

### Group Chats
- Create a new group or join an existing one
- Send messages to the group
- Manage group members

### Group Invitations
- Send invitations to other users
- Accept or decline received invitations

## API Reference
For developers: consult the `API_GUIDE.md` file and the Postman collection `Ruggine Chat API.postman_collection.json` to test the APIs.

---

# Architecture Documentation

## System Overview
The Ruggine project implements a multiplatform chat system based on a client-server architecture. The backend is developed in Rust to ensure high performance and memory safety, while the client uses Flutter for multiplatform portability.

## Backend Architecture

### Modular Structure
The server is organized into specialized modules:

- **Handler**: Manages HTTP and WebSocket requests
- **Models**: Defines domain data structures
- **Middleware**: Implements authentication and validation
- **Utility**: Support functions for logging and configuration

### Concurrency Management
The server uses the Actix Web framework which implements a concurrency model based on:

- **Actor system**: Each connection is managed by an independent actor
- **Async/await**: Asynchronous programming for non-blocking I/O
- **Thread pool**: Thread pool for CPU-intensive processing

### Main Data Structures
- **User**: User management with JWT authentication
- **Message**: Point-to-point messages with timestamps, valid for both private and group chats
- **Chat**: Identifies a chat (both private and group) and maintains its main information
- **GroupInvite**: Invitation system with states (pending, accepted, rejected)

### Data Persistence
Uses SQLite with Diesel ORM for:
- Automatic schema migration
- Compile-time type-safe queries
- Connection pooling to optimize performance

## Client Architecture (Flutter)

### Code Organization
- **Core**: Business logic and services
- **Data**: Data access layer and APIs
- **Models**: Client-side data representation
- **UI**: Reactive user interface
- **Exceptions**: Centralized error handling

### State Management
Implements BLoC (Business Logic Component) pattern for:
- Separation between business logic and UI
- Reactive event handling
- Simplified component testing

### Client-Server Communication

#### Protocols Used
- **HTTP/HTTPS**: REST APIs for CRUD operations
- **WebSocket**: Real-time bidirectional communication for notifying clients upon message and invitation receipt
- **JSON**: Standardized data exchange format

### Authentication and Security
- **JWT tokens**: Stateless authentication with refresh tokens
- **CORS**: Configurable cross-origin access control
- **Input validation**: Data sanitization on both client and server sides

### Scalability and Performance

#### Server Optimizations
- **Connection pooling**: Database connection reuse
- **Lazy loading**: On-demand data loading
- **Batch operations**: Batch processing for efficiency

#### Client Optimizations
- **Pagination**: Incremental message loading
- **Caching**: Local storage of messages and chats
- **Background sync**: Background synchronization

## Safety Features

### Backend Safety (Rust)
Using Rust as the programming language for our server provides guarantees:
- **Memory safety guaranteed**: Prevents buffer overflows, memory leaks, and data races at compile-time
- **Ownership system**: Automatic memory management without garbage collection
- **Error handling with Result<T,E>**: Explicit error handling without unexpected exceptions
- **Exhaustive pattern matching**: Complete control over all possible cases
- **Lifetime management**: Prevention of dangling pointers and use-after-free

### Frontend Safety (Flutter/Dart)
- **Null safety**: Prevention of null pointer exceptions at compile-time
- **State immutability**: Use of Riverpod with immutable state to prevent accidental modifications
- **Type safety**: Strong type system to prevent type errors
- **Structured exception handling**: Try-catch blocks for controlled error handling
- **Input validation**: User data checks before processing
- **Safe navigation**: ?. and ?? operators for safe data access

### Data Safety
- **Automatic local saving**: Data persistence in local database
- **Payload validation**: Input and output data validation
- **Automatic cleanup**: Application state cleanup (cleanup() method)

## Future Extensibility
The modular architecture easily allows for:
- Adding new message types (files, media, emojis)
- Implementing end-to-end encryption
- Integrating external services (push notifications)
- Horizontal scaling with load balancing
- Migration to distributed databases (PostgreSQL, MongoDB)

## Contributions
Project developed by students from polito:
- Pasquale Papalia
- Adriano Giuliani
- Borlina Edoardo
- Federico Ferrari
