String? validarUsuario(String? value) {
  final username = value?.trim() ?? '';
  if (username.isEmpty) return 'Ingresa tu nombre de usuario';
  if (username.length < 3 || username.length > 30) {
    return 'El usuario debe tener entre 3 y 30 caracteres';
  }
  if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
    return 'Usa letras sin tildes, números, puntos o guiones bajos';
  }
  return null;
}
