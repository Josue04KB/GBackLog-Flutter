import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef JsonMap = Map<String, dynamic>;
typedef JsonList = List<JsonMap>;

class SupabaseRemoteService {
  final SupabaseClient _client;

  SupabaseRemoteService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // --- Gestión de Sesión y JWT ---
  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception('Error de autenticación: ${e.message}');
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red e intenta de nuevo.');
    } catch (e) {
      throw Exception('Fallo de red al iniciar sesión. Reintenta.');
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception('No se pudo registrar la cuenta: ${e.message}');
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red e intenta de nuevo.');
    } catch (e) {
      throw Exception('Fallo de red al registrar usuario. Reintenta.');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar la sesión.');
    }
  }

  // --- Consultas a Entidad Maestra 1: Plataformas ---
  Future<JsonList> fetchPlataformas() async {
    try {
      final response = await _client
          .from('plataformas')
          .select()
          .order('id', ascending: true);
      return response;
    } on SocketException {
      throw Exception('No hay conexión a internet para cargar las plataformas.');
    } catch (e) {
      throw Exception('Error de red al consultar plataformas: $e');
    }
  }

  // --- Consultas y Creación en Entidad Maestra 2: Videojuegos ---
  Future<JsonList> fetchVideojuegos() async {
    try {
      final response = await _client
          .from('videojuegos')
          .select()
          .order('creado_en', ascending: false);
      return response;
    } on SocketException {
      throw Exception('No hay conexión a internet para cargar el catálogo.');
    } catch (e) {
      throw Exception('Error de red al consultar videojuegos: $e');
    }
  }

  Future<void> insertVideojuego(JsonMap data) async {
    try {
      await _client.from('videojuegos').insert(data);
    } on SocketException {
      throw Exception('Sin conexión. No se pudo guardar el videojuego.');
    } catch (e) {
      throw Exception('Error al registrar videojuego en la nube: $e');
    }
  }

  // --- Consultas y Registro en Entidad Transaccional: Sesiones de Juego ---
  Future<JsonList> fetchSesiones({int? videojuegoId}) async {
    try {
      var query = _client
          .from('sesiones_juego')
          .select('*, videojuegos(titulo), plataformas(nombre)');

      if (videojuegoId != null) {
        query = query.eq('videojuego_id', videojuegoId);
      }

      final response = await query.order('fecha', ascending: false);
      return response;
    } on SocketException {
      throw Exception('Sin conexión a internet para consultar las sesiones.');
    } catch (e) {
      throw Exception('Error de red al cargar sesiones de juego: $e');
    }
  }

  Future<void> insertSesion(JsonMap data) async {
    try {
      await _client.from('sesiones_juego').insert(data);
    } on SocketException {
      throw Exception('Sin conexión. La sesión de juego no se pudo registrar.');
    } catch (e) {
      throw Exception('Error al registrar la transacción en el servidor: $e');
    }
  }
}