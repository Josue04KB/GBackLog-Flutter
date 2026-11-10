import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Usa las fuentes de Flutter para que el ancho del texto coincida con la app.
/// No depende de variables de entorno ni de rutas específicas del equipo.
Future<void> loadTestFonts() async {
  var fonts = Platform.environment['SESSION_PREVIEW_FONT_DIR'];
  if (fonts == null) {
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final packages = config['packages'] as List<dynamic>;
    final flutter = packages.cast<Map<String, dynamic>>().singleWhere(
      (p) => p['name'] == 'flutter',
    );
    final packageDirectory = Directory.fromUri(
      configFile.uri.resolve(flutter['rootUri'] as String),
    );
    fonts =
        '${packageDirectory.parent.parent.path}/bin/cache/artifacts/material_fonts';
  }
  await (FontLoader('Roboto')..addFont(
        File('$fonts/roboto-regular.ttf')
            .readAsBytes()
            .then(ByteData.sublistView),
      ))
      .load();
  await (FontLoader('MaterialIcons')..addFont(
        File('$fonts/materialicons-regular.otf')
            .readAsBytes()
            .then(ByteData.sublistView),
      ))
      .load();
}
