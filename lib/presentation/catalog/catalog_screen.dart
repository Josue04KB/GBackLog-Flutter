import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/models/game_models.dart';
import '../auth/auth_view_model.dart';
import '../widgets/ui_state.dart';
import 'catalog_view_model.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const List<String> _filtros = [
    'Todos',
    'En progreso',
    'Pendiente',
    'Completado',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogViewModel>().cargarMaestros();
    });
  }

  Color _colorPorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return const Color(0xFFFFA726); // Naranja
      case 'Completado':
        return const Color(0xFF7986CB); // Azul violáceo
      case 'En progreso':
      case 'Jugando':
        return const Color(0xFF26A69A); // Verde esmeralda
      default:
        return Colors.grey;
    }
  }

  String _portadaPorDefecto(String titulo) {
    final lower = titulo.toLowerCase();
    if (lower.contains('elden')) {
      return 'https://image.api.playstation.com/vulcan/ap/rnd/202110/2000/phvVT0qZfcRms5qDAk0SI3CM.png';
    } else if (lower.contains('cyberpunk')) {
      return 'https://cdn.cloudflare.steamstatic.com/steam/apps/1091500/library_600x900_2x.jpg';
    } else if (lower.contains('zelda')) {
      return 'https://assets.nintendo.com/image/upload/c_fill,w_1200/q_auto:best/f_auto/dpr_2.0/ncom/software/switch/70010000063714/276a412988e07c4d55a2996c6d38abb408b464413b2dfeb44d2aa460b9f622e1';
    } else if (lower.contains('pokémon') || lower.contains('pokemon')) {
      return 'https://assets.nintendo.com/image/upload/c_fill,w_1200/q_auto:best/f_auto/dpr_2.0/ncom/software/switch/70010000039955/f7abdc63003702446f4f2ef917a1f732d63c20b706d86e51c6c656c3b6593334';
    }
    return 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600&q=80';
  }

  void _mostrarOpcionesYPlataformas() {
    final catalogVm = context.read<CatalogViewModel>();
    final authVm = context.read<AuthViewModel>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1826),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Configuración y Plataformas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Recargar datos de Supabase',
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      catalogVm.cargarMaestros();
                    },
                  ),
                ],
              ),
              if (authVm.userEmail != null)
                Text(
                  'Sesión activa: ${authVm.userEmail}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              const SizedBox(height: 16),
              const Text(
                'Plataformas registradas (Entidad Maestra 1):',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: catalogVm.plataformas
                    .map(
                      (p) => Chip(
                        backgroundColor: const Color(0xFF282538),
                        label: Text(
                          '${p.nombre} (${p.fabricante})',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, color: Color(0xFF7C5CFF)),
                title: const Text(
                  'Historial general de sesiones (Transacciones)',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  context.push('/sesiones');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  await authVm.signOut();
                  if (!mounted) return;
                  context.go('/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _mostrarDialogoNuevoJuego() async {
    final catalogVm = context.read<CatalogViewModel>();
    final tituloCtrl = TextEditingController();
    final generoCtrl = TextEditingController();
    final imagenCtrl = TextEditingController();
    String estadoSeleccionado = 'Pendiente';
    String plataformaSeleccionada = catalogVm.plataformas.isNotEmpty
        ? catalogVm.plataformas.first.nombre
        : 'PS5';

    final opcionesPlataforma = catalogVm.plataformas.isNotEmpty
        ? catalogVm.plataformas.map((e) => e.nombre).toList()
        : ['PS5', 'PC', 'Switch', 'Emulador'];

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1826),
              title: const Text(
                'Agregar a Mi Colección',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Título del videojuego',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: generoCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Género',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: plataformaSeleccionada,
                      dropdownColor: const Color(0xFF282538),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Plataforma',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      items: opcionesPlataforma
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => plataformaSeleccionada = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: estadoSeleccionado,
                      dropdownColor: const Color(0xFF282538),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                        DropdownMenuItem(value: 'En progreso', child: Text('En progreso')),
                        DropdownMenuItem(value: 'Completado', child: Text('Completado')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => estadoSeleccionado = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imagenCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'URL de portada (opcional)',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C5CFF),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (tituloCtrl.text.trim().isEmpty) return;
                    Navigator.of(dialogCtx).pop();
                    final ok = await catalogVm.agregarVideojuego(
                      titulo: tituloCtrl.text,
                      genero: generoCtrl.text.isEmpty ? 'General' : generoCtrl.text,
                      estado: estadoSeleccionado,
                      plataforma: plataformaSeleccionada,
                      imagenUrl: imagenCtrl.text,
                    );
                    if (!mounted) return;
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(catalogVm.errorMessage ?? 'Error al guardar')),
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

    return Scaffold(
      backgroundColor: const Color(0xFF0D0C14),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Encabezado idéntico a Android Studio: ★ Mi Colección + ⚙ ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFF7C5CFF), size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Mi Colección',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Opciones, Plataformas y Sesión',
                    icon: const Icon(Icons.settings, color: Colors.white, size: 26),
                    onPressed: _mostrarOpcionesYPlataformas,
                  ),
                ],
              ),
            ),

            // --- Subtítulo: X juegos en tu colección ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${catalogVm.videojuegos.length} juegos en tu colección',
                style: const TextStyle(color: Color(0xFF9E9EAB), fontSize: 15),
              ),
            ),
            const SizedBox(height: 16),

            // --- Barra de filtros horizontales (Todos, En progreso, Pendiente, Completado) ---
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filtros.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final filtro = _filtros[index];
                  final seleccionado = catalogVm.filtroEstado == filtro;
                  return GestureDetector(
                    onTap: () => catalogVm.cambiarFiltro(filtro),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: seleccionado
                            ? const Color(0xFF7C5CFF)
                            : const Color(0xFF171622),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: seleccionado
                              ? const Color(0xFF7C5CFF)
                              : const Color(0xFF343246),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filtro,
                        style: TextStyle(
                          color: seleccionado ? Colors.white : const Color(0xFFB0B0C0),
                          fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // --- Cuerpo con los 4 estados (Loading, Error, Empty, Grid Success) ---
            Expanded(
              child: _buildBody(catalogVm),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 58,
        height: 58,
        child: FloatingActionButton(
          tooltip: 'Agregar videojuego',
          backgroundColor: const Color(0xFF7C5CFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onPressed: _mostrarDialogoNuevoJuego,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildBody(CatalogViewModel vm) {
    switch (vm.state) {
      case ViewState.loading:
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
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
                const Text(
                  'Sin conexión con Supabase',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vm.errorMessage ?? 'Verifica tu conexión a internet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C5CFF),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => vm.cargarMaestros(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );

      case ViewState.empty:
        return const Center(
          child: Text(
            'No hay juegos en tu colección.',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
        );

      case ViewState.success:
        final lista = vm.videojuegosFiltrados;
        if (lista.isEmpty) {
          return const Center(
            child: Text(
              'No hay juegos en este estado.',
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemCount: lista.length,
              itemBuilder: (context, index) {
                return _buildGameCard(lista[index], vm);
              },
            );
          },
        );
    }
  }

  Widget _buildGameCard(Videojuego juego, CatalogViewModel vm) {
    final imageUrl = (juego.imagenUrl != null && juego.imagenUrl!.isNotEmpty)
        ? juego.imagenUrl!
        : _portadaPorDefecto(juego.titulo);
    final statusColor = _colorPorEstado(juego.estado);

    return GestureDetector(
      onTap: () {
        final encodedTitle = Uri.encodeComponent(juego.titulo);
        context.push('/sesiones?juegoId=${juego.id}&titulo=$encodedTitle');
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181624),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Portada con etiqueta de plataforma en la esquina superior derecha ---
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFF282538),
                        child: const Icon(
                          Icons.videogame_asset,
                          color: Colors.white38,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        juego.plataforma,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // --- Título del juego ---
            Text(
              juego.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // --- Punto de estado + Texto + Ícono de basurero ---
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    juego.estado,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => vm.borrarVideojuego(juego.id),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete,
                      color: Color(0xFF9E9EAB),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}