part of 'usuario.dart';

extension UsuarioGoogleExtension on Usuario {
  UsuarioGoogle() {
    _configureGoogleSignIn();
  }

  void _configureGoogleSignIn() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      // Maneja cambios en la cuenta si lo necesitas.
    });
    _googleSignIn.signInSilently();
  }

  Future<void> googleSignOut() async {
    await _googleSignIn.signOut();
  }

  Future<GoogleSignInAccount?> googleSignIn() async {
    return await _googleSignIn.signIn();
  }

  Future<GoogleSignInAccount?> googleSignInSilently() async {
    return await _googleSignIn.signInSilently();
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  bool googleIsLoggedIn() {
    return _googleSignIn.currentUser != null;
  }

  Future<List<dynamic>?> googleGetEntrenamientos30Dias() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final url = Uri.parse(
      'https://www.googleapis.com/fitness/v1/users/me/sessions'
      '?startTime=${thirtyDaysAgo.toUtc().toIso8601String()}'
      '&endTime=${now.toUtc().toIso8601String()}',
    );

    final logger = Logger();
    GoogleSignInAccount? account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    if (account == null) {
      logger.e("No hay usuario de Google autenticado.");
      return null;
    }

    final auth = await account.authentication;
    final accessToken = auth.accessToken;
    if (accessToken == null) {
      logger.e("No se pudo obtener el token de acceso de Google.");
      return null;
    }

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['session'] != null) {
        return List<dynamic>.from(data['session']);
      }
      return [];
    } else {
      logger.e('Error fetching data: ${response.body}');
      return null;
    }
  }

  /// Intenta obtener el detalle de la sesión por ID vía GET.
  /// Si falla (por ejemplo, 404), busca la sesión en la lista y usa
  /// getDatosSesion para recuperar los datos agregados.
  Future<dynamic> getEntrenamientoCompleto(dynamic entrenamientoJson) async {
    final logger = Logger();
    GoogleSignInAccount? account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    if (account == null) {
      return Future.error("No hay usuario de Google autenticado.");
    }
    final auth = await account.authentication;
    final accessToken = auth.accessToken;
    if (accessToken == null) {
      return Future.error("No se pudo obtener el token de acceso.");
    }

    // Eliminado: print(entrenamientoJson);
    final id = entrenamientoJson["id"];
    final encodedId = Uri.encodeComponent(id.toString());
    final url = Uri.parse('https://www.googleapis.com/fitness/v1/users/me/sessions/$encodedId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    int? startTimeMillis;
    int? endTimeMillis;
    if (response.statusCode == 200) {
      final sessionDetail = jsonDecode(utf8.decode(response.bodyBytes));
      try {
        startTimeMillis = int.parse(sessionDetail['startTimeMillis'].toString());
        endTimeMillis = int.parse(sessionDetail['endTimeMillis'].toString());
      } catch (e) {
        logger.e('Error parseando timestamps del detalle de sesión: $e');
      }
    } else {
      logger.e('Error obteniendo detalle de sesión: ${response.body}');
    }

    if (startTimeMillis == null || endTimeMillis == null) {
      // Fallback: busca la sesión en la lista utilizando googleGetEntrenamientos30Dias.
      final sesiones = await googleGetEntrenamientos30Dias();
      if (sesiones == null) return Future.error("No se pudieron obtener sesiones.");
      final session = sesiones.firstWhere((s) => s['id'] == id, orElse: () => null);
      if (session == null) return Future.error("Sesión no encontrada en la lista.");
      try {
        startTimeMillis = int.parse(session['startTimeMillis'].toString());
        endTimeMillis = int.parse(session['endTimeMillis'].toString());
      } catch (e) {
        return Future.error("Error parseando timestamps de la sesión fallback.");
      }
    }
    // Retorna los datos agregados (métricas) en lugar del detalle completo.
    return await getDatosSesion(startTimeMillis: startTimeMillis, endTimeMillis: endTimeMillis);
  }

  /// Consulta la API de agregación de Google Fit para obtener datos de
  /// distancia, calorías y pulsaciones en un rango de tiempo.
  ///
  /// [startTimeMillis] y [endTimeMillis] se obtienen de la sesión.
  /// Retorna un Map con totales y la lista de pulsaciones.
  Future<Map<String, dynamic>> getDatosSesion({
    required int startTimeMillis,
    required int endTimeMillis,
  }) async {
    final logger = Logger();
    logger.i('Obteniendo datos de la sesión: $startTimeMillis - $endTimeMillis');
    GoogleSignInAccount? account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    if (account == null) {
      return Future.error("No hay usuario de Google autenticado.");
    }
    final auth = await account.authentication;
    final accessToken = auth.accessToken;
    if (accessToken == null) {
      return Future.error("No se pudo obtener el token de acceso.");
    }

    final url = Uri.parse('https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate');
    final body = {
      "aggregateBy": [
        {"dataTypeName": "com.google.distance.delta"},
        {"dataTypeName": "com.google.calories.expended"},
        {"dataTypeName": "com.google.heart_rate.bpm"}
      ],
      "bucketByTime": {"durationMillis": 60000}, // Agrupar cada 1 minuto.
      "startTimeMillis": startTimeMillis,
      "endTimeMillis": endTimeMillis
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final buckets = data["bucket"] ?? [];

      double totalDistance = 0.0;
      double totalCalories = 0.0;
      List<double> heartRates = [];

      for (var bucket in buckets) {
        final datasetList = bucket["dataset"] ?? [];
        for (var dataset in datasetList) {
          final dataSourceId = dataset["dataSourceId"] ?? "";
          final points = dataset["point"] ?? [];
          for (var point in points) {
            final values = point["value"] ?? [];
            for (var value in values) {
              if (dataSourceId.contains("com.google.distance.delta")) {
                totalDistance += (value["fpVal"] ?? 0.0);
              } else if (dataSourceId.contains("com.google.calories.expended")) {
                totalCalories += (value["fpVal"] ?? 0.0);
              } else if (dataSourceId.contains("com.google.heart_rate.bpm")) {
                heartRates.add(value["fpVal"] ?? 0.0);
              }
            }
          }
        }
      }

      double avgHeartRate = 0.0;
      if (heartRates.isNotEmpty) {
        avgHeartRate = heartRates.reduce((a, b) => a + b) / heartRates.length;
      }

      return {
        "distance": totalDistance, // en metros.
        "calories": totalCalories, // en kcal.
        "avgHeartRate": avgHeartRate, // pulsaciones promedio.
        "heartRates": heartRates, // lista de pulsaciones.
      };
    } else {
      logger.e('Error al obtener datos de la sesión: ${response.body}');
      return Future.error('Error: ${response.body}');
    }
  }

  String getActivityTypeTitle(int activityType) {
    switch (activityType) {
      case 9:
        return "Aeróbica";
      case 119:
        return "Tiro con arco";
      case 10:
        return "Bádminton";
      case 11:
        return "Béisbol";
      case 12:
        return "Básquetbol";
      case 13:
        return "Biatlón";
      case 1:
        return "Ciclismo";
      case 14:
        return "Bicicleta de mano";
      case 15:
        return "Ciclismo de montaña";
      case 16:
        return "Ciclismo en carretera";
      case 17:
        return "Hilado";
      case 18:
        return "Bicicleta fija";
      case 19:
        return "Ciclismo urbano";
      case 20:
        return "Boxeo";
      case 21:
        return "Calistenia";
      case 22:
        return "Circuito de entrenamiento";
      case 23:
        return "Críquet";
      case 113:
        return "CrossFit";
      case 106:
        return "Curling";
      case 24:
        return "Baile";
      case 102:
        return "Buceo";
      case 117:
        return "Ascensor";
      case 25:
        return "Bicicleta elíptica";
      case 103:
        return "Ergómetro";
      case 118:
        return "Escalera mecánica";
      case 26:
        return "Esgrima";
      case 27:
        return "Fútbol americano";
      case 28:
        return "Fútbol americano (Australia)";
      case 29:
        return "Fútbol americano";
      case 30:
        return "Disco volador";
      case 31:
        return "Jardinería";
      case 32:
        return "Golf";
      case 122:
        return "Respiración Guiada";
      case 33:
        return "Gimnasia";
      case 34:
        return "Balonmano";
      case 114:
        return "HIIT";
      case 35:
        return "Senderismo";
      case 36:
        return "Hockey";
      case 37:
        return "Equitación";
      case 38:
        return "Tareas del hogar";
      case 104:
        return "Patinar sobre hielo";
      case 0:
        return "En un vehículo";
      case 115:
        return "Entrenamiento por intervalos";
      case 39:
        return "Saltar la cuerda";
      case 40:
        return "Kayakismo";
      case 41:
        return "Entrenamiento con pesas rusas";
      case 42:
        return "Kickboxing";
      case 43:
        return "Kitesurf";
      case 44:
        return "Artes marciales";
      case 45:
        return "Meditación";
      case 46:
        return "Artes marciales mixtas";
      case 108:
        return "Otro (actividad sin clasificar)";
      case 47:
        return "Ejercicios de P90X";
      case 48:
        return "Parapente";
      case 49:
        return "Pilates";
      case 50:
        return "Polo";
      case 51:
        return "Ráquetbol";
      case 52:
        return "Escalada";
      case 53:
        return "Remo";
      case 54:
        return "Máquina de remo";
      case 55:
        return "Rugby";
      case 8:
        return "En ejecución";
      case 56:
        return "Trote";
      case 57:
        return "Correr en la arena";
      case 58:
        return "Correr (caminadora)";
      case 59:
        return "Navegar";
      case 60:
        return "Buceo";
      case 61:
        return "Patineta";
      case 62:
        return "Patinaje";
      case 63:
        return "Patinaje nórdico";
      case 105:
        return "Patinaje en pista cubierta";
      case 64:
        return "Patinaje en línea";
      case 65:
        return "Esquí";
      case 66:
        return "Esquí de fondo";
      case 67:
        return "Esquí a campo traviesa";
      case 68:
        return "Esquí cuesta abajo";
      case 69:
        return "Kite esquí";
      case 70:
        return "Skiroll";
      case 71:
        return "Carrera en trineo";
      case 73:
        return "Snowboard";
      case 74:
        return "Moto de nieve";
      case 75:
        return "Caminata con raquetas para nieve";
      case 120:
        return "Softball";
      case 76:
        return "Squash";
      case 77:
        return "Subir escaleras";
      case 78:
        return "Máquina escaladora";
      case 79:
        return "Surf de remo";
      case 3:
        return "Inmóvil (no se mueve)";
      case 80:
        return "Entrenamiento de fuerza";
      case 81:
        return "Surf";
      case 82:
        return "Natación";
      case 84:
        return "Natación (aguas abiertas)";
      case 83:
        return "Natación (piscina)";
      case 85:
        return "Tenis de mesa (ping pong)";
      case 86:
        return "Deportes en equipo";
      case 87:
        return "Tenis";
      case 5:
        return "Inclinación";
      case 88:
        return "Cinta de correr";
      case 4:
        return "Desconocido";
      case 89:
        return "Voleibol";
      case 90:
        return "Voleibol (playa)";
      case 91:
        return "Voleibol (interiores)";
      case 92:
        return "Wakeboarding";
      case 7:
        return "Caminar";
      case 93:
        return "Caminar (actividad física)";
      case 94:
        return "Caminata convencional";
      case 95:
        return "Caminar (cinta de correr)";
      case 116:
        return "Para caminar (cochecito)";
      case 96:
        return "Waterpolo";
      case 97:
        return "Levantamiento de pesas";
      case 98:
        return "Silla de ruedas";
      case 99:
        return "Windsurf";
      case 100:
        return "Yoga";
      case 101:
        return "Zumba";
      default:
        return "Desconocido";
    }
  }
}
