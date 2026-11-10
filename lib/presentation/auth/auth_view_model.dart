import 'package:flutter/foundation.dart';

import '../../domain/repositories/game_repository.dart';
import '../../domain/use_cases/validar_usuario.dart';

class AuthViewModel extends ChangeNotifier {
  final GameRepository _repository;

  AuthViewModel(this._repository);

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _repository.hasValidSession;
  String? get userEmail => _repository.currentUserEmail;
  String? get username => _repository.currentUsername;
  String? get userAvatarUrl => _repository.currentUserAvatarUrl;

  /// Notifica a las vistas que los metadatos del usuario cambiaron fuera del
  /// flujo de autenticación, por ejemplo después de actualizar el avatar.
  void notifyProfileChanged() => notifyListeners();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(
    String email,
    String password, {
    required String username,
  }) async {
    if (_isLoading) return false;
    final validationError = validarUsuario(username);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signUp(
        email: email.trim(),
        password: password,
        username: username.trim(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.signOut();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
