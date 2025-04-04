import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class EditarEntrenamientoPage extends StatelessWidget {
  const EditarEntrenamientoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Entrenamiento'),
        backgroundColor: AppColors.accentColor,
      ),
      body: const Center(
        child: Text('En construcción'),
      ),
    );
  }
}
