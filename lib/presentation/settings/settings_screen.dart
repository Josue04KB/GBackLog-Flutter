import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../catalog/catalog_view_model.dart';
import 'settings_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _cargarAvatar();
  }

  void _cargarAvatar() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.userMetadata != null) {
      setState(() {
        _avatarUrl = user.userMetadata!['avatar_url'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final catalogVm = context.watch<CatalogViewModel>();

    final brightness = settingsVm.isDarkMode ? Brightness.dark : Brightness.light;

    final bgColor = settingsVm.isDarkMode ? const Color(0xFF0D0C14) : Colors.grey.shade100;
    final appBarBg = settingsVm.isDarkMode ? const Color(0xFF171622) : Colors.white;
    final cardBg = settingsVm.isDarkMode ? const Color(0xFF181624) : Colors.white;
    final textColor = settingsVm.isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = settingsVm.isDarkMode ? Colors.white54 : Colors.grey.shade600;

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
              style: TextStyle(color: Color(0xFF7C5CFF), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                await context.push('/perfil');
                _cargarAvatar();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: settingsVm.isDarkMode
                      ? []
                      : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF7C5CFF),
                      backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                          ? NetworkImage(_avatarUrl!)
                          : null,
                      child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 36, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Usuario Activo', style: TextStyle(color: subtextColor, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            settingsVm.userEmail ?? 'correo@gpu.com',
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
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
              style: TextStyle(color: Color(0xFF7C5CFF), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text('Modo Oscuro / Claro', style: TextStyle(color: textColor)),
              subtitle: Text(
                settingsVm.isDarkMode ? 'Tema oscuro activado' : 'Tema claro activado',
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
                  style: TextStyle(color: Color(0xFF7C5CFF), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton.icon(
                  onPressed: () => _mostrarDialogoCrearPlataforma(context, settingsVm.isDarkMode),
                  icon: const Icon(Icons.add, color: Color(0xFF7C5CFF)),
                  label: const Text('Agregar', style: TextStyle(color: Color(0xFF7C5CFF))),
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
                  leading: const Icon(Icons.devices, color: Color(0xFF7C5CFF)),
                  title: Text(p.nombre, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Fabricante: ${p.fabricante} • ${p.formatoDefault}',
                    style: TextStyle(color: subtextColor),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
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
  void _mostrarDialogoConfirmarBorrarPlataforma(
    BuildContext context,
    int plataformaId,
    String nombrePlataforma,
    bool isDark,
  ) {
    final settingsVm = context.read<SettingsViewModel>();
    final catalogVm = context.read<CatalogViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1826) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
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
            onPressed: () async {
              Navigator.pop(ctx);
              await settingsVm.borrarPlataforma(plataformaId);
              await catalogVm.cargarMaestros();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Plataforma "$nombrePlataforma" eliminada')),
              );
            },
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCrearPlataforma(BuildContext context, bool isDark) {
    final nombreCtrl = TextEditingController();
    final fabCtrl = TextEditingController();
    final formatoCtrl = TextEditingController();
    final settingsVm = context.read<SettingsViewModel>();
    final catalogVm = context.read<CatalogViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1826) : Colors.white,
        title: Text('Nueva Plataforma', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Nombre (ej. Xbox Series X)',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            TextField(
              controller: fabCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Fabricante (ej. Microsoft)',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            TextField(
              controller: formatoCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Formato (ej. Digital)',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              await settingsVm.agregarPlataforma(
                nombre: nombreCtrl.text,
                fabricante: fabCtrl.text,
                formato: formatoCtrl.text,
              );
              catalogVm.cargarMaestros();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}