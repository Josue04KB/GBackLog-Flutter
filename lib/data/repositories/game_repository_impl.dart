import '../../core/errors/app_exception.dart';
import '../../domain/models/game_models.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/use_cases/validar_usuario.dart';
import '../../domain/use_cases/validar_plataforma.dart';
import '../services/supabase_remote_service.dart';

class GameRepositoryImpl implements GameRepository {
  final SupabaseRemoteService _remoteService;

  GameRepositoryImpl(this._remoteService);

  @override
  bool get hasValidSession => _remoteService.currentSession != null;

  @override
  String? get currentUserEmail => _remoteService.currentUser?.email;

  @override
  String? get currentUsername => _remoteService.currentUsername;

  @override
  String? get currentUserAvatarUrl => _remoteService.currentUserAvatarUrl;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _remoteService.signIn(email.trim(), password);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final error = validarUsuario(username);
    if (error != null) throw AppException(error);
    await _remoteService.signUp(email.trim(), password, username.trim());
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
    validarPlataforma(nombre, fabricante, formato);
    final userId = _remoteService.currentUser?.id;
    if (userId == null) {
      throw AppException('Vuelve a iniciar sesión para continuar.');
    }
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
  Future<Plataforma> actualizarPlataforma({
    required int id,
    required String nombre,
    required String fabricante,
    required String formato,
  }) async {
    validarPlataforma(nombre, fabricante, formato);
    final updated = await _remoteService.updatePlataforma(
      id,
      nombre: nombre.trim(),
      fabricante: fabricante.trim(),
      formato: formato.trim(),
    );
    return Plataforma.fromJson(updated);
  }

  @override
  Future<List<Videojuego>> getVideojuegos() async {
    final rawList = await _remoteService.fetchVideojuegos();
    return rawList.map((json) => Videojuego.fromJson(json)).toList();
  }

  @override
  Future<List<JuegoCatalogo>> getCatalogoGlobal() async {
    final rawList = await _remoteService.fetchCatalogoGlobal();
    return rawList.map((json) => JuegoCatalogo.fromJson(json)).toList();
  }

  @override
  Future<void> crearVideojuego({
    required String titulo,
    required String genero,
    required String estado,
    required String plataforma,
    String? imagenUrl,
  }) async {
    final userId = _remoteService.currentUser?.id;
    if (userId == null) {
      throw AppException('Vuelve a iniciar sesión para continuar.');
    }

    await _remoteService.insertVideojuego({
      'user_id': userId,
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
  Future<void> actualizarVideojuego({
    required int id,
    required String titulo,
    required String estado,
    required String plataforma,
    required String imagenUrl,
  }) async {
    await _remoteService.updateVideojuego(id, {
      'titulo': titulo.trim(),
      'estado': estado,
      'plataforma': plataforma.trim(),
      'imagen_url': imagenUrl.trim().isEmpty ? null : imagenUrl.trim(),
    });
  }

  @override
  Future<void> eliminarVideojuego(int id) async {
    await _remoteService.deleteVideojuego(id);
  }

  @override
  Future<List<SesionJuego>> getSesiones({int? videojuegoId}) async {
    final rawList = await _remoteService.fetchSesiones(
      videojuegoId: videojuegoId,
    );
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
  Future<SesionJuego> actualizarSesion({
    required int id,
    required int plataformaId,
    required int minutosJugados,
    required String notas,
  }) async {
    final updated = await _remoteService.updateSesion(id, {
      'plataforma_id': plataformaId,
      'minutos_jugados': minutosJugados,
      'notas': notas.trim(),
    });
    return SesionJuego.fromJson(updated);
  }

  @override
  Future<void> eliminarSesion(int id) => _remoteService.deleteSesion(id);

  @override
  Future<void> actualizarContrasena(String nuevaContrasena) async {
    await _remoteService.updatePassword(nuevaContrasena);
  }

  @override
  Future<String> subirImagen({
    required String rutaLocal,
    required String prefijo,
  }) {
    return _remoteService.uploadImage(localPath: rutaLocal, prefix: prefijo);
  }

  @override
  Future<void> actualizarAvatarUrl(String avatarUrl) {
    return _remoteService.updateAvatarUrl(avatarUrl);
  }

  @override
  Future<void> eliminarCuentaUsuario() async {
    await _remoteService.deleteAccount();
  }
}
