import 'package:flutter/foundation.dart';
import '../../domain/models/game_models.dart';
import '../../domain/repositories/game_repository.dart';
import '../widgets/ui_state.dart';

class CatalogViewModel extends ChangeNotifier {
  final GameRepository _repository;

  CatalogViewModel(this._repository);

  ViewState _state = ViewState.loading;
  String? _errorMessage;
  bool _isSubmitting = false;

  List<Plataforma> _plataformas = [];
  List<Videojuego> _videojuegos = [];

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  List<Plataforma> get plataformas => _plataformas;
  List<Videojuego> get videojuegos => _videojuegos;

  // Consulta ambas entidades maestras directamente de la nube (Sin caché offline)
  Future<void> cargarMaestros() async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getPlataformas(),
        _repository.getVideojuegos(),
      ]);

      _plataformas = results[0] as List<Plataforma>;
      _videojuegos = results[1] as List<Videojuego>;

      if (_plataformas.isEmpty && _videojuegos.isEmpty) {
        _state = ViewState.empty;
      } else {
        _state = ViewState.success;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = ViewState.error;
    }
    notifyListeners();
  }

  Future<bool> agregarVideojuego({
    required String titulo,
    required String genero,
    required String estado,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.crearVideojuego(
        titulo: titulo,
        genero: genero,
        estado: estado,
      );
      _isSubmitting = false;
      await cargarMaestros(); // Recarga desde Supabase para verificar en vivo
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}