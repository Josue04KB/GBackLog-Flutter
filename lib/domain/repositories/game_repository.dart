import '../models/game_models.dart';

abstract class GameRepository {
  bool get hasValidSession;
  String? get currentUserEmail;
  String? get currentUserAvatarUrl;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> signOut();

  Future<List<Plataforma>> getPlataformas();

  Future<List<Videojuego>> getVideojuegos();
  Future<List<JuegoCatalogo>> getCatalogoGlobal();
  Future<void> crearVideojuego({
    required String titulo,
    required String genero,
    required String estado,
    required String plataforma,
    String? imagenUrl,
  });
  Future<void> actualizarVideojuego({
    required int id,
    required String titulo,
    required String estado,
    required String plataforma,
    required String imagenUrl,
  });
  Future<void> eliminarVideojuego(int id);

  Future<List<SesionJuego>> getSesiones({int? videojuegoId});
  Future<void> registrarSesion({
    required int videojuegoId,
    required int plataformaId,
    required int minutosJugados,
    required String notas,
  });
  Future<SesionJuego> actualizarSesion({
    required int id,
    required int plataformaId,
    required int minutosJugados,
    required String notas,
  });
  Future<void> eliminarSesion(int id);

  Future<void> crearPlataforma({
    required String nombre,
    required String fabricante,
    required String formato,
  });
  Future<void> eliminarPlataforma(int id);
  Future<void> actualizarContrasena(String nuevaContrasena);
  Future<String> subirImagen({
    required String rutaLocal,
    required String prefijo,
  });
  Future<void> actualizarAvatarUrl(String avatarUrl);
  Future<void> eliminarCuentaUsuario();
}
