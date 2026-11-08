import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'catalog_view_model.dart';

class AddGameCatalogScreen extends StatefulWidget {
  const AddGameCatalogScreen({super.key});

  @override
  State<AddGameCatalogScreen> createState() => _AddGameCatalogScreenState();
}

class _AddGameCatalogScreenState extends State<AddGameCatalogScreen> {
  late final Future<List> _futureCatalogo;

  @override
  void initState() {
    super.initState();
    _futureCatalogo = _cargarCatalogoDesdeSupabase();
  }

  Future<List> _cargarCatalogoDesdeSupabase() async {
    final response = await Supabase.instance.client
        .from('catalogo_global')
        .select()
        .order('titulo', ascending: true);
    return List.from(response);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0C14) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF171622) : Colors.white,
        title: Text('Explorar Catálogo', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: FutureBuilder<List>(
        future: _futureCatalogo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No se pudo cargar el catálogo de la nube.',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
              ),
            );
          }

          final juegos = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.75,
            ),
            itemCount: juegos.length,
            itemBuilder: (context, index) {
              final juego = juegos[index];
              return GestureDetector(
                onTap: () => _mostrarHojaDetalleJuego(context, juego, isDark),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF181624) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark
                        ? []
                        : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            juego['imagen_url'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, _) => Container(
                              color: isDark ? const Color(0xFF282538) : Colors.grey.shade200,
                              child: Icon(
                                Icons.image_not_supported,
                                color: isDark ? Colors.white38 : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              juego['titulo'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              juego['genero'] ?? '',
                              style: const TextStyle(color: Color(0xFF7C5CFF), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _mostrarHojaDetalleJuego(
    BuildContext parentContext,
    Map<String, dynamic> juego,
    bool isDark,
  ) {
    final catalogVm = parentContext.read<CatalogViewModel>();

    String estadoSeleccionado = 'Pendiente';
    String plataformaSeleccionada = catalogVm.plataformas.isNotEmpty
        ? catalogVm.plataformas.first.nombre
        : 'PC';
    bool leerMas = false;

    final opcionesPlataforma = catalogVm.plataformas.isNotEmpty
        ? catalogVm.plataformas.map((e) => e.nombre).toList()
        : ['PS5', 'PC', 'Switch', 'Emulador', 'Móvil'];

    final sheetBg = isDark ? const Color(0xFF100F18) : Colors.grey.shade100;
    final cardBg = isDark ? const Color(0xFF181624) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    final titulo = juego['titulo'] ?? '';
    final genero = juego['genero'] ?? '';
    final desarrollador = juego['desarrollador'] ?? 'Desconocido';
    final lanzamiento = juego['lanzamiento'] ?? 'N/A';
    final imagenUrl = juego['imagen_url'] ?? '';
    final descripcion = juego['descripcion'] ?? 'Sin descripción.';

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.55,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Container(
                    color: sheetBg,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 280,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                imagenUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                              ),
                              BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.35),
                                        sheetBg,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                          children: [
                            Center(
                              child: Container(
                                width: 42,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white30 : Colors.black26,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () => Navigator.pop(sheetCtx),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 155,
                                height: 220,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.network(
                                    imagenUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: const Color(0xFF282538),
                                      child: const Icon(
                                        Icons.videogame_asset,
                                        color: Colors.white38,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              titulo,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white : const Color(0xFF7C5CFF),
                                  foregroundColor: isDark ? Colors.black87 : Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () async {
                                  Navigator.pop(sheetCtx);
                                  final ok = await catalogVm.agregarVideojuego(
                                    titulo: titulo,
                                    genero: genero,
                                    estado: estadoSeleccionado,
                                    plataforma: plataformaSeleccionada,
                                    imagenUrl: imagenUrl,
                                  );
                                  if (!parentContext.mounted) return;

                                  if (ok) {
                                    parentContext.pop();
                                    ScaffoldMessenger.of(parentContext).showSnackBar(
                                      SnackBar(
                                        content: Text('"$titulo" agregado a tu colección'),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(parentContext).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          catalogVm.errorMessage ?? 'Error al guardar',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.library_add_outlined, size: 20),
                                label: const Text(
                                  'Agregar al Backlog',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2E2B40) : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: isDark ? Colors.white : const Color(0xFF7C5CFF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Detalles',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Acerca de',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF252236) : Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    descripcion,
                                    maxLines: leerMas ? 20 : 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 14,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => setSheetState(() => leerMas = !leerMas),
                                    child: Text(
                                      leerMas ? 'Leer menos' : 'Leer más',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Detalles',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF252236) : Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildFilaDetalle('Género', genero, textColor, subtextColor),
                                  const Divider(height: 22),
                                  _buildFilaDetalle('Desarrollador', desarrollador, textColor, subtextColor),
                                  const Divider(height: 22),
                                  _buildFilaDetalle('Lanzamiento', lanzamiento, textColor, subtextColor),
                                  const Divider(height: 26),
                                  DropdownButtonFormField<String>(
                                    initialValue: plataformaSeleccionada,
                                    dropdownColor: isDark ? const Color(0xFF282538) : Colors.white,
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      labelText: 'Plataforma para tu colección',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF7C5CFF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isDark ? const Color(0xFF343246) : Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF7C5CFF),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    items: opcionesPlataforma
                                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setSheetState(() => plataformaSeleccionada = val);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    initialValue: estadoSeleccionado,
                                    dropdownColor: isDark ? const Color(0xFF282538) : Colors.white,
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      labelText: 'Estado inicial',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF7C5CFF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isDark ? const Color(0xFF343246) : Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF7C5CFF),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                                      DropdownMenuItem(value: 'En progreso', child: Text('En progreso')),
                                      DropdownMenuItem(value: 'Completado', child: Text('Completado')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setSheetState(() => estadoSeleccionado = val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilaDetalle(
    String etiqueta,
    String valor,
    Color textColor,
    Color subtextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta, style: TextStyle(color: subtextColor, fontSize: 14)),
        Text(valor, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}