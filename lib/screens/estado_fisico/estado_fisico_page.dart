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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.background,
          toolbarHeight: 0,
          bottom: TabBar(
            dividerColor: Colors.transparent,
            indicatorWeight: 0,
            indicator: BoxDecoration(),
            indicatorColor: Colors.transparent,
            labelColor: AppColors.mutedAdvertencia,
            unselectedLabelColor: AppColors.accentColor,
            tabs: const [
              Tab(text: 'Recuperación'),
              Tab(text: 'Estadísticas'),
              Tab(text: 'Medidas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RecuperacionPage(),
            EstadisticasPage(),
            MedidasPage(),
          ],
        ),
      ),
    );
  }
}
