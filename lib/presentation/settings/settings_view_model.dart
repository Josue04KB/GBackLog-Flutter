import '../../core/errors/error_messages.dart';

import 'package:flutter/foundation.dart';

import '../../domain/repositories/game_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final GameRepository _repository;

  SettingsViewModel(this._repository);

  bool _isDarkMode = true; // Tema oscuro por defecto
  bool _isLoading = false;
  String? _errorMessage;

  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userEmail => _repository.currentUserEmail;
  String? get username => _repository.currentUsername;
  String? get userAvatarUrl => _repository.currentUserAvatarUrl;

  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  Future<bool> agregarPlataforma({
    required String nombre,
    required String fabricante,
    required String formato,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.crearPlataforma(
        nombre: nombre,
        fabricante: fabricante,
        formato: formato,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = userMessage(
        e,
        fallback: 'No pudimos crear la plataforma. Inténtalo de nuevo.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> borrarPlataforma(int id) async {
    try {
      await _repository.eliminarPlataforma(id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = userMessage(
        e,
        fallback: 'No pudimos eliminar la plataforma. Inténtalo de nuevo.',
        operation: ErrorOperation.deletePlatform,
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> editarPlataforma({
    required int id,
    required String nombre,
    required String fabricante,
    required String formato,
  }) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.actualizarPlataforma(
        id: id,
        nombre: nombre,
        fabricante: fabricante,
        formato: formato,
      );
      return true;
    } catch (error) {
      _errorMessage = userMessage(
        error,
        fallback: 'No pudimos actualizar la plataforma. Inténtalo de nuevo.',
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cambiarContrasena(String nuevaPass) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.actualizarContrasena(nuevaPass);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = userMessage(
        e,
        fallback: 'No pudimos cambiar la contraseña. Inténtalo de nuevo.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarAvatar(String rutaLocal) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final avatarUrl = await _repository.subirImagen(
        rutaLocal: rutaLocal,
        prefijo: 'avatar',
      );
      await _repository.actualizarAvatarUrl(avatarUrl);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = userMessage(
        e,
        fallback:
            'No pudimos actualizar la foto de perfil. Inténtalo de nuevo.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarCuenta() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.eliminarCuentaUsuario();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = userMessage(
        e,
        fallback: 'No pudimos eliminar la cuenta. Inténtalo de nuevo.',
      );
      notifyListeners();
      return false;
    }
  }
}
