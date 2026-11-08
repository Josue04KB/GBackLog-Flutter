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

  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  Future<bool> agregarPlataforma({required String nombre, required String fabricante, required String formato}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.crearPlataforma(nombre: nombre, fabricante: fabricante, formato: formato);
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

  Future<bool> borrarPlataforma(int id) async {
    try {
      await _repository.eliminarPlataforma(id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
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
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}