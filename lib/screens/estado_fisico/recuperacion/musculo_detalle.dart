import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'detalle_musculo/musculo_detalle_gasto.dart';
import 'detalle_musculo/musculo_detalle_informacion.dart';

class MusculoDetallePage extends StatefulWidget {
  final String musculo;
  final List<Entrenamiento> entrenamientos;

  const MusculoDetallePage({
    Key? key,
    required this.musculo,
    required this.entrenamientos,
  }) : super(key: key);

  @override
  _MusculoDetallePageState createState() => _MusculoDetallePageState();
}

class _MusculoDetallePageState extends State<MusculoDetallePage> {
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
          title: Text(
            '${widget.musculo[0].toUpperCase()}${widget.musculo.substring(1)} al ${globalRecoveryPercentage.toStringAsFixed(1)}%',
          ),
          backgroundColor: AppColors.appBarBackground,
          bottom: TabBar(
            indicatorColor: AppColors.advertencia,
            labelColor: AppColors.advertencia,
            unselectedLabelColor: AppColors.background,
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
