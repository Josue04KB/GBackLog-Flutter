import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      context
          .read<SessionViewModel>()
          .cargarSesiones(videojuegoId: widget.filtroVideojuegoId);
      final catalogVm = context.read<CatalogViewModel>();
      if (catalogVm.plataformas.isEmpty || catalogVm.videojuegos.isEmpty) {
        catalogVm.cargarMaestros();
      }
    });
  }

  Future<void> _abrirFormularioTransaccion() async {
    final catalogVm = context.read<CatalogViewModel>();
    if (catalogVm.videojuegos.isEmpty || catalogVm.plataformas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero deben cargarse los videojuegos y plataformas.'),
        ),
      );
      return;
    }

    int? selectedJuegoId =
        widget.filtroVideojuegoId ?? catalogVm.videojuegos.first.id;
    int? selectedPlatId = catalogVm.plataformas.first.id;
    final minutosCtrl = TextEditingController();
    final notasCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Registrar Sesión de Juego (Transacción)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const Text('Videojuego (Entidad Maestra 2):'),
                    DropdownButton<int>(
                      value: selectedJuegoId,
                      isExpanded: true,
                      items: catalogVm.videojuegos
                          .map(
                            (j) => DropdownMenuItem<int>(
                              value: j.id,
                              child: Text(j.titulo),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setModalState(() => selectedJuegoId = val),
                    ),
                    const SizedBox(height: 12),
                    const Text('Plataforma (Entidad Maestra 1):'),
                    DropdownButton<int>(
                      value: selectedPlatId,
                      isExpanded: true,
                      items: catalogVm.plataformas
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: p.id,
                              child: Text(p.nombre),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setModalState(() => selectedPlatId = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: minutosCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minutos jugados (1 - 1440)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notasCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notas o progreso de la partida (mín. 5 letras)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final mins = int.tryParse(minutosCtrl.text.trim()) ?? 0;
                        final sessionVm = context.read<SessionViewModel>();
                        final ok = await sessionVm.registrarNuevaSesion(
                          videojuegoId: selectedJuegoId,
                          plataformaId: selectedPlatId,
                          minutosJugados: mins,
                          notas: notasCtrl.text,
                          filtroVideojuegoIdActual: widget.filtroVideojuegoId,
                        );
                        if (!mounted || !sheetCtx.mounted) return;
                        if (ok) {
                          Navigator.of(sheetCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transacción registrada en Supabase.'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                sessionVm.errorMessage ?? 'Error de validación',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Guardar Transacción'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionVm = context.watch<SessionViewModel>();
    final title = widget.videojuegoTitulo != null
        ? 'Sesiones: ${widget.videojuegoTitulo}'
        : 'Historial de Sesiones (Transaccional)';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Recargar transacciones desde Supabase',
            icon: const Icon(Icons.refresh),
            onPressed: () => sessionVm.cargarSesiones(
              videojuegoId: widget.filtroVideojuegoId,
            ),
          ),
        ],
      ),
      body: _buildBody(sessionVm),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Registrar nueva sesión de juego',
        onPressed: _abrirFormularioTransaccion,
        icon: const Icon(Icons.add_task),
        label: const Text('Registrar Sesión'),
      ),
    );
  }

  Widget _buildBody(SessionViewModel vm) {
    switch (vm.state) {
      case ViewState.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Consultando transacciones en Supabase...'),
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
                const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'No se pudieron obtener las sesiones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  vm.errorMessage ?? 'Error de red',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => vm.cargarSesiones(
                    videojuegoId: widget.filtroVideojuegoId,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );

      case ViewState.empty:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_score, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Aún no hay sesiones registradas.\nUsa el botón inferior para registrar tu primera transacción.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

      case ViewState.success:
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vm.sesiones.length,
          itemBuilder: (context, index) {
            final s = vm.sesiones[index];
            final fechaStr =
                '${s.fecha.day.toString().padLeft(2, '0')}/${s.fecha.month.toString().padLeft(2, '0')}/${s.fecha.year}';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text('${s.minutosJugados}m'),
                ),
                title: Text(
                  s.videojuegoTitulo ?? 'Juego #${s.videojuegoId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Plataforma: ${s.plataformaNombre ?? 'ID ${s.plataformaId}'}\nNotas: ${s.notas}',
                ),
                trailing: Text(
                  fechaStr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                isThreeLine: true,
              ),
            );
          },
        );
    }
  }
}