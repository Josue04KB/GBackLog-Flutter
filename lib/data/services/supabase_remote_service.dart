import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_messages.dart';

typedef JsonMap = Map<String, dynamic>;
typedef JsonList = List<JsonMap>;

class SupabaseRemoteService {
  final SupabaseClient _client;

  SupabaseRemoteService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  String? get currentUsername {
    final username = currentUser?.userMetadata?['username'];
    if (username is String && username.trim().isNotEmpty) {
      return username.trim();
    }
    // Coincide con el nombre de respaldo usado en el SQL para cuentas antiguas.
    final email = currentUser?.email;
    return email != null && email.contains('@') ? email.split('@').first : null;
  }

  String? get currentUserAvatarUrl {
    final avatarUrl = currentUser?.userMetadata?['avatar_url'];
    return avatarUrl is String && avatarUrl.isNotEmpty ? avatarUrl : null;
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos iniciar sesión. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos crear la cuenta. Inténtalo de nuevo.',
          operation: ErrorOperation.signUp,
        ),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos cerrar sesión. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<JsonList> fetchPlataformas() async {
    try {
      final response = await _client
          .from('plataformas')
          .select()
          .order('id', ascending: true);
      return response;
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos cargar las plataformas. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<JsonList> fetchVideojuegos() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        throw const AppException('Vuelve a iniciar sesión para continuar.');
      }

      final response = await _client
          .from('videojuegos')
          .select()
          .eq('user_id', userId)
          .order('creado_en', ascending: false);
      return response;
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos cargar tu colección. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<JsonList> fetchCatalogoGlobal() async {
    try {
      final response = await _client
          .from('catalogo_global')
          .select()
          .order('titulo', ascending: true);
      return response;
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos cargar el catálogo. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<void> insertVideojuego(JsonMap data) async {
    try {
      await _client.from('videojuegos').insert(data);
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos guardar el juego. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<void> deleteVideojuego(int id) async {
    try {
      final deleted = await _client
          .from('videojuegos')
          .delete()
          .eq('id', id)
          .select('id');
      if (deleted.isEmpty) {
        throw const AppException(
          'El juego ya no existe o no tienes permiso para eliminarlo.',
        );
      }
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos eliminar el juego. Inténtalo de nuevo.',
          operation: ErrorOperation.deleteGame,
        ),
      );
    }
  }

  Future<void> updateVideojuego(int id, JsonMap data) async {
    try {
      final updated = await _client
          .from('videojuegos')
          .update(data)
          .eq('id', id)
          .select('id');
      if (updated.isEmpty) {
        throw const AppException(
          'El juego ya no existe o no tienes permiso para editarlo.',
        );
      }
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos actualizar el juego. Inténtalo de nuevo.',
        ),
      );
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
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos cargar las sesiones. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<void> insertSesion(JsonMap data) async {
    try {
      await _client.from('sesiones_juego').insert(data);
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos guardar la sesión. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<JsonMap> updateSesion(int id, JsonMap data) async {
    if (currentUser == null) {
      throw const AppException('Vuelve a iniciar sesión para continuar.');
    }
    try {
      final updated = await _client
          .from('sesiones_juego')
          .update(data)
          .eq('id', id)
          .select('*, videojuegos(titulo), plataformas(nombre)');
      if (updated.isEmpty) {
        throw const AppException(
          'La sesión ya no existe o no tienes permiso para editarla.',
        );
      }
      return updated.single;
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos actualizar la sesión. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<void> deleteSesion(int id) async {
    if (currentUser == null) {
      throw const AppException('Vuelve a iniciar sesión para continuar.');
    }
    try {
      final deleted = await _client
          .from('sesiones_juego')
          .delete()
          .eq('id', id)
          .select('id');
      if (deleted.isEmpty) {
        throw const AppException(
          'La sesión ya no existe o no tienes permiso para eliminarla.',
        );
      }
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos eliminar la sesión. Inténtalo de nuevo.',
        ),
      );
    }
  }

  // --- Plataformas ---
  Future<void> insertPlataforma(JsonMap data) async {
    try {
      await _client.from('plataformas').insert(data);
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos crear la plataforma. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<void> deletePlataforma(int id) async {
    try {
      final deleted = await _client
          .from('plataformas')
          .delete()
          .eq('id', id)
          .select('id');
      if (deleted.isEmpty) {
        throw const AppException(
          'La plataforma ya no existe o no tienes permiso para eliminarla.',
        );
      }
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos eliminar la plataforma. Inténtalo de nuevo.',
          operation: ErrorOperation.deletePlatform,
        ),
      );
    }
  }

  Future<JsonMap> updatePlataforma(
    int id, {
    required String nombre,
    required String fabricante,
    required String formato,
  }) async {
    if (currentUser == null) {
      throw const AppException('Vuelve a iniciar sesión para continuar.');
    }
    try {
      // El servidor renombra también los juegos en una sola transacción.
      final result = await _client.rpc(
        'editar_plataforma',
        params: {
          'p_id': id,
          'p_nombre': nombre,
          'p_fabricante': fabricante,
          'p_formato': formato,
        },
      );
      if (result is! Map<String, dynamic> || result['id'] != id) {
        throw const AppException(
          'No pudimos confirmar los cambios. Actualiza la lista antes de volver a intentarlo.',
        );
      }
      return result;
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST202' || error.code == '42883') {
        throw const AppException(
          'La edición de plataformas todavía no está disponible. Contacta al administrador.',
        );
      }
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos actualizar la plataforma. Inténtalo de nuevo.',
        ),
      );
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos actualizar la plataforma. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<String> uploadImage({
    required String localPath,
    required String prefix,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        throw const AppException('Vuelve a iniciar sesión para continuar.');
      }

      final file = File(localPath);
      if (!await file.exists()) {
        throw const AppException('No se encontró la imagen seleccionada.');
      }

      final extension = localPath.contains('.')
          ? localPath.split('.').last.toLowerCase()
          : 'jpg';
      final fileName =
          '$prefix-$userId-${DateTime.now().millisecondsSinceEpoch}.$extension';
      final storagePath = 'public/$fileName';

      await _client.storage
          .from('avatars')
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from('avatars').getPublicUrl(storagePath);
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos subir la imagen. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(data: {'avatar_url': avatarUrl}),
      );
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback:
              'No pudimos actualizar la foto de perfil. Inténtalo de nuevo.',
        ),
      );
    }
  }

  // --- Cuenta de Usuario ---
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos cambiar la contraseña. Inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _client.rpc('delete_user');
      await _client.auth.signOut();
    } catch (error) {
      throw AppException(
        userMessage(
          error,
          fallback: 'No pudimos eliminar la cuenta. Inténtalo de nuevo.',
        ),
      );
    }
  }
}
