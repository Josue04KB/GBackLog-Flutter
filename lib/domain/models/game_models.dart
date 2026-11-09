class Plataforma {
  final int id;
  final String nombre;
  final String fabricante;
  final String formatoDefault;
  final String? userId;

  Plataforma({
    required this.id,
    required this.nombre,
    required this.fabricante,
    required this.formatoDefault,
    this.userId,
  });

  factory Plataforma.fromJson(Map<String, dynamic> json) {
    return Plataforma(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      fabricante: json['fabricante'] as String,
      formatoDefault: json['formato_default'] as String,
      userId: json['user_id'] as String?,
    );
  }
}

class Videojuego {
  final int id;
  final String titulo;
  final String genero;
  final String estado;
  final String plataforma;
  final String? imagenUrl;

  Videojuego({
    required this.id,
    required this.titulo,
    required this.genero,
    required this.estado,
    required this.plataforma,
    this.imagenUrl,
  });

  factory Videojuego.fromJson(Map<String, dynamic> json) {
    return Videojuego(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      genero: json['genero'] as String,
      estado: json['estado'] as String,
      plataforma: (json['plataforma'] as String?) ?? 'PC',
      imagenUrl: json['imagen_url'] as String?,
    );
  }
}

/// Juego disponible en el catálogo remoto que el usuario puede agregar a su
/// colección. Se mantiene separado de [Videojuego] porque todavía no tiene
/// estado ni plataforma elegida por el usuario.
class JuegoCatalogo {
  final String titulo;
  final String genero;
  final String desarrollador;
  final String lanzamiento;
  final String imagenUrl;
  final String descripcion;

  const JuegoCatalogo({
    required this.titulo,
    required this.genero,
    required this.desarrollador,
    required this.lanzamiento,
    required this.imagenUrl,
    required this.descripcion,
  });

  factory JuegoCatalogo.fromJson(Map<String, dynamic> json) {
    String value(String key, String fallback) {
      final rawValue = json[key];
      if (rawValue == null) return fallback;
      final text = rawValue.toString().trim();
      return text.isEmpty ? fallback : text;
    }

    return JuegoCatalogo(
      titulo: value('titulo', 'Sin título'),
      genero: value('genero', 'Sin género'),
      desarrollador: value('desarrollador', 'Desconocido'),
      lanzamiento: value('lanzamiento', 'N/A'),
      imagenUrl: value('imagen_url', ''),
      descripcion: value('descripcion', 'Sin descripción.'),
    );
  }
}

class SesionJuego {
  final int id;
  final int videojuegoId;
  final int plataformaId;
  final int minutosJugados;
  final String notas;
  final DateTime fecha;
  final String? videojuegoTitulo;
  final String? plataformaNombre;

  SesionJuego({
    required this.id,
    required this.videojuegoId,
    required this.plataformaId,
    required this.minutosJugados,
    required this.notas,
    required this.fecha,
    this.videojuegoTitulo,
    this.plataformaNombre,
  });

  factory SesionJuego.fromJson(Map<String, dynamic> json) {
    final juegoMap = json['videojuegos'] as Map<String, dynamic>?;
    final platMap = json['plataformas'] as Map<String, dynamic>?;

    return SesionJuego(
      id: json['id'] as int,
      videojuegoId: json['videojuego_id'] as int,
      plataformaId: json['plataforma_id'] as int,
      minutosJugados: json['minutos_jugados'] as int,
      notas: json['notas'] as String,
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      videojuegoTitulo: juegoMap?['titulo'] as String?,
      plataformaNombre: platMap?['nombre'] as String?,
    );
  }
}
