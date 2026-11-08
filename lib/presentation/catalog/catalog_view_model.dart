import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/game_models.dart';
import '../widgets/ui_state.dart';

class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel([dynamic _]);

  ViewState _state = ViewState.loading;
  String? _errorMessage;
  List<Videojuego> _videojuegos = [];
  List<Plataforma> _plataformas = [];
  String _filtroEstado = 'Todos';

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Videojuego> get videojuegos => _videojuegos;
  List<Plataforma> get plataformas => _plataformas;
  String get filtroEstado => _filtroEstado;

  List<Videojuego> get videojuegosFiltrados {
    if (_filtroEstado == 'Todos') {
      return _videojuegos;
    }
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
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final responseJuegos = await supabase
          .from('videojuegos')
          .select()
          .eq('user_id', userId)
          .order('id', ascending: false);

      _videojuegos = (responseJuegos as List)
          .map((json) => Videojuego.fromJson(json))
          .toList();

      try {
        final responsePlataformas = await supabase
            .from('plataformas')
            .select()
            .order('nombre', ascending: true);

        _plataformas = (responsePlataformas as List)
            .map((json) => Plataforma.fromJson(json))
            .toList();
      } catch (_) {}

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
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) throw Exception('Usuario no autenticado');

      await supabase.from('videojuegos').insert({
        'user_id': userId,
        'titulo': titulo,
        'genero': genero,
        'estado': estado,
        'plataforma': plataforma,
        'imagen_url': imagenUrl ?? '',
      });

      await cargarMaestros();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
    try {
      final supabase = Supabase.instance.client;

      await supabase
          .from('videojuegos')
          .update({
            'titulo': nuevoTitulo,
            'estado': nuevoEstado,
            'imagen_url': nuevaImagenUrl,
          })
          .eq('id', id);

      final index = _videojuegos.indexWhere((j) => j.id == id);
      if (index != -1) {
        final actual = _videojuegos[index];
        _videojuegos[index] = Videojuego(
          id: actual.id,
          titulo: nuevoTitulo,
          genero: actual.genero,
          estado: nuevoEstado,
          plataforma: actual.plataforma,
          imagenUrl: nuevaImagenUrl,
        );
      }

      _state = _videojuegos.isEmpty ? ViewState.empty : ViewState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> borrarVideojuego(int id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('videojuegos').delete().eq('id', id);

      _videojuegos.removeWhere((j) => j.id == id);
      if (_videojuegos.isEmpty) {
        _state = ViewState.empty;
      } else {
        _state = ViewState.success;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}