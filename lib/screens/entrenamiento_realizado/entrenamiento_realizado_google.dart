import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/providers/usuario_provider.dart';

class EntrenamientoRealizadoGooglePage extends ConsumerWidget {
  final dynamic entrenamientoJson;
  const EntrenamientoRealizadoGooglePage({super.key, required this.entrenamientoJson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.read(usuarioProvider);
    return FutureBuilder<dynamic>(
        future: usuario.getEntrenamientoCompleto(entrenamientoJson), // Se pasa el id de la actividad de Google
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Text('No data found');
          } else {
            return Text('Demo text');
          }
        });
  }
}
