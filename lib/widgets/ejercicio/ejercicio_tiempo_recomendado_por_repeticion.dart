import 'package:flutter/material.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/utils/colors.dart';

class EjercicioTiempoRecomendadoPorRepeticion extends StatelessWidget {
  final Ejercicio ejercicio;
  const EjercicioTiempoRecomendadoPorRepeticion({Key? key, required this.ejercicio}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contenedor con los datos y el gráfico
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Table(
                    columnWidths: {0: IntrinsicColumnWidth(), 1: IntrinsicColumnWidth()},
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        children: [
                          Row(
                            children: [Icon(Icons.arrow_upward, color: AppColors.mutedAdvertencia, size: 20), const SizedBox(width: 4), Text("Concéntrica:")],
                          ),
                          Text("${ejercicio.tiempos.faseConcentrica}s"),
                        ],
                      ),
                      TableRow(
                        children: [
                          Row(
                            children: [Icon(Icons.horizontal_rule, color: AppColors.mutedAdvertencia, size: 20), const SizedBox(width: 4), Text("Isométrica:")],
                          ),
                          Text("${ejercicio.tiempos.faseIsometrica}s"),
                        ],
                      ),
                      TableRow(
                        children: [
                          Row(
                            children: [Icon(Icons.arrow_downward, color: AppColors.mutedAdvertencia, size: 20), const SizedBox(width: 4), Text("Excéntrica:")],
                          ),
                          Text("${ejercicio.tiempos.faseExcentrica}s"),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.timer, color: AppColors.textColor, size: 40),
                      const SizedBox(height: 4),
                      Text(
                        "${ejercicio.tiempos.faseConcentrica + ejercicio.tiempos.faseExcentrica + ejercicio.tiempos.faseIsometrica}s",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mutedAdvertencia,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
