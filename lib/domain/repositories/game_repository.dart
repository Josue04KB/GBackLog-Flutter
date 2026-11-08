import '../models/game_models.dart';

abstract class GameRepository {
  // --- Autenticación y Sesión ---
  bool get hasValidSession;
  String? get currentUserEmail;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> signOut();

  // --- Entidad Maestra 1: Plataformas ---
  Future<List<Plataforma>> getPlataformas();

  // --- Entidad Maestra 2: Videojuegos ---
  Future<List<Videojuego>> getVideojuegos();
  Future<void> crearVideojuego({
    required String titulo,
    required String genero,
    required String estado,
  });

  // --- Entidad Transaccional: Sesiones de Juego ---
  Future<List<SesionJuego>> getSesiones({int? videojuegoId});
  Future<void> registrarSesion({
    required int videojuegoId,
    required int plataformaId,
    required int minutosJugados,
    required String notas,
  });
}