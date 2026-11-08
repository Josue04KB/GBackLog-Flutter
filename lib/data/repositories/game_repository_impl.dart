import '../../domain/models/game_models.dart';
import '../../domain/repositories/game_repository.dart';
import '../services/supabase_remote_service.dart';

class GameRepositoryImpl implements GameRepository {
  final SupabaseRemoteService _remoteService;

  GameRepositoryImpl(this._remoteService);

  @override
  bool get hasValidSession => _remoteService.currentSession != null;

  @override
  String? get currentUserEmail => _remoteService.currentUser?.email;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _remoteService.signIn(email.trim(), password);
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    await _remoteService.signUp(email.trim(), password);
  }

  @override
  Future<void> signOut() async {
    await _remoteService.signOut();
  }

  @override
  Future<List<Plataforma>> getPlataformas() async {
    final rawList = await _remoteService.fetchPlataformas();
    return rawList.map((json) => Plataforma.fromJson(json)).toList();
  }

  @override
  Future<void> crearPlataforma({
    required String nombre,
    required String fabricante,
    required String formato,
  }) async {
    final userId = _remoteService.currentUser?.id;
    await _remoteService.insertPlataforma({
      'nombre': nombre.trim(),
      'fabricante': fabricante.trim(),
      'formato_default': formato.trim(),
      'user_id': userId,
    });
  }

  @override
  Future<void> eliminarPlataforma(int id) async {
    await _remoteService.deletePlataforma(id);
  }

  @override
  Future<List<Videojuego>> getVideojuegos() async {
    final rawList = await _remoteService.fetchVideojuegos();
    return rawList.map((json) => Videojuego.fromJson(json)).toList();
  }

  @override
  Future<void> crearVideojuego({
    required String titulo,
    required String genero,
    required String estado,
    required String plataforma,
    String? imagenUrl,
  }) async {
    await _remoteService.insertVideojuego({
      'titulo': titulo.trim(),
      'genero': genero.trim(),
      'estado': estado,
      'plataforma': plataforma,
      'imagen_url': (imagenUrl != null && imagenUrl.trim().isNotEmpty)
          ? imagenUrl.trim()
          : null,
    });
  }

  @override
  Future<void> eliminarVideojuego(int id) async {
    await _remoteService.deleteVideojuego(id);
  }

  @override
  Future<List<SesionJuego>> getSesiones({int? videojuegoId}) async {
    final rawList = await _remoteService.fetchSesiones(videojuegoId: videojuegoId);
    return rawList.map((json) => SesionJuego.fromJson(json)).toList();
  }

  @override
  Future<void> registrarSesion({
    required int videojuegoId,
    required int plataformaId,
    required int minutosJugados,
    required String notas,
  }) async {
    await _remoteService.insertSesion({
      'videojuego_id': videojuegoId,
      'plataforma_id': plataformaId,
      'minutos_jugados': minutosJugados,
      'notas': notas,
    });
  }

  @override
  Future<void> actualizarContrasena(String nuevaContrasena) async {
    await _remoteService.updatePassword(nuevaContrasena);
  }

  @override
  Future<void> eliminarCuentaUsuario() async {
    await _remoteService.deleteAccount();
  }
}