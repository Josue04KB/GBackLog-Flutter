import '../models/game_models.dart';

abstract class GameRepository {
  bool get hasValidSession;
  String? get currentUserEmail;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> signOut();

  Future<List<Plataforma>> getPlataformas();

  Future<List<Videojuego>> getVideojuegos();
  Future<void> crearVideojuego({
    required String titulo,
    required String genero,
    required String estado,
    required String plataforma,
    String? imagenUrl,
  });
  Future<void> eliminarVideojuego(int id);

  Future<List<SesionJuego>> getSesiones({int? videojuegoId});
  Future<void> registrarSesion({
    required int videojuegoId,
    required int plataformaId,
    required int minutosJugados,
    required String notas,
  });
}