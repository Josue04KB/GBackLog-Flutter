import 'package:flutter/material.dart';

import '../../core/errors/error_messages.dart';

/// Mantiene los campos y el estado de guardado hasta que termina la ruta.
class ProfileActionDialog extends StatefulWidget {
  const ProfileActionDialog({
    super.key,
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.icon,
    required this.onConfirm,
    this.asksForPassword = false,
    this.destructive = false,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final IconData icon;
  final bool asksForPassword;
  final bool destructive;
  final Future<String?> Function(String password) onConfirm;

  @override
  State<ProfileActionDialog> createState() => _ProfileActionDialogState();
}

class _ProfileActionDialogState extends State<ProfileActionDialog> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? true)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    String? error;
    try {
      error = await widget.onConfirm(_password.text);
    } catch (failure) {
      error = userMessage(failure);
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
    final background = dark ? const Color(0xFF181624) : Colors.white;
    final secondary = dark ? const Color(0xFFB7B1CA) : const Color(0xFF716980);
    final border = dark ? const Color(0xFF373247) : const Color(0xFFE0DAEF);
    final accent = widget.destructive
        ? const Color(0xFFBE3048)
        : const Color(0xFF7C5CFF);
    final highlight = widget.destructive
        ? dark
              ? const Color(0xFFFF9AA6)
              : const Color(0xFFB3263A)
        : dark
        ? const Color(0xFFB6A5FF)
        : const Color(0xFF6744D8);

    Widget passwordField({required bool confirmation}) => TextFormField(
      controller: confirmation ? _confirmation : _password,
      enabled: !_saving,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: confirmation
          ? TextInputAction.done
          : TextInputAction.next,
      onFieldSubmitted: confirmation ? (_) => _save() : null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: confirmation ? 'Confirmar contraseña' : 'Nueva contraseña',
        helperText: confirmation ? null : 'Al menos 6 caracteres',
        helperMaxLines: 2,
        errorMaxLines: 3,
        filled: true,
        fillColor: dark ? const Color(0xFF211E30) : const Color(0xFFF5F3FC),
        labelStyle: TextStyle(color: secondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        suffixIcon: confirmation
            ? null
            : IconButton(
                tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                onPressed: _saving
                    ? null
                    : () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
      ),
      validator: (value) {
        if (confirmation) {
          return value != _password.text || (value?.isEmpty ?? true)
              ? 'Las contraseñas no coinciden.'
              : null;
        }
        return (value?.length ?? 0) < 6 ? 'Usa al menos 6 caracteres.' : null;
      },
    );

    return PopScope(
      canPop: !_saving,
      child: Dialog(
        backgroundColor: background,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: highlight.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(widget.icon, color: highlight, size: 28),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.description,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (widget.asksForPassword) ...[
                    const SizedBox(height: 24),
                    passwordField(confirmation: false),
                    const SizedBox(height: 18),
                    passwordField(confirmation: true),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.confirmLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text('Cancelar', style: TextStyle(color: secondary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
