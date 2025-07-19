class LoginException implements Exception {
  final String message;

  LoginException(this.message);

  @override
  String toString() {
    return message;
  }
}

class UserNotFoundException implements Exception {
  // final String message;

  UserNotFoundException();

  @override
  String toString() {
    return "Errore: uno o più utenti specificati non esistono";
  }
}

class SameUserException implements Exception {
  // final String message;

  SameUserException();

  @override
  String toString() {
    return "Errore: non puoi creare una chat con te stesso.";
  }
}

class ChatCreationError implements Exception {
  final String message;

  ChatCreationError(this.message);

  @override
  String toString() {
    return "Errore durante la creazione della chat: $message";
  }
}