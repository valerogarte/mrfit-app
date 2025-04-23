import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'estadisticas/estadisticas_page.dart';
import 'peso/medidas_page.dart';
import 'recuperacion/recuperacion_page.dart'; // Nueva importación

class EstadoFisicoPage extends StatefulWidget {
  const EstadoFisicoPage({super.key});

  @override
  _EstadoFisicoPageState createState() => _EstadoFisicoPageState();
}

class _EstadoFisicoPageState extends State<EstadoFisicoPage> {
  // Se eliminan variables y métodos de la lógica de "Recuperación"

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background, // Set scroll/background color
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
            indicatorColor: AppColors.mutedAdvertencia, // Indicator in advertencia
            labelColor: AppColors.mutedAdvertencia,
            unselectedLabelColor: AppColors.background,
            tabs: const [
              Tab(text: 'Recuperación'),
              Tab(text: 'Estadísticas'),
              Tab(text: 'Medidas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RecuperacionPage(), // Se utiliza el nuevo widget
            EstadisticasPage(),
            MedidasPage(),
          ],
        ),
      ),
    );
  }
}
