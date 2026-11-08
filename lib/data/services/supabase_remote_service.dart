import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef JsonMap = Map<String, dynamic>;
typedef JsonList = List<JsonMap>;

class SupabaseRemoteService {
  final SupabaseClient _client;

  SupabaseRemoteService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

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

  Future<void> deleteVideojuego(int id) async {
    try {
      await _client.from('videojuegos').delete().eq('id', id);
    } on SocketException {
      throw Exception('Sin conexión. No se pudo eliminar el videojuego.');
    } catch (e) {
      throw Exception('Error al eliminar videojuego: $e');
    }
  }

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

  // --- Plataformas ---
  Future<void> insertPlataforma(JsonMap data) async {
    try {
      await _client.from('plataformas').insert(data);
    } on SocketException {
      throw Exception('Sin conexión para crear la plataforma.');
    } catch (e) {
      throw Exception('Error al crear plataforma: $e');
    }
  }

  Future<void> deletePlataforma(int id) async {
    try {
      await _client.from('plataformas').delete().eq('id', id);
    } on SocketException {
      throw Exception('Sin conexión para eliminar la plataforma.');
    } catch (e) {
      throw Exception('Error al eliminar plataforma: $e');
    }
  }

  // --- Cuenta de Usuario ---
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw Exception('Error al actualizar contraseña: ${e.message}');
    } catch (e) {
      throw Exception('Fallo de red al cambiar contraseña.');
    }
  }

  Future<void> deleteAccount() async {
    try {
      // Nota: En Supabase la eliminación total por API suele requerir función de servidor o Admin, 
      // pero cerramos sesión e invalidamos el usuario actual.
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Error al procesar la baja de cuenta.');
    }
  }
}
