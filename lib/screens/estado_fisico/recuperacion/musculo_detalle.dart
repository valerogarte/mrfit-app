import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'detalle_musculo/musculo_detalle_gasto.dart';
import 'detalle_musculo/musculo_detalle_informacion.dart';

class MusculoDetallePage extends StatefulWidget {
  final String musculo;
  final List<Entrenamiento> entrenamientos;

  const MusculoDetallePage({
    super.key,
    required this.musculo,
    required this.entrenamientos,
  });

  @override
  MusculoDetallePageState createState() => MusculoDetallePageState();
}

class MusculoDetallePageState extends State<MusculoDetallePage> {
  double globalRecoveryPercentage = 100.0;

  void updatePercentage(double percentage) {
    if (globalRecoveryPercentage != percentage) {
      setState(() {
        globalRecoveryPercentage = percentage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.background,
          title: Text(
            '${widget.musculo[0].toUpperCase()}${widget.musculo.substring(1)} al ${globalRecoveryPercentage.toStringAsFixed(1)}%',
          ),
          bottom: TabBar(
            dividerColor: Colors.transparent,
            indicatorWeight: 0,
            indicator: BoxDecoration(),
            indicatorColor: Colors.transparent,
            labelColor: AppColors.mutedAdvertencia,
            unselectedLabelColor: AppColors.accentColor,
            tabs: const [
              Tab(text: 'Gasto'),
              Tab(text: 'Información'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DetalleMusculoGasto(
              musculo: widget.musculo,
              entrenamientos: widget.entrenamientos,
              onPercentageCalculated: updatePercentage,
            ),
            DetalleMusculoInformacion(
              musculo: widget.musculo,
              entrenamientos: widget.entrenamientos,
            ),
          ],
        ),
        backgroundColor: AppColors.background,
      ),
    );
  }
}
