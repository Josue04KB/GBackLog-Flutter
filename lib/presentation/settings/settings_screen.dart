import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../catalog/catalog_view_model.dart';
import 'settings_view_model.dart';
import 'platform_form_sheet.dart';
import '../../domain/models/game_models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final catalogVm = context.watch<CatalogViewModel>();
    final avatarUrl = settingsVm.userAvatarUrl;

    final brightness = settingsVm.isDarkMode
        ? Brightness.dark
        : Brightness.light;

    final bgColor = settingsVm.isDarkMode
        ? const Color(0xFF0D0C14)
        : Colors.grey.shade100;
    final appBarBg = settingsVm.isDarkMode
        ? const Color(0xFF171622)
        : Colors.white;
    final cardBg = settingsVm.isDarkMode
        ? const Color(0xFF181624)
        : Colors.white;
    final textColor = settingsVm.isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = settingsVm.isDarkMode
        ? Colors.white54
        : Colors.grey.shade600;

    return Theme(
      data: ThemeData(
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C5CFF),
          brightness: brightness,
        ),
        useMaterial3: true,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: appBarBg,
          title: Text('Configuración', style: TextStyle(color: textColor)),
          iconTheme: IconThemeData(color: textColor),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- SECCIÓN 1: PERFIL DE USUARIO ---
            const Text(
              'Perfil de Usuario',
              style: TextStyle(
                color: Color(0xFF7C5CFF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                await context.push('/perfil');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: settingsVm.isDarkMode
                      ? []
                      : [
                          const BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF7C5CFF),
                      backgroundImage:
                          (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settingsVm.username ?? 'Usuario Activo',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            settingsVm.userEmail ?? 'correo@gpu.com',
                            style: TextStyle(color: subtextColor, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- SECCIÓN 2: TEMA VISUAL ---
            const Text(
              'Apariencia',
              style: TextStyle(
                color: Color(0xFF7C5CFF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              secondary: const Icon(
                Icons.brightness_6_outlined,
                color: Color(0xFF7C5CFF),
                size: 26,
              ),
              title: Text(
                'Tema de la aplicación',
                style: TextStyle(color: textColor),
              ),
              subtitle: Text(
                settingsVm.isDarkMode
                    ? 'Tema oscuro activado'
                    : 'Tema claro activado',
                style: TextStyle(color: subtextColor),
              ),
              value: settingsVm.isDarkMode,
              activeThumbColor: const Color(0xFF7C5CFF),
              onChanged: (val) {
                settingsVm.toggleTheme(val);
                setState(() {});
              },
            ),
            const SizedBox(height: 24),

            // --- SECCIÓN 3: GESTIÓN DE PLATAFORMAS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Plataformas Maestras',
                  style: TextStyle(
                    color: Color(0xFF7C5CFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _mostrarFormularioPlataforma(
                    context,
                    settingsVm.isDarkMode,
                  ),
                  icon: const Icon(Icons.add, color: Color(0xFF7C5CFF)),
                  label: const Text(
                    'Agregar',
                    style: TextStyle(color: Color(0xFF7C5CFF)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...catalogVm.plataformas.map(
              (p) => Card(
                color: cardBg,
                margin: const EdgeInsets.only(bottom: 8),
                elevation: settingsVm.isDarkMode ? 1 : 2,
                child: ListTile(
                  leading: IconButton(
                    tooltip: 'Editar ${p.nombre}',
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF7C5CFF),
                    ),
                    onPressed: () => _mostrarFormularioPlataforma(
                      context,
                      settingsVm.isDarkMode,
                      plataforma: p,
                    ),
                  ),
                  title: Text(
                    p.nombre,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Fabricante: ${p.fabricante} • ${p.formatoDefault}',
                    style: TextStyle(color: subtextColor),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _mostrarDialogoConfirmarBorrarPlataforma(
                      context,
                      p.id,
                      p.nombre,
                      settingsVm.isDarkMode,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIÁLOGO DE ADVERTENCIA PARA ELIMINAR PLATAFORMA ---
  Future<void> _mostrarDialogoConfirmarBorrarPlataforma(
    BuildContext context,
    int plataformaId,
    String nombrePlataforma,
    bool isDark,
  ) async {
    final settingsVm = context.read<SettingsViewModel>();
    final catalogVm = context.read<CatalogViewModel>();

    final shouldDelete = await showDialog<bool>(
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
                '¿Eliminar plataforma?',
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
          '¿Estás seguro de que deseas eliminar la plataforma "$nombrePlataforma"? Esta acción no se puede deshacer.',
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
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;
    await Future<void>.delayed(kThemeAnimationDuration);
    if (!mounted) return;

    final eliminada = await settingsVm.borrarPlataforma(plataformaId);
    if (!mounted) return;

    if (eliminada) {
      await catalogVm.cargarMaestros();
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Plataforma "$nombrePlataforma" eliminada')),
      );
    } else {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(
            settingsVm.errorMessage ??
                'No se pudo eliminar la plataforma. Reintenta.',
          ),
        ),
      );
    }
  }

  Future<void> _mostrarFormularioPlataforma(
    BuildContext context,
    bool isDark, {
    Plataforma? plataforma,
  }) async {
    final settingsVm = context.read<SettingsViewModel>();
    final catalogVm = context.read<CatalogViewModel>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => Theme(
        data: ThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7C5CFF),
            brightness: isDark ? Brightness.dark : Brightness.light,
          ),
          useMaterial3: true,
        ),
        child: PlatformFormSheet(
          initial: plataforma,
          onSave: (draft) async {
            final ok = plataforma == null
                ? await settingsVm.agregarPlataforma(
                    nombre: draft.nombre,
                    fabricante: draft.fabricante,
                    formato: draft.formato,
                  )
                : await settingsVm.editarPlataforma(
                    id: plataforma.id,
                    nombre: draft.nombre,
                    fabricante: draft.fabricante,
                    formato: draft.formato,
                  );
            return ok
                ? null
                : settingsVm.errorMessage ??
                      'No pudimos guardar la plataforma. Inténtalo de nuevo.';
          },
        ),
      ),
    );
    if (saved != true || !mounted) return;
    final refreshed = await catalogVm.cargarMaestros();
    if (!mounted) return;
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(
          refreshed
              ? plataforma == null
                    ? 'Plataforma creada'
                    : 'Plataforma actualizada'
              : 'Plataforma guardada. No pudimos actualizar la lista. Vuelve a abrir Configuración.',
        ),
      ),
    );
  }
}
