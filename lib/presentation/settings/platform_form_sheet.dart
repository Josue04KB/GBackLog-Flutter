import 'package:flutter/material.dart';

import '../../core/errors/error_messages.dart';
import '../../domain/models/game_models.dart';

typedef PlatformDraft = ({String nombre, String fabricante, String formato});

class PlatformFormSheet extends StatefulWidget {
  const PlatformFormSheet({super.key, this.initial, required this.onSave});
  final Plataforma? initial;
  final Future<String?> Function(PlatformDraft draft) onSave;

  @override
  State<PlatformFormSheet> createState() => _PlatformFormSheetState();
}

class _PlatformFormSheetState extends State<PlatformFormSheet> {
  static const accent = Color(0xFF7C5CFF);
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _manufacturer;
  late final TextEditingController _format;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.nombre ?? '');
    _manufacturer = TextEditingController(
      text: widget.initial?.fabricante ?? '',
    );
    _format = TextEditingController(text: widget.initial?.formatoDefault ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _manufacturer.dispose();
    _format.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    String? error;
    try {
      error = await widget.onSave((
        nombre: _name.text.trim(),
        fabricante: _manufacturer.text.trim(),
        formato: _format.text.trim(),
      ));
    } catch (failure) {
      error = userMessage(
        failure,
        fallback: 'No pudimos guardar la plataforma. Inténtalo de nuevo.',
      );
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final editing = widget.initial != null;
    final background = dark ? const Color(0xFF171622) : Colors.white;
    final surface = dark ? const Color(0xFF211E30) : const Color(0xFFF5F3FC);
    final border = dark ? const Color(0xFF373247) : const Color(0xFFE0DAEF);
    final secondary = dark ? const Color(0xFFB7B1CA) : const Color(0xFF655E76);
    final highlight = dark ? const Color(0xFFB6A5FF) : const Color(0xFF6744D8);

    Widget field(
      TextEditingController controller,
      String label,
      String hint,
      IconData icon, {
      bool last = false,
    }) {
      return TextFormField(
        controller: controller,
        enabled: !_saving,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: last ? (_) => _save() : null,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: surface,
          prefixIcon: Icon(icon, color: highlight, size: 22),
          labelStyle: TextStyle(color: secondary),
          hintStyle: TextStyle(color: secondary.withValues(alpha: 0.7)),
          floatingLabelStyle: TextStyle(color: highlight),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          errorMaxLines: 3,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
        ),
        validator: (value) {
          final length = value?.trim().length ?? 0;
          if (length < 2 || length > 80) {
            return 'Escribe entre 2 y 80 caracteres.';
          }
          return null;
        },
      );
    }

    return PopScope(
      canPop: !_saving,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Material(
          color: background,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            side: BorderSide(color: border),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            editing
                                ? Icons.edit_outlined
                                : Icons.devices_rounded,
                            color: highlight,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            editing ? 'Editar plataforma' : 'Nueva plataforma',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      editing ? 'Actualiza los datos de tu plataforma.' : 'Organiza tu colección con los dispositivos donde juegas.',
                      style: TextStyle(
                        color: secondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    field(
                      _name,
                      'Nombre',
                      'Ej. Xbox Series X',
                      Icons.sports_esports_outlined,
                    ),
                    const SizedBox(height: 18),
                    field(
                      _manufacturer,
                      'Fabricante',
                      'Ej. Microsoft',
                      Icons.business_outlined,
                    ),
                    const SizedBox(height: 18),
                    field(
                      _format,
                      'Formato',
                      'Ej. Cartucho / Digital',
                      Icons.album_outlined,
                      last: true,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final value in [
                          'Digital',
                          'Físico',
                          'Físico / Digital',
                        ])
                          ChoiceChip(
                            label: Text(value),
                            selected: _format.text == value,
                            onSelected: _saving
                                ? null
                                : (_) => setState(() => _format.text = value),
                            selectedColor: accent.withValues(alpha: 0.2),
                            labelStyle: TextStyle(color: highlight),
                            side: BorderSide(color: border),
                            showCheckmark: false,
                          ),
                      ],
                    ),
                    if (editing) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Si cambias el nombre, también se actualizará en tus juegos.',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      key: const ValueKey('save-platform'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 17,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _saving
                            ? 'Guardando…'
                            : editing
                            ? 'Guardar cambios'
                            : 'Guardar plataforma',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
