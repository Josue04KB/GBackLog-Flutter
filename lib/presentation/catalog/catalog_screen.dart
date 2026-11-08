import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/auth_view_model.dart';
import '../widgets/ui_state.dart';
import 'catalog_view_model.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogViewModel>().cargarMaestros();
    });
  }

  Future<void> _mostrarDialogoNuevoJuego() async {
    final tituloCtrl = TextEditingController();
    final generoCtrl = TextEditingController();
    String estadoSeleccionado = 'Pendiente';

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo Videojuego (Maestro 2)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloCtrl,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: generoCtrl,
                      decoration: const InputDecoration(labelText: 'Género'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      value: estadoSeleccionado,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                        DropdownMenuItem(value: 'Jugando', child: Text('Jugando')),
                        DropdownMenuItem(value: 'Completado', child: Text('Completado')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => estadoSeleccionado = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (tituloCtrl.text.trim().isEmpty || generoCtrl.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.of(dialogCtx).pop();
                    final ok = await context.read<CatalogViewModel>().agregarVideojuego(
                          titulo: tituloCtrl.text,
                          genero: generoCtrl.text,
                          estado: estadoSeleccionado,
                        );
                    if (!mounted) return;
                    if (!ok) {
                      final err = context.read<CatalogViewModel>().errorMessage;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(err ?? 'Error al guardar')),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogVm = context.watch<CatalogViewModel>();
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Catálogo Maestro'),
            if (authVm.userEmail != null)
              Text(
                authVm.userEmail!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ver todas las sesiones (Transacciones)',
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/sesiones'),
          ),
          IconButton(
            tooltip: 'Recargar datos de Supabase',
            icon: const Icon(Icons.refresh),
            onPressed: () => catalogVm.cargarMaestros(),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authVm.signOut();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: _buildBody(catalogVm),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Agregar nuevo videojuego al catálogo',
        onPressed: _mostrarDialogoNuevoJuego,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Juego'),
      ),
    );
  }

  Widget _buildBody(CatalogViewModel vm) {
    switch (vm.state) {
      case ViewState.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Consultando entidades maestras en Supabase...'),
            ],
          ),
        );

      case ViewState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'Fallo de conexión con el servidor remoto',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  vm.errorMessage ?? 'Error desconocido',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => vm.cargarMaestros(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar conexión'),
                ),
              ],
            ),
          ),
        );

      case ViewState.empty:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No existen registros en las entidades maestras.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => vm.cargarMaestros(),
                child: const Text('Actualizar'),
              ),
            ],
          ),
        );

      case ViewState.success:
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildPlataformasSection(vm),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 3,
                    child: _buildVideojuegosSection(vm),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPlataformasHeader(),
                const SizedBox(height: 8),
                ...vm.plataformas.map(
                  (p) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.devices, color: Colors.indigo),
                      title: Text(p.nombre),
                      subtitle: Text('Fabricante: ${p.fabricante}'),
                      trailing: Chip(label: Text(p.formatoDefault)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildVideojuegosHeader(),
                const SizedBox(height: 8),
                ...vm.videojuegos.map((j) => _buildJuegoCard(j.id, j.titulo, j.genero, j.estado)),
                const SizedBox(height: 80),
              ],
            );
          },
        );
    }
  }

  Widget _buildPlataformasHeader() {
    return const Text(
      'Entidad Maestra 1: Plataformas Disponibles',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildVideojuegosHeader() {
    return const Text(
      'Entidad Maestra 2: Catálogo de Videojuegos',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPlataformasSection(CatalogViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPlataformasHeader(),
        const SizedBox(height: 8),
        ...vm.plataformas.map(
          (p) => Card(
            child: ListTile(
              leading: const Icon(Icons.devices, color: Colors.indigo),
              title: Text(p.nombre),
              subtitle: Text('Fabricante: ${p.fabricante}'),
              trailing: Chip(label: Text(p.formatoDefault)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideojuegosSection(CatalogViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildVideojuegosHeader(),
        const SizedBox(height: 8),
        ...vm.videojuegos.map((j) => _buildJuegoCard(j.id, j.titulo, j.genero, j.estado)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildJuegoCard(int id, String titulo, String genero, String estado) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.videogame_asset, color: Colors.deepPurple),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$genero • Estado: $estado'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          final encodedTitle = Uri.encodeComponent(titulo);
          context.push('/sesiones?juegoId=$id&titulo=$encodedTitle');
        },
      ),
    );
  }
}