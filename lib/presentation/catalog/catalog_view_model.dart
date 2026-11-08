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
  String _filtroEstado = 'Todos';

  List<Plataforma> _plataformas = [];
  List<Videojuego> _videojuegos = [];

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  String get filtroEstado => _filtroEstado;
  List<Plataforma> get plataformas => _plataformas;
  List<Videojuego> get videojuegos => _videojuegos;

  List<Videojuego> get videojuegosFiltrados {
    if (_filtroEstado == 'Todos') return _videojuegos;
    return _videojuegos.where((j) => j.estado == _filtroEstado).toList();
  }

  void cambiarFiltro(String nuevoFiltro) {
    _filtroEstado = nuevoFiltro;
    notifyListeners();
  }

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

      if (_videojuegos.isEmpty) {
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
    required String plataforma,
    String? imagenUrl,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.crearVideojuego(
        titulo: titulo,
        genero: genero,
        estado: estado,
        plataforma: plataforma,
        imagenUrl: imagenUrl,
      );
      _isSubmitting = false;
      await cargarMaestros();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> borrarVideojuego(int id) async {
    try {
      await _repository.eliminarVideojuego(id);
      await cargarMaestros();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}