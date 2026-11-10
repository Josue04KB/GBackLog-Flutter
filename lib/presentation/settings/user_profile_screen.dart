import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/errors/error_messages.dart';
import '../auth/auth_view_model.dart';
import 'profile_action_dialog.dart';
import 'settings_view_model.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const _accent = Color(0xFF7C5CFF);
  bool _changingPhoto = false;

  Future<void> _cambiarFotoPerfil() async {
    if (_changingPhoto) return;
    setState(() => _changingPhoto = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null || !mounted) return;
      final settings = context.read<SettingsViewModel>();
      final updated = await settings.actualizarAvatar(picked.path);
      if (!mounted) return;
      if (updated) context.read<AuthViewModel>().notifyProfileChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated
                ? 'Foto de perfil actualizada'
                : settings.errorMessage ?? 'No pudimos actualizar tu foto.',
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
    } finally {
      if (mounted) setState(() => _changingPhoto = false);
    }
  }

  Future<void> _showAction({
    required String title,
    required String description,
    required String confirmLabel,
    required IconData icon,
    required Future<String?> Function(String password) onConfirm,
    bool password = false,
    bool destructive = false,
    bool leavesAccount = false,
  }) async {
    final settings = context.read<SettingsViewModel>();
    final theme = _theme(settings.isDarkMode);
    final messenger = ScaffoldMessenger.of(context);
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Theme(
        data: theme,
        child: ProfileActionDialog(
          title: title,
          description: description,
          confirmLabel: confirmLabel,
          icon: icon,
          asksForPassword: password,
          destructive: destructive,
          onConfirm: onConfirm,
        ),
      ),
    );
    if (completed != true || !mounted) return;
    if (leavesAccount) {
      context.read<AuthViewModel>().notifyProfileChanged();
      context.go('/login');
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada con éxito')),
      );
    }
  }

  ThemeData _theme(bool dark) => ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: dark ? Brightness.dark : Brightness.light,
    ),
    useMaterial3: true,
  );

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final auth = context.watch<AuthViewModel>();
    final dark = settings.isDarkMode;
    final busy = settings.isLoading || auth.isLoading || _changingPhoto;
    final background = dark ? const Color(0xFF0D0C14) : const Color(0xFFF5F3FA);
    final surface = dark ? const Color(0xFF181624) : Colors.white;
    final border = dark ? const Color(0xFF302B42) : const Color(0xFFE4DEF0);
    final foreground = dark ? Colors.white : const Color(0xFF211D35);
    final secondary = dark ? const Color(0xFFADA6BE) : const Color(0xFF716980);
    final highlight = dark ? const Color(0xFFB6A5FF) : const Color(0xFF6744D8);
    final danger = dark ? const Color(0xFFFF9AA6) : const Color(0xFFB3263A);
    final avatar = settings.userAvatarUrl;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(left: 4, top: 26, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: secondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );

    Widget action({
      required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap,
      bool dangerAction = false,
    }) {
      final color = dangerAction ? danger : highlight;
      return Material(
        color: dangerAction
            ? (dark ? const Color(0xFF21151F) : const Color(0xFFFFF5F6))
            : surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: dangerAction ? color.withValues(alpha: 0.22) : border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: dangerAction ? danger : foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: secondary, size: 22),
              ],
            ),
          ),
        ),
      );
    }

    return Theme(
      data: _theme(dark),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Mi perfil',
            style: TextStyle(color: foreground, fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: foreground),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: dark
                            ? [
                                const Color(0xFF30234F),
                                const Color(0xFF1B182A),
                                surface,
                              ]
                            : [
                                const Color(0xFFEDE5FF),
                                const Color(0xFFF7F3FF),
                                Colors.white,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: border),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sports_esports_outlined,
                              color: highlight,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'GAMEBACKLOG',
                              style: TextStyle(
                                color: highlight,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: highlight.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              child: _changingPhoto
                                  ? ColoredBox(
                                      color: surface,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      ),
                                    )
                                  : avatar != null && avatar.isNotEmpty
                                  ? Image.network(
                                      avatar,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          _avatarFallback(),
                                    )
                                  : _avatarFallback(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          settings.username ?? 'Mi cuenta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          settings.userEmail ?? 'Correo no disponible',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: busy ? null : _cambiarFotoPerfil,
                          icon: const Icon(
                            Icons.add_a_photo_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _changingPhoto
                                ? 'Actualizando foto…'
                                : 'Cambiar foto',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: highlight,
                            side: BorderSide(
                              color: highlight.withValues(alpha: 0.35),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  section('SEGURIDAD'),
                  action(
                    title: 'Cambiar contraseña',
                    subtitle: 'Actualiza tu clave de acceso.',
                    icon: Icons.lock_outline_rounded,
                    onTap: () => _showAction(
                      title: 'Cambiar contraseña',
                      description:
                          'Elige una nueva clave para proteger tu cuenta.',
                      confirmLabel: 'Guardar contraseña',
                      icon: Icons.lock_reset_rounded,
                      password: true,
                      onConfirm: (value) async {
                        final ok = await settings.cambiarContrasena(value);
                        return ok
                            ? null
                            : settings.errorMessage ??
                                  'No pudimos cambiar la contraseña.';
                      },
                    ),
                  ),
                  section('TU SESIÓN'),
                  action(
                    title: 'Cerrar sesión',
                    subtitle: 'Podrás volver a entrar cuando quieras.',
                    icon: Icons.logout_rounded,
                    onTap: () => _showAction(
                      title: '¿Cerrar sesión?',
                      description: 'Tendrás que iniciar sesión de nuevo para ver tu colección.',
                      confirmLabel: 'Sí, salir',
                      icon: Icons.logout_rounded,
                      leavesAccount: true,
                      onConfirm: (_) async {
                        final ok = await auth.signOut();
                        return ok
                            ? null
                            : auth.errorMessage ?? 'No pudimos cerrar sesión.';
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  action(
                    title: 'Eliminar cuenta',
                    subtitle: 'Borra permanentemente tu cuenta y tus datos.',
                    icon: Icons.delete_outline_rounded,
                    dangerAction: true,
                    onTap: () => _showAction(
                      title: '¿Eliminar cuenta?',
                      description: 'Se eliminarán permanentemente tu perfil, tus videojuegos, tus sesiones registradas y tus plataformas personalizadas. Esta acción no se puede deshacer.',
                      confirmLabel: 'Sí, eliminar cuenta',
                      icon: Icons.delete_forever_outlined,
                      destructive: true,
                      leavesAccount: true,
                      onConfirm: (_) async {
                        final ok = await settings.eliminarCuenta();
                        return ok
                            ? null
                            : settings.errorMessage ??
                                  'No pudimos eliminar la cuenta.';
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback() => const ColoredBox(
    color: _accent,
    child: Icon(Icons.person_rounded, color: Colors.white, size: 58),
  );
}
