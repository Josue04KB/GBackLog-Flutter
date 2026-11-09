import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/game_models.dart';

class SessionDraft {
  const SessionDraft({
    required this.plataformaId,
    required this.minutosJugados,
    required this.notas,
  });

  final int plataformaId;
  final int minutosJugados;
  final String notas;
}

/// El formulario conserva sus controladores hasta que Flutter desmonta la ruta,
/// incluyendo la animación de salida. El guardado lo coordina la pantalla.
class NewSessionSheet extends StatefulWidget {
  const NewSessionSheet({
    super.key,
    required this.videojuegoTitulo,
    required this.plataformas,
    required this.plataformaInicialId,
    required this.onSave,
  });

  final String videojuegoTitulo;
  final List<Plataforma> plataformas;
  final int? plataformaInicialId;

  /// Devuelve null al guardar o el mensaje de error para permitir reintentar.
  final Future<String?> Function(SessionDraft draft) onSave;

  @override
  State<NewSessionSheet> createState() => _NewSessionSheetState();
}

class _NewSessionSheetState extends State<NewSessionSheet> {
  static const _accent = Color(0xFF7C5CFF);
  final _formKey = GlobalKey<FormState>();
  final _minutesController = TextEditingController();
  final _notesController = TextEditingController();
  int? _platformId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _platformId =
        widget.plataformas.any(
          (platform) => platform.id == widget.plataformaInicialId,
        )
        ? widget.plataformaInicialId
        : null;
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    final draft = SessionDraft(
      plataformaId: _platformId!,
      minutosJugados: int.parse(_minutesController.text.trim()),
      notas: _notesController.text.trim(),
    );
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    String? error;
    try {
      error = await widget.onSave(draft);
    } catch (_) {
      error = 'No se pudo guardar la sesión. Revisa tu conexión y reintenta.';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF171622) : Colors.white;
    final fieldBackground = isDark
        ? const Color(0xFF211E30)
        : const Color(0xFFF5F3FC);
    final borderColor = isDark
        ? const Color(0xFF373247)
        : const Color(0xFFE0DAEF);
    final foreground = isDark ? Colors.white : const Color(0xFF211D35);
    final secondary = isDark
        ? const Color(0xFFB7B1CA)
        : const Color(0xFF655E76);
    final highlight = isDark
        ? const Color(0xFFB6A5FF)
        : const Color(0xFF6744D8);

    InputDecoration decoration(
      String label, {
      String? hint,
      String? helper,
      IconData? icon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        errorMaxLines: 3,
        alignLabelWithHint: true,
        filled: true,
        fillColor: fieldBackground,
        labelStyle: TextStyle(color: secondary),
        hintStyle: TextStyle(color: secondary.withValues(alpha: 0.7)),
        helperStyle: TextStyle(color: secondary, fontSize: 12),
        floatingLabelStyle: TextStyle(color: highlight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: highlight, size: 21),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
      );
    }

    return PopScope(
      canPop: !_saving,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Material(
          color: background,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            side: BorderSide(color: borderColor),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.timer_outlined, color: highlight),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nueva sesión',
                            style: TextStyle(
                              color: foreground,
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar formulario',
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close_rounded, color: secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Guarda tu tiempo y los avances de tu partida.',
                      style: TextStyle(
                        color: secondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: isDark ? 0.1 : 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sports_esports_outlined, color: highlight),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.videojuegoTitulo,
                              style: TextStyle(
                                color: foreground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<int>(
                      initialValue: _platformId,
                      isExpanded: true,
                      dropdownColor: fieldBackground,
                      borderRadius: BorderRadius.circular(14),
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: foreground, fontSize: 15),
                      decoration: decoration(
                        'Plataforma',
                        icon: Icons.devices_outlined,
                      ),
                      items: widget.plataformas
                          .map(
                            (platform) => DropdownMenuItem(
                              value: platform.id,
                              child: Text(
                                platform.nombre,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _platformId = value),
                      validator: (value) =>
                          value == null ? 'Selecciona una plataforma.' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _minutesController,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(color: foreground),
                      decoration: decoration(
                        'Minutos jugados',
                        hint: 'Ej. 45',
                        helper: 'De 1 a 1440 minutos por sesión',
                        icon: Icons.schedule_rounded,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final minutes = int.tryParse(value?.trim() ?? '');
                        if (minutes == null || minutes < 1 || minutes > 1440) {
                          return 'Ingresa un tiempo entre 1 y 1440 minutos.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [30, 60, 90]
                          .map(
                            (minutes) => ChoiceChip(
                              label: Text('$minutes min'),
                              selected: _minutesController.text == '$minutes',
                              showCheckmark: false,
                              selectedColor: _accent.withValues(alpha: 0.22),
                              backgroundColor: fieldBackground,
                              labelStyle: TextStyle(
                                color: highlight,
                                fontWeight: FontWeight.w600,
                              ),
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              onSelected: _saving
                                  ? null
                                  : (_) => setState(() {
                                      _minutesController.text = '$minutes';
                                    }),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      enabled: !_saving,
                      minLines: 3,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(color: foreground, height: 1.4),
                      decoration: decoration(
                        'Notas o progreso logrado',
                        hint: '¿Qué lograste en esta partida?',
                        helper: 'Al menos 5 caracteres',
                      ),
                      validator: (value) => (value?.trim().length ?? 0) < 5
                          ? 'Describe tu avance con al menos 5 caracteres.'
                          : null,
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
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _accent.withValues(alpha: 0.5),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(52),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 21),
                      label: Text(
                        _saving ? 'Guardando sesión…' : 'Guardar sesión',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: secondary,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Cancelar'),
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
