import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/game_models.dart';
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

  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogViewModel>().cargarMaestros();
    });
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

  Color _colorPorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return const Color(0xFFFFA726);
      case 'Completado':
        return const Color(0xFF7986CB);
      case 'En progreso':
      case 'Jugando':
        return const Color(0xFF26A69A);
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

  // Diálogo de confirmación para eliminar juego
  Future<void> _mostrarDialogoConfirmarBorrarJuego(
    Videojuego juego,
    CatalogViewModel vm,
    bool isDark,
  ) async {
    final nombreJuego = juego.titulo;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1826) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¿Eliminar juego?',
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
            '¿Estás seguro de que deseas eliminar "$nombreJuego" de tu colección? Esta acción también borrará sus sesiones registradas y no se puede deshacer.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await vm.borrarVideojuego(juego.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$nombreJuego" fue eliminado de tu colección'),
                  ),
                );
              },
              child: const Text('Sí, eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogVm = context.watch<CatalogViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0D0C14) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? const Color(0xFF9E9EAB) : Colors.grey.shade600;
    final totalJuegos = catalogVm.videojuegos.length.toString();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Encabezado: Avatar + Mi Colección + Configuración ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await context.push('/perfil');
                      _cargarAvatar();
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF7C5CFF),
                      backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                          ? NetworkImage(_avatarUrl!)
                          : null,
                      child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 20, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mi Colección',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Configuración',
                    icon: Icon(Icons.settings, color: textColor, size: 26),
                    onPressed: () async {
                      await context.push('/config');
                      _cargarAvatar();
                    },
                  ),
                ],
              ),
            ),

            // --- Subtítulo con contador corregido ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '$totalJuegos juegos en tu colección',
                style: TextStyle(color: subtextColor, fontSize: 15),
              ),
            ),
            const SizedBox(height: 16),

            // --- Filtros horizontales ---
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
                            : (isDark ? const Color(0xFF171622) : Colors.white),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: seleccionado
                              ? const Color(0xFF7C5CFF)
                              : (isDark ? const Color(0xFF343246) : Colors.grey.shade300),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filtro,
                        style: TextStyle(
                          color: seleccionado
                              ? Colors.white
                              : (isDark ? const Color(0xFFB0B0C0) : Colors.black54),
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

            // --- Grid de juegos ---
            Expanded(
              child: _buildBody(catalogVm, isDark, textColor),
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
          onPressed: () => context.push('/agregar_catalogo'),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildBody(CatalogViewModel vm, bool isDark, Color textColor) {
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
                Text(
                  'Sin conexión con Supabase',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vm.errorMessage ?? 'Verifica tu conexión a internet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
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
        return Center(
          child: Text(
            'No hay juegos en tu colección.',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 16),
          ),
        );

      case ViewState.success:
        final lista = vm.videojuegosFiltrados;
        if (lista.isEmpty) {
          return Center(
            child: Text(
              'No hay juegos en este estado.',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 15),
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
                return _buildGameCard(lista[index], vm, isDark);
              },
            );
          },
        );
    }
  }

  Widget _buildGameCard(Videojuego juego, CatalogViewModel vm, bool isDark) {
    final imageUrl = (juego.imagenUrl != null && juego.imagenUrl!.isNotEmpty)
        ? juego.imagenUrl!
        : _portadaPorDefecto(juego.titulo);
    final statusColor = _colorPorEstado(juego.estado);

    return GestureDetector(
      onTap: () {
        final encodedTitle = Uri.encodeComponent(juego.titulo);
        final idJuego = juego.id.toString();
        context.push('/sesiones?juegoId=$idJuego&titulo=$encodedTitle');
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181624) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isDark ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        color: isDark ? const Color(0xFF282538) : Colors.grey.shade200,
                        child: Icon(
                          Icons.videogame_asset,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
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
            Text(
              juego.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
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
                  onTap: () => _mostrarDialogoConfirmarBorrarJuego(juego, vm, isDark),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete,
                      color: isDark ? const Color(0xFF9E9EAB) : Colors.grey,
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