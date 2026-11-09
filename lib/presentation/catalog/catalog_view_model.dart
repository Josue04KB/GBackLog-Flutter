import 'package:flutter/foundation.dart';

import '../../domain/models/game_models.dart';
import '../../domain/repositories/game_repository.dart';
import '../widgets/ui_state.dart';

class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel(this._repository);

  final GameRepository _repository;

  ViewState _state = ViewState.loading;
  ViewState _catalogoGlobalState = ViewState.loading;
  String? _errorMessage;
  String? _catalogoGlobalErrorMessage;
  List<Videojuego> _videojuegos = [];
  List<Plataforma> _plataformas = [];
  List<JuegoCatalogo> _catalogoGlobal = [];
  String _filtroEstado = 'Todos';

  ViewState get state => _state;
  ViewState get catalogoGlobalState => _catalogoGlobalState;
  String? get errorMessage => _errorMessage;
  String? get catalogoGlobalErrorMessage => _catalogoGlobalErrorMessage;
  List<Videojuego> get videojuegos => List.unmodifiable(_videojuegos);
  List<Plataforma> get plataformas => List.unmodifiable(_plataformas);
  List<JuegoCatalogo> get catalogoGlobal => List.unmodifiable(_catalogoGlobal);
  String get filtroEstado => _filtroEstado;

  List<Videojuego> get videojuegosFiltrados {
    if (_filtroEstado == 'Todos') {
      return _videojuegos;
    }
    return _videojuegos
        .where((juego) => juego.estado == _filtroEstado)
        .toList();
  }

  void cambiarFiltro(String nuevoFiltro) {
    _filtroEstado = nuevoFiltro;
    notifyListeners();
  }

  Future<bool> cargarMaestros() async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final videojuegos = await _repository.getVideojuegos();
      final plataformas = await _repository.getPlataformas();

      _videojuegos = videojuegos;
      _plataformas = plataformas;
      _state = videojuegos.isEmpty ? ViewState.empty : ViewState.success;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFrom(error);
      _state = ViewState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cargarCatalogoGlobal() async {
    _catalogoGlobalState = ViewState.loading;
    _catalogoGlobalErrorMessage = null;
    notifyListeners();

    try {
      _catalogoGlobal = await _repository.getCatalogoGlobal();
      _catalogoGlobalState = _catalogoGlobal.isEmpty
          ? ViewState.empty
          : ViewState.success;
      notifyListeners();
      return true;
    } catch (error) {
      _catalogoGlobalErrorMessage = _messageFrom(error);
      _catalogoGlobalState = ViewState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> agregarVideojuego({
    required String titulo,
    required String genero,
    required String estado,
    required String plataforma,
    String? imagenUrl,
  }) async {
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
      return await cargarMaestros();
    } catch (error) {
      _errorMessage = _messageFrom(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarVideojuego({
    required int id,
    required String nuevoTitulo,
    required String nuevoEstado,
    required String nuevaImagenUrl,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.actualizarVideojuego(
        id: id,
        titulo: nuevoTitulo,
        estado: nuevoEstado,
        imagenUrl: nuevaImagenUrl,
      );

      final index = _videojuegos.indexWhere((juego) => juego.id == id);
      if (index != -1) {
        final actual = _videojuegos[index];
        _videojuegos[index] = Videojuego(
          id: actual.id,
          titulo: nuevoTitulo,
          genero: actual.genero,
          estado: nuevoEstado,
          plataforma: actual.plataforma,
          imagenUrl: nuevaImagenUrl.isEmpty ? null : nuevaImagenUrl,
        );
      }

      _state = _videojuegos.isEmpty ? ViewState.empty : ViewState.success;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFrom(error);
      notifyListeners();
      return false;
    }
  }

  Future<String?> subirPortada(String rutaLocal) async {
    _errorMessage = null;
    notifyListeners();

    try {
      return await _repository.subirImagen(
        rutaLocal: rutaLocal,
        prefijo: 'cover',
      );
    } catch (error) {
      _errorMessage = _messageFrom(error);
      notifyListeners();
      return null;
    }
  }

  Future<bool> borrarVideojuego(int id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.eliminarVideojuego(id);
      _videojuegos.removeWhere((juego) => juego.id == id);
      _state = _videojuegos.isEmpty ? ViewState.empty : ViewState.success;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFrom(error);
      notifyListeners();
      return false;
    }
  }

  String _messageFrom(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
