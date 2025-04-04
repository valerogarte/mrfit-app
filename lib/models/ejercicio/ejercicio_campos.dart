part of 'ejercicio.dart';

class Musculo {
  final int id;
  final String titulo;
  final String imagen;

  Musculo({required this.id, required this.titulo, required this.imagen});

  factory Musculo.fromJson(Map<String, dynamic> json) {
    return Musculo(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      imagen: json['imagen'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'imagen': imagen,
    };
  }
}

class MusculoInvolucrado {
  final int id;
  final Musculo musculo;
  final String tipo;
  final int porcentajeImplicacion;
  final String descripcionImplicacion;

  MusculoInvolucrado({
    required this.id,
    required this.musculo,
    required this.tipo,
    required this.porcentajeImplicacion,
    this.descripcionImplicacion = '',
  });

  // Nuevo getter para mapear el campo "tipo" a "tipoString"
  String get tipoString {
    switch (tipo.toUpperCase()) {
      case 'P':
        return 'Principal';
      case 'S':
        return 'Sinergista';
      case 'E':
        return 'Estabilizador';
      default:
        return tipo;
    }
  }

  factory MusculoInvolucrado.fromJson(Map<String, dynamic> json) {
    return MusculoInvolucrado(
      id: json['id'],
      musculo: Musculo.fromJson(json['musculo'] ?? {}),
      tipo: json['tipo'] ?? '',
      porcentajeImplicacion: json['porcentaje_implicacion'] ?? 0,
      descripcionImplicacion: json['descripcion_implicacion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'musculo': musculo.toJson(),
      'tipo': tipo,
      'porcentaje_implicacion': porcentajeImplicacion,
      'descripcion_implicacion': descripcionImplicacion,
    };
  }
}

class Instruccion {
  final int id;
  final String texto;

  Instruccion({required this.id, required this.texto});

  factory Instruccion.fromJson(Map<String, dynamic> json) {
    return Instruccion(
      id: json['id'],
      texto: json['texto'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'texto': texto,
    };
  }
}

class TipoFuerza {
  final int id;
  final String titulo;

  TipoFuerza({required this.id, required this.titulo});

  factory TipoFuerza.fromJson(Map<String, dynamic> json) {
    return TipoFuerza(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
    };
  }
}

class Dificultad {
  final int id;
  final String titulo;

  Dificultad({required this.id, required this.titulo});

  factory Dificultad.fromJson(Map<String, dynamic> json) {
    return Dificultad(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
    };
  }
}

class Mecanica {
  final int id;
  final String titulo;

  Mecanica({required this.id, required this.titulo});

  factory Mecanica.fromJson(Map<String, dynamic> json) {
    return Mecanica(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
    };
  }
}

class Categoria {
  final int id;
  final String titulo;
  final String imagen;

  Categoria({required this.id, required this.titulo, required this.imagen});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      imagen: json['imagen'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'imagen': imagen,
    };
  }
}

class Equipamiento {
  final int id;
  final String titulo;
  final String imagen;

  Equipamiento({required this.id, required this.titulo, required this.imagen});

  factory Equipamiento.fromJson(Map<String, dynamic> json) {
    return Equipamiento(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      imagen: json['imagen'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'imagen': imagen,
    };
  }
}

class ErrorComun {
  final int id;
  final String texto;

  ErrorComun({required this.id, required this.texto});

  factory ErrorComun.fromJson(Map<String, dynamic> json) {
    return ErrorComun(
      id: json['id'],
      texto: json['texto'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'texto': texto,
    };
  }
}

class TituloAdicional {
  final int id;
  final String titulo;

  TituloAdicional({required this.id, required this.titulo});

  factory TituloAdicional.fromJson(Map<String, dynamic> json) {
    return TituloAdicional(
      id: json['id'],
      titulo: json['titulo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
    };
  }
}

class Tiempos {
  final double faseConcentrica;
  final double faseExcentrica;
  final double faseIsometrica;

  Tiempos({
    required this.faseConcentrica,
    required this.faseExcentrica,
    required this.faseIsometrica,
  });

  factory Tiempos.fromJson(Map<String, dynamic> json) {
    return Tiempos(
      faseConcentrica: (json['fase_concentrica'] ?? 0.0).toDouble(),
      faseExcentrica: (json['fase_excentrica'] ?? 0.0).toDouble(),
      faseIsometrica: (json['fase_isometrica'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fase_concentrica': faseConcentrica,
      'fase_excentrica': faseExcentrica,
      'fase_isometrica': faseIsometrica,
    };
  }
}
