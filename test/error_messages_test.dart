import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog_cloud/core/errors/app_exception.dart';
import 'package:gamebacklog_cloud/core/errors/error_messages.dart';
import 'package:gamebacklog_cloud/domain/repositories/game_repository.dart';
import 'package:gamebacklog_cloud/domain/use_cases/registrar_sesion_use_case.dart';
import 'package:gamebacklog_cloud/presentation/auth/auth_view_model.dart';
import 'package:gamebacklog_cloud/presentation/catalog/catalog_view_model.dart';
import 'package:gamebacklog_cloud/presentation/settings/settings_view_model.dart';
import 'package:gamebacklog_cloud/presentation/sessions/session_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FailingRepository implements GameRepository {
  Object failure = Exception('private URL/token and SQL details');
  @override
  dynamic noSuchMethod(Invocation invocation) => throw failure;
}

void main() {
  test(
    'reconoce red directa y envuelta por Auth sin mostrar URL ni códigos',
    () {
      for (final error in <Object>[
        const SocketException('Failed host lookup: private.example.com'),
        const AuthException(
          'ClientException with SocketException: Failed host lookup: private.example.com',
        ),
        const AuthException(
          'ClientException: Failed to fetch, uri=https://private.example.com',
        ),
      ]) {
        expect(
          userMessage(error),
          'No pudimos conectarnos. Revisa tu conexión a internet e inténtalo de nuevo.',
        );
      }
    },
  );

  test('errores conocidos explican cómo continuar sin detalles técnicos', () {
    final cases = <(Object, String)>[
      (TimeoutException('private URL'), 'tardando demasiado'),
      (
        const AuthException('private', code: 'invalid_credentials'),
        'correo o la contraseña',
      ),
      (
        const AuthException('private', code: 'email_not_confirmed'),
        'Confirma tu correo',
      ),
      (
        const AuthException('private', code: 'email_exists'),
        'Ya existe una cuenta',
      ),
      (
        const AuthException('private', code: 'weak_password'),
        'contraseña es demasiado débil',
      ),
      (
        const AuthException('private', code: 'same_password'),
        'contraseña diferente',
      ),
      (
        const AuthException('private', statusCode: '429'),
        'demasiados intentos',
      ),
      (
        const AuthException('private', code: 'session_expired'),
        'sesión ha vencido',
      ),
      (
        const PostgrestException(message: 'private', code: 'PGRST301'),
        'sesión ha vencido',
      ),
      (
        const PostgrestException(message: 'private', code: '42501'),
        'No tienes permiso',
      ),
      (
        const PostgrestException(message: 'private', code: '23505'),
        'Ya existe un registro',
      ),
      (
        const PostgrestException(message: 'private', code: '23514'),
        'datos incompletos o no válidos',
      ),
      (
        const PostgrestException(message: 'private', code: 'PGRST116'),
        'No encontramos ese registro',
      ),
      (
        const StorageException('private', statusCode: '413'),
        'imagen es demasiado grande',
      ),
      (
        const StorageException('private', statusCode: '403'),
        'No tienes permiso',
      ),
      (
        const AuthException('private', statusCode: '503'),
        'servicio no está disponible',
      ),
      (
        PlatformException(code: 'photo_access_denied', message: 'private'),
        'acceso a tus fotos',
      ),
      (
        const FileSystemException('private', '/private/path'),
        'abrir la imagen',
      ),
    ];
    for (final (error, expected) in cases) {
      expect(
        userMessage(error),
        contains(expected),
        reason: error.runtimeType.toString(),
      );
      expect(userMessage(error), isNot(contains('private')));
    }
  });

  test('dependencias indican qué no se puede eliminar', () {
    const error = PostgrestException(
      message: 'foreign key secret constraint',
      code: '23503',
    );
    expect(
      userMessage(error, operation: ErrorOperation.deletePlatform),
      contains('plataforma porque tiene sesiones asociadas'),
    );
    expect(
      userMessage(error, operation: ErrorOperation.deleteGame),
      contains('juego porque tiene datos asociados'),
    );
    expect(userMessage(error), contains('Actualiza la lista'));
  });

  test('solo los mensajes locales explícitos se conservan literalmente', () {
    expect(
      userMessage(
        const AppException('Las notas deben tener al menos 5 caracteres.'),
      ),
      'Las notas deben tener al menos 5 caracteres.',
    );
    for (final error in <Object>[
      Exception('SECRET URL https://private.example.com/token'),
      const AuthException('SECRET auth server response'),
      const PostgrestException(message: 'SECRET SQL query', code: '42703'),
      const StorageException('SECRET storage path'),
      StateError('SECRET stack trace'),
    ]) {
      expect(
        userMessage(error, fallback: 'No pudimos guardar los cambios.'),
        'No pudimos guardar los cambios.',
      );
    }
  });

  test(
    'los modelos de pantalla también protegen contra fallos inesperados',
    () async {
      final repo = _FailingRepository();
      final auth = AuthViewModel(repo);
      final catalog = CatalogViewModel(repo);
      final settings = SettingsViewModel(repo);
      final sessions = SessionViewModel(repo, RegistrarSesionUseCase(repo));
      addTearDown(auth.dispose);
      addTearDown(catalog.dispose);
      addTearDown(settings.dispose);
      addTearDown(sessions.dispose);

      expect(await auth.signIn('test@example.com', 'secret'), isFalse);
      expect(
        auth.errorMessage,
        'No pudimos iniciar sesión. Inténtalo de nuevo.',
      );
      expect(auth.isLoading, isFalse);
      expect(await auth.signOut(), isFalse);
      expect(
        auth.errorMessage,
        'No pudimos cerrar sesión. Inténtalo de nuevo.',
      );
      expect(auth.isLoading, isFalse);
      expect(await catalog.cargarMaestros(), isFalse);
      expect(
        catalog.errorMessage,
        'No pudimos cargar tu colección. Inténtalo de nuevo.',
      );
      expect(await settings.cambiarContrasena('new-password'), isFalse);
      expect(
        settings.errorMessage,
        'No pudimos cambiar la contraseña. Inténtalo de nuevo.',
      );
      expect(settings.isLoading, isFalse);
      expect(await sessions.eliminarSesion(1), isFalse);
      expect(
        sessions.errorMessage,
        'No pudimos guardar los cambios de la sesión. Inténtalo de nuevo.',
      );
      expect(sessions.isSubmitting, isFalse);

      repo.failure = const SocketException('private endpoint');
      expect(await settings.actualizarAvatar('image.png'), isFalse);
      expect(settings.errorMessage, contains('Revisa tu conexión a internet'));
      expect(
        await sessions.registrarNuevaSesion(
          videojuegoId: 1,
          plataformaId: 1,
          minutosJugados: 30,
          notas: 'Avance',
        ),
        isFalse,
      );
      expect(sessions.errorMessage, contains('Revisa tu conexión a internet'));
    },
  );
}
