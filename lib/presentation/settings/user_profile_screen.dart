import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/errors/error_messages.dart';

import '../auth/auth_view_model.dart';
import 'settings_view_model.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Future<void> _cambiarFotoPerfil() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) return;
      if (!mounted) return;

      final settingsVm = context.read<SettingsViewModel>();
      final updated = await settingsVm.actualizarAvatar(pickedFile.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated
                ? 'Foto de perfil actualizada con éxito'
                : settingsVm.errorMessage ?? 'No se pudo actualizar la foto',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userMessage(
              error,
              fallback: 'No pudimos seleccionar la foto. Inténtalo de nuevo.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _eliminarCuenta(BuildContext context) async {
    final settingsVm = context.read<SettingsViewModel>();
    final deleted = await settingsVm.eliminarCuenta();
    if (!context.mounted) return;

    if (deleted) {
      context.read<AuthViewModel>().notifyProfileChanged();
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta eliminada permanentemente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settingsVm.errorMessage ?? 'No se pudo eliminar la cuenta',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final authVm = context.read<AuthViewModel>();
    final avatarUrl = settingsVm.userAvatarUrl;
    final isDark = settingsVm.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0D0C14) : Colors.grey.shade100;
    final appBarBg = isDark ? const Color(0xFF171622) : Colors.white;
    final cardBg = isDark ? const Color(0xFF181624) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Theme(
      data: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C5CFF),
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: appBarBg,
          title: Text('Perfil de Usuario', style: TextStyle(color: textColor)),
          iconTheme: IconThemeData(color: textColor),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // --- Foto de perfil interactiva ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF7C5CFF),
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  if (settingsVm.isLoading)
                    const Positioned.fill(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: settingsVm.isLoading ? null : _cambiarFotoPerfil,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C5CFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                settingsVm.username ?? 'Usuario Activo',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                settingsVm.userEmail ?? 'correo@gpu.com',
                style: TextStyle(color: subtextColor, fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),

            // --- Información de la Cuenta ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? []
                    : [
                        const BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información de la Cuenta',
                    style: TextStyle(
                      color: Color(0xFF7C5CFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Correo Electrónico (Fijo)',
                      style: TextStyle(color: subtextColor, fontSize: 12),
                    ),
                    subtitle: Text(
                      settingsVm.userEmail ?? 'correo@gpu.com',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Seguridad y Acciones ---
            const Text(
              'Seguridad y Acciones',
              style: TextStyle(
                color: Color(0xFF7C5CFF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF282538)
                    : Colors.white,
                foregroundColor: textColor,
                elevation: isDark ? 0 : 1,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => _mostrarDialogoCambiarPassword(context, isDark),
              icon: const Icon(Icons.lock_reset),
              label: const Text('Cambiar contraseña'),
            ),
            const SizedBox(height: 12),

            // --- BOTÓN CERRAR SESIÓN CON ADVERTENCIA ---
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () =>
                  _mostrarDialogoConfirmarCerrarSesion(context, authVm, isDark),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
            ),
            const SizedBox(height: 12),

            // --- BOTÓN ELIMINAR CUENTA ---
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  _mostrarDialogoConfirmarEliminar(context, isDark),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Eliminar cuenta'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoCambiarPassword(BuildContext context, bool isDark) {
    final passCtrl = TextEditingController();
    final settingsVm = context.read<SettingsViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1826) : Colors.white,
        title: Text(
          'Cambiar Contraseña',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Nueva contraseña (mín. 6 caracteres)',
            labelStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passCtrl.text.length < 6) return;
              Navigator.pop(ctx);
              final ok = await settingsVm.cambiarContrasena(passCtrl.text);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Contraseña actualizada con éxito'
                        : settingsVm.errorMessage ?? 'No pudimos cambiar la contraseña. Inténtalo de nuevo.',
                  ),
                ),
              );
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  // --- DIÁLOGO DE ADVERTENCIA PARA CERRAR SESIÓN ---
  void _mostrarDialogoConfirmarCerrarSesion(
    BuildContext context,
    AuthViewModel authVm,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1826) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.orangeAccent, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¿Cerrar sesión?',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas salir de tu cuenta? Tendrás que volver a iniciar sesión para ver tu colección.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final signedOut = await authVm.signOut();
              if (!context.mounted) return;
              if (signedOut) {
                context.go('/login');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      authVm.errorMessage ??
                          'No pudimos cerrar sesión. Inténtalo de nuevo.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Sí, salir'),
          ),
        ],
      ),
    );
  }

  // --- DIÁLOGO DE ADVERTENCIA PARA ELIMINAR CUENTA ---
  void _mostrarDialogoConfirmarEliminar(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1826) : Colors.white,
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¿Eliminar cuenta?',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Esta acción es irreversible. Se eliminarán permanentemente tu perfil, tus videojuegos, tus sesiones registradas y tus plataformas personalizadas.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _eliminarCuenta(context);
            },
            child: const Text('Sí, eliminar cuenta'),
          ),
        ],
      ),
    );
  }
}
