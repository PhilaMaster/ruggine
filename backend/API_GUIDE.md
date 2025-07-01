# API Documentation - User Management

## Server
Il server gira su: `http://localhost:8080`

## Endpoints

### 1. Creare un nuovo utente
- **URL**: `POST /api/users`
- **Content-Type**: `application/json`
- **Body**:
```json
{
  "username": "mario_rossi",
  "password": "password123"
}
```

**Risposta di successo (201 Created):**
```json
{
  "id": 1,
  "username": "mario_rossi"
}
```

**Risposta di errore (400 Bad Request):**
```json
{
  "error": "Username already exists"
}
```

### 2. Ottenere tutti gli utenti
- **URL**: `GET /api/users`

**Risposta di successo (200 OK):**
```json
[
  {
    "id": 1,
    "username": "mario_rossi"
  },
  {
    "id": 2,
    "username": "luca_bianchi"
  }
]
```

## Come testare con Postman

### Test 1: Creare un utente
1. Apri Postman
2. Crea una nuova richiesta POST
3. URL: `http://localhost:8080/api/users`
4. Headers: `Content-Type: application/json`
5. Body (raw JSON):
```json
{
  "username": "test_user",
  "password": "mypassword"
}
```
6. Invia la richiesta

### Test 2: Leggere tutti gli utenti
1. Crea una nuova richiesta GET
2. URL: `http://localhost:8080/api/users`
3. Invia la richiesta

## Avviare il server
```bash
cargo run
```

Il server mostrerà:
```
🚀 Server starting on http://localhost:8080
📖 API endpoints:
  POST /api/users - Create user
  GET  /api/users - Get all users
```
