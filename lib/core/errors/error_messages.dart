import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

enum ErrorOperation { general, signUp, deletePlatform, deleteGame }

/// Traduce errores conocidos; los desconocidos usan un texto local, nunca
/// error.toString(). Supabase puede envolver errores de red en AuthException.
String userMessage(
  Object error, {
  String fallback = 'No pudimos completar la acción. Inténtalo de nuevo.',
  ErrorOperation operation = ErrorOperation.general,
}) {
  if (error is AppException) return error.message;

  final raw = error.toString().toLowerCase();
  final code = error is AuthException
      ? error.code
      : error is PostgrestException
      ? error.code
      : null;
  final status = error is AuthException
      ? int.tryParse(error.statusCode ?? '')
      : error is StorageException
      ? int.tryParse(error.statusCode ?? '')
      : error is PostgrestException
      ? int.tryParse(error.code ?? '')
      : null;

  if (error is TimeoutException ||
      status == 408 ||
      status == 504 ||
      raw.contains('timed out') ||
      raw.contains('timeoutexception')) {
    return 'La conexión está tardando demasiado. Inténtalo de nuevo.';
  }
  if (error is SocketException ||
      raw.contains('socketexception') ||
      raw.contains('failed host lookup') ||
      raw.contains('failed to fetch') ||
      raw.contains('network is unreachable') ||
      raw.contains('connection refused') ||
      raw.contains('connection reset') ||
      raw.contains('clientexception')) {
    return 'No pudimos conectarnos. Revisa tu conexión a internet e inténtalo de nuevo.';
  }

  if (code == 'invalid_credentials' ||
      raw.contains('invalid login credentials')) {
    return 'El correo o la contraseña son incorrectos. Revisa tus datos.';
  }
  if (code == 'email_not_confirmed' || raw.contains('email not confirmed')) {
    return 'Confirma tu correo electrónico antes de iniciar sesión. Revisa también la carpeta de spam.';
  }
  if (code == 'user_already_exists' || code == 'email_exists') {
    return 'Ya existe una cuenta con ese correo. Inicia sesión o usa otro correo.';
  }
  if (code == 'weak_password' || error is AuthWeakPasswordException) {
    return 'La contraseña es demasiado débil. Usa una más larga que combine letras, números y símbolos.';
  }
  if (code == 'same_password') {
    return 'Elige una contraseña diferente a la que usas actualmente.';
  }
  if (status == 429 ||
      code == 'over_request_rate_limit' ||
      code == 'over_email_send_rate_limit') {
    return 'Has realizado demasiados intentos. Espera unos minutos y vuelve a intentarlo.';
  }
  if (error is AuthSessionMissingException ||
      status == 401 ||
      {
        'session_expired',
        'session_not_found',
        'refresh_token_not_found',
        'refresh_token_already_used',
        'bad_jwt',
        'PGRST301',
        'PGRST302',
      }.contains(code)) {
    return 'Tu sesión ha vencido. Vuelve a iniciar sesión para continuar.';
  }
  if (code == 'signup_disabled' || code == 'email_provider_disabled') {
    return 'El registro de cuentas no está disponible en este momento. Inténtalo más tarde.';
  }
  if (code == 'email_address_invalid') {
    return 'Ese correo no es válido para registrarse. Revisa la dirección o utiliza otro correo.';
  }
  if (operation == ErrorOperation.signUp &&
      raw.contains('database error saving new user')) {
    return 'No se pudo crear la cuenta. Prueba con otro nombre de usuario. Si el problema continúa, contacta al administrador.';
  }
  if (status == 403 || code == '42501') {
    return 'No tienes permiso para realizar esta acción.';
  }
  if (code == '23505') {
    return 'Ya existe un registro con esos datos. Revisa la información e inténtalo de nuevo.';
  }
  if (code == '23503') {
    if (operation == ErrorOperation.deletePlatform) {
      return 'No puedes eliminar esta plataforma porque tiene sesiones asociadas.';
    }
    if (operation == ErrorOperation.deleteGame) {
      return 'No puedes eliminar este juego porque tiene datos asociados.';
    }
    return 'El juego o la plataforma ya no está disponible. Actualiza la lista e inténtalo de nuevo.';
  }
  if ({'23502', '23514', '22001', '22P02'}.contains(code)) {
    return 'Hay datos incompletos o no válidos. Revisa el formulario e inténtalo de nuevo.';
  }
  if (code == 'PGRST116') {
    return 'No encontramos ese registro. Actualiza la lista e inténtalo de nuevo.';
  }
  if (status == 413) {
    return 'La imagen es demasiado grande. Selecciona una más pequeña.';
  }
  if (error is PlatformException &&
      {
        'photo_access_denied',
        'camera_access_denied',
        'storage_access_denied',
        'photo_access_restricted',
        'camera_access_restricted',
      }.contains(error.code.toLowerCase())) {
    return 'Permite el acceso a tus fotos en los ajustes del teléfono para seleccionar una imagen.';
  }
  if (error is FileSystemException) {
    return 'No pudimos abrir la imagen. Selecciónala de nuevo.';
  }
  if (status != null && status >= 500 && status <= 599) {
    return 'El servicio no está disponible en este momento. Inténtalo más tarde.';
  }
  return fallback;
}
