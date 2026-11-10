import 'package:flutter/material.dart';

import '../../core/errors/error_messages.dart';

class DeleteSessionDialog extends StatefulWidget {
  const DeleteSessionDialog({
    super.key,
    required this.detalle,
    required this.onDelete,
  });

  final String detalle;
  final Future<String?> Function() onDelete;

  @override
  State<DeleteSessionDialog> createState() => _DeleteSessionDialogState();
}

class _DeleteSessionDialogState extends State<DeleteSessionDialog> {
  bool _deleting = false;
  String? _error;

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    String? error;
    try {
      error = await widget.onDelete();
    } catch (failure) {
      error = userMessage(
        failure,
        fallback: 'No pudimos eliminar la sesión. Inténtalo de nuevo.',
      );
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _deleting = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: !_deleting,
      child: AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1826) : Colors.white,
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
        title: const Text('¿Eliminar sesión?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.detalle),
              const SizedBox(height: 12),
              const Text(
                'Se descontará este tiempo del total jugado. Esta acción no se puede deshacer.',
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _deleting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: _deleting ? null : _delete,
            icon: _deleting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: Text(_deleting ? 'Eliminando…' : 'Eliminar sesión'),
          ),
        ],
      ),
    );
  }
}
