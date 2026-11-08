import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/game_models.dart';
import '../catalog/catalog_view_model.dart';
import '../widgets/ui_state.dart';
import 'session_view_model.dart';

class SessionsScreen extends StatefulWidget {
  final int? filtroVideojuegoId;
  final String? videojuegoTitulo;

  const SessionsScreen({
    super.key,
    this.filtroVideojuegoId,
    this.videojuegoTitulo,
  });

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionViewModel>().cargarSesiones(
            videojuegoId: widget.filtroVideojuegoId,
          );
    });
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

  String _formatearTiempoTotal(int totalMinutos) {
    if (totalMinutos <= 0) return '0 min';
    final horas = totalMinutos ~/ 60;
    final minutos = totalMinutos % 60;
    if (horas == 0) return '$minutos min';
    if (minutos == 0) return '${horas}h';
    return '${horas}h ${minutos}m';
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha is DateTime) {
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha.toLocal());
    }
    if (fecha is String) {
      final parsed = DateTime.tryParse(fecha);
      if (parsed != null) {
        return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
      }
      return fecha;
    }
    return '';
  }

  Future<void> _abrirPantallaEditarJuego(
    BuildContext context,
    Videojuego? juegoActual,
    String tituloFallback,
    String imagenFallback,
  ) async {
    final juegoId = widget.filtroVideojuegoId;
    if (juegoId == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EditGameScreen(
          juegoId: juegoId,
          tituloInicial: juegoActual?.titulo ?? tituloFallback,
          estadoInicial: juegoActual?.estado ?? 'Pendiente',
          imagenInicial: (juegoActual?.imagenUrl != null &&
                  juegoActual!.imagenUrl!.isNotEmpty)
              ? juegoActual.imagenUrl!
              : imagenFallback,
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoConfirmarEliminar(
    BuildContext context,
    String tituloJuego,
    bool isDark,
  ) async {
    final juegoId = widget.filtroVideojuegoId;
    if (juegoId == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
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
                  '¿Eliminar de tu biblioteca?',
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
            '¿Estás seguro de que deseas eliminar "$tituloJuego" de tu colección? '
            'Se borrarán tus sesiones registradas, pero el juego seguirá disponible en el catálogo.',
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
                final catalogVm = context.read<CatalogViewModel>();
                await catalogVm.borrarVideojuego(juegoId);

                if (!context.mounted) return;
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$tituloJuego" fue eliminado de tu biblioteca'),
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

  Future<void> _mostrarDialogoNuevaSesion(
    bool isDark,
    Videojuego? juegoActual,
  ) async {
    final sessionVm = context.read<SessionViewModel>();
    final catalogVm = context.read<CatalogViewModel>();

    final minutosCtrl = TextEditingController();
    final notasCtrl = TextEditingController();

    final int? juegoSeleccionadoId = widget.filtroVideojuegoId ??
        (catalogVm.videojuegos.isNotEmpty ? catalogVm.videojuegos.first.id : null);

    int? plataformaSeleccionadaId;
    if (catalogVm.plataformas.isNotEmpty) {
      final coincidencia = catalogVm.plataformas.where(
        (p) =>
            p.nombre.toLowerCase() ==
            (juegoActual?.plataforma ?? '').toLowerCase(),
      );
      plataformaSeleccionadaId = coincidencia.isNotEmpty
          ? coincidencia.first.id
          : catalogVm.plataformas.first.id;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1A1826) : Colors.white,
              title: Text(
                'Registrar Sesión',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (catalogVm.plataformas.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        initialValue: plataformaSeleccionadaId,
                        dropdownColor:
                            isDark ? const Color(0xFF282538) : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Plataforma',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        items: catalogVm.plataformas
                            .map(
                              (p) => DropdownMenuItem<int>(
                                value: p.id,
                                child: Text(p.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => plataformaSeleccionadaId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: minutosCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Minutos jugados (> 0)',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notasCtrl,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Notas o progreso logrado',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
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
                    final mins = int.tryParse(minutosCtrl.text.trim()) ?? 0;
                    Navigator.of(dialogCtx).pop();

                    final ok = await sessionVm.registrarNuevaSesion(
                      videojuegoId: juegoSeleccionadoId,
                      plataformaId: plataformaSeleccionadaId,
                      minutosJugados: mins,
                      notas: notasCtrl.text.trim(),
                      filtroVideojuegoIdActual: widget.filtroVideojuegoId,
                    );

                    if (!mounted) return;
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            sessionVm.errorMessage ?? 'Error al registrar sesión',
                          ),
                        ),
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

  Widget _buildPosterImage(String imagePath, bool isDark) {
    final isUrl = imagePath.startsWith('http');
    if (isUrl) {
      return Image.network(
        imagePath,
        width: 105,
        height: 145,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackBox(isDark),
      );
    } else {
      return Image.file(
        File(imagePath),
        width: 105,
        height: 145,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackBox(isDark),
      );
    }
  }

  Widget _buildFallbackBox(bool isDark) {
    return Container(
      width: 105,
      height: 145,
      color: isDark ? const Color(0xFF282538) : Colors.grey.shade200,
      child: Icon(
        Icons.videogame_asset,
        color: isDark ? Colors.white38 : Colors.grey,
        size: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionVm = context.watch<SessionViewModel>();
    final catalogVm = context.watch<CatalogViewModel>(); // Escucha cambios globales del catálogo
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0D0C14) : Colors.grey.shade100;
    final cardBg = isDark ? const Color(0xFF181624) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    Videojuego? juegoActual;
    if (widget.filtroVideojuegoId != null) {
      for (final j in catalogVm.videojuegos) {
        if (j.id == widget.filtroVideojuegoId) {
          juegoActual = j;
          break;
        }
      }
    }

    final tituloMostrar =
        juegoActual?.titulo ?? widget.videojuegoTitulo ?? 'Detalles del Juego';
    final imagenMostrar =
        (juegoActual?.imagenUrl != null && juegoActual!.imagenUrl!.isNotEmpty)
            ? juegoActual.imagenUrl!
            : _portadaPorDefecto(tituloMostrar);

    final totalSesiones = sessionVm.sesiones.length;
    final totalMinutos = sessionVm.sesiones.fold<int>(
      0,
      (sum, sesion) => sum + sesion.minutosJugados,
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF171622) : Colors.white,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          tituloMostrar,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.filtroVideojuegoId != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: textColor),
              color: isDark ? const Color(0xFF221F30) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (valor) {
                if (valor == 'editar') {
                  _abrirPantallaEditarJuego(
                    context,
                    juegoActual,
                    tituloMostrar,
                    imagenMostrar,
                  );
                } else if (valor == 'eliminar') {
                  _mostrarDialogoConfirmarEliminar(
                    context,
                    tituloMostrar,
                    isDark,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: textColor, size: 20),
                      const SizedBox(width: 10),
                      Text('Editar juego', style: TextStyle(color: textColor)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Eliminar de la biblioteca',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark
                  ? []
                  : [
                      const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildPosterImage(imagenMostrar, isDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tituloMostrar,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (juegoActual != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C5CFF)
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                juegoActual.plataforma,
                                style: const TextStyle(
                                  color: Color(0xFF7C5CFF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                juegoActual.estado,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF100F18)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: Color(0xFF7C5CFF),
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatearTiempoTotal(totalMinutos),
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Tiempo jugado',
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF100F18)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.history_edu,
                                    color: Color(0xFF26A69A),
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$totalSesiones',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Sesiones',
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'Sesiones registradas',
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: _buildSessionsList(
              sessionVm,
              isDark,
              cardBg,
              textColor,
              subtextColor,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C5CFF),
        foregroundColor: Colors.white,
        onPressed: sessionVm.isSubmitting
            ? null
            : () => _mostrarDialogoNuevaSesion(isDark, juegoActual),
        icon: const Icon(Icons.add),
        label: const Text('Registrar sesión'),
      ),
    );
  }

  Widget _buildSessionsList(
    SessionViewModel vm,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
  ) {
    switch (vm.state) {
      case ViewState.loading:
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
        );

      case ViewState.error:
        return Center(
          child: Text(
            vm.errorMessage ?? 'Error al cargar las sesiones',
            style: TextStyle(color: subtextColor),
          ),
        );

      case ViewState.empty:
        return Center(
          child: Text(
            'Aún no has registrado sesiones para este juego.',
            style: TextStyle(color: subtextColor, fontSize: 15),
          ),
        );

      case ViewState.success:
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          itemCount: vm.sesiones.length,
          itemBuilder: (context, index) {
            final sesion = vm.sesiones[index];
            return Card(
              color: cardBg,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      const Color(0xFF7C5CFF).withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.access_time,
                    color: Color(0xFF7C5CFF),
                  ),
                ),
                title: Text(
                  '${sesion.minutosJugados} minutos jugados',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sesion.notas.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          sesion.notas,
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _formatearFecha(sesion.fecha),
                      style: TextStyle(color: subtextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        );
    }
  }
}

class EditGameScreen extends StatefulWidget {
  final int juegoId;
  final String tituloInicial;
  final String estadoInicial;
  final String imagenInicial;

  const EditGameScreen({
    super.key,
    required this.juegoId,
    required this.tituloInicial,
    required this.estadoInicial,
    required this.imagenInicial,
  });

  @override
  State<EditGameScreen> createState() => _EditGameScreenState();
}

class _EditGameScreenState extends State<EditGameScreen> {
  late final TextEditingController _tituloCtrl;
  late String _estadoSeleccionado;
  late String _imagenActual;
  File? _archivoGaleria;
  bool _guardando = false;

  static const List<String> _estadosDisponibles = [
    'Pendiente',
    'En progreso',
    'Completado',
  ];

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.tituloInicial);
    _estadoSeleccionado = _estadosDisponibles.contains(widget.estadoInicial)
        ? widget.estadoInicial
        : 'Pendiente';
    _imagenActual = widget.imagenInicial;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    super.dispose();
  }

  void _mostrarMenuCambiarPoster(bool isDark) {
    final sheetBg = isDark ? const Color(0xFF14131D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconCircleBg =
        isDark ? const Color(0xFF252332) : Colors.grey.shade200;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cambiar Imagen de póster',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(sheetCtx),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconCircleBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: textColor, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              InkWell(
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _seleccionarDesdeGaleria();
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconCircleBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.image_outlined,
                          color: textColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Elegir de la galería',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.info_outline,
                      color: Color(0xFFC64646),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Las imágenes de la galería permanecen en este dispositivo. '
                      'Utilice una URL de imagen para verlas en otros dispositivos.',
                      style: TextStyle(
                        color: Color(0xFFC64646),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _mostrarDialogoIntroducirUrl(isDark);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconCircleBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.link,
                          color: textColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Introducir URL',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _seleccionarDesdeGaleria() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked == null) return;

    setState(() {
      _archivoGaleria = File(picked.path);
      _imagenActual = picked.path;
    });
  }

  Future<void> _mostrarDialogoIntroducirUrl(bool isDark) async {
    final urlCtrl = TextEditingController(
      text: _imagenActual.startsWith('http') ? _imagenActual : '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1826) : Colors.white,
          title: Text(
            'Introducir URL de póster',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: urlCtrl,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'https://ejemplo.com/portada.jpg',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              labelText: 'Enlace de la imagen',
              labelStyle: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C5CFF),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final url = urlCtrl.text.trim();
                if (url.isNotEmpty) {
                  setState(() {
                    _archivoGaleria = null;
                    _imagenActual = url;
                  });
                }
                Navigator.pop(dialogCtx);
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _guardarCambios() async {
    final nuevoTitulo = _tituloCtrl.text.trim();
    if (nuevoTitulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del juego no puede estar vacío')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final supabase = Supabase.instance.client;
      String urlFinal = _imagenActual;

      if (_archivoGaleria != null) {
        try {
          final userId = supabase.auth.currentUser?.id ?? 'user';
          final ext = _archivoGaleria!.path.split('.').last;
          final fileName =
              'cover-$userId-${DateTime.now().millisecondsSinceEpoch}.$ext';
          final filePath = 'public/$fileName';

          await supabase.storage.from('avatars').upload(
                filePath,
                _archivoGaleria!,
                fileOptions: const FileOptions(upsert: true),
              );
          urlFinal = supabase.storage.from('avatars').getPublicUrl(filePath);
        } catch (_) {
          urlFinal = _archivoGaleria!.path;
        }
      }

      // Actualiza en Supabase
      await supabase
          .from('videojuegos')
          .update({
            'titulo': nuevoTitulo,
            'estado': _estadoSeleccionado,
            'imagen_url': urlFinal,
          })
          .eq('id', widget.juegoId);

      if (!mounted) return;

      // FUERZA la recarga de datos en el ViewModel global para reflejar los cambios al instante
      await context.read<CatalogViewModel>().cargarMaestros();

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Juego actualizado con éxito')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar cambios: $e')),
      );
    }
  }

  Widget _buildPreviewPoster(bool isDark) {
    if (_archivoGaleria != null) {
      return Image.file(
        _archivoGaleria!,
        width: 145,
        height: 210,
        fit: BoxFit.cover,
      );
    }
    if (_imagenActual.startsWith('http')) {
      return Image.network(
        _imagenActual,
        width: 145,
        height: 210,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildEmptyPoster(isDark),
      );
    }
    if (_imagenActual.isNotEmpty) {
      return Image.file(
        File(_imagenActual),
        width: 145,
        height: 210,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildEmptyPoster(isDark),
      );
    }
    return _buildEmptyPoster(isDark);
  }

  Widget _buildEmptyPoster(bool isDark) {
    return Container(
      width: 145,
      height: 210,
      color: isDark ? const Color(0xFF282538) : Colors.grey.shade200,
      child: Icon(
        Icons.videogame_asset,
        color: isDark ? Colors.white38 : Colors.grey,
        size: 48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0A0F) : Colors.grey.shade100;
    final cardBg = isDark ? const Color(0xFF12111A) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF242232) : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor, size: 26),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Editar juego',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Text(
                  'Imagen de póster',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Opcional',
                  style: TextStyle(color: subtextColor, fontSize: 13),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildPreviewPoster(isDark),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF262433) : Colors.grey.shade200,
                    foregroundColor: textColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: () => _mostrarMenuCambiarPoster(isDark),
                  icon: const Icon(Icons.image_outlined, size: 20),
                  label: const Text(
                    'Cambiar póster',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datos del juego',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tituloCtrl,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Nombre del juego',
                    labelStyle: TextStyle(color: subtextColor),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF1A1826) : Colors.grey.shade100,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF7C5CFF),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _estadoSeleccionado,
                  dropdownColor:
                      isDark ? const Color(0xFF1E1C2A) : Colors.white,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Estado en tu colección',
                    labelStyle: TextStyle(color: subtextColor),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF1A1826) : Colors.grey.shade100,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF7C5CFF),
                        width: 2,
                      ),
                    ),
                  ),
                  items: _estadosDisponibles
                      .map(
                        (estado) => DropdownMenuItem<String>(
                          value: estado,
                          child: Text(estado),
                        ),
                      )
                      .toList(),
                  onChanged: (nuevoEstado) {
                    if (nuevoEstado != null) {
                      setState(() => _estadoSeleccionado = nuevoEstado);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed:
                        _guardando ? null : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C5CFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: _guardando ? null : _guardarCambios,
                    child: _guardando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Guardar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}