import 'package:flutter/material.dart';
import 'package:mrfit/models/entrenamiento/serie_realizada.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/modelo_datos.dart';

class ResumenSerie extends StatelessWidget {
  final int index;
  final SerieRealizada serie;
  final double pesoUsuario;

  const ResumenSerie({Key? key, required this.index, required this.serie, required this.pesoUsuario}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final peso = serie.peso;
    final repeticiones = serie.repeticiones;
    final pesoObjetivo = serie.pesoObjetivo;
    final repeticionesObjetivo = serie.repeticionesObjetivo;
    final rer = serie.rer;
    final kcal = serie.calcularKcal(pesoUsuario);
    String rerLabel = "";
    Color iconColor = AppColors.intermediateAccentColor;
    if (rer > 0) {
      final dificultadRer = ModeloDatos.getDifficultyOptions(value: rer);
      rerLabel = dificultadRer != null ? dificultadRer['label'] : '';
      iconColor = dificultadRer["iconColor"];
    }
    final diferenciaPesoObjetivo = peso - pesoObjetivo;
    final diferenciaRepeticionesObjetivo = repeticiones - repeticionesObjetivo;
    final extra = serie.extra == 1 ? true : false;

    if (!serie.realizada) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rer > 0 ? iconColor : Colors.transparent,
                border: Border.all(color: rer > 0 ? iconColor : AppColors.accentColor),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(fontSize: 12, color: rer > 0 ? AppColors.background : AppColors.accentColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$peso kg x $repeticiones repeticiones',
              style: TextStyle(color: extra ? AppColors.mutedAdvertencia : AppColors.textColor),
            ),
            const SizedBox(width: 8),
            if (extra)
              Text(
                'EXTRA',
                style: TextStyle(color: AppColors.mutedAdvertencia),
              )
            else
              Text(
                '(${(diferenciaPesoObjetivo >= 0 ? '+' : '')}${diferenciaPesoObjetivo} kg, ${(diferenciaRepeticionesObjetivo >= 0 ? '+' : '')}${diferenciaRepeticionesObjetivo} repes)',
                style: TextStyle(
                  color: (diferenciaPesoObjetivo >= 0 && diferenciaRepeticionesObjetivo >= 0) ? AppColors.intermediateAccentColor : AppColors.mutedRed,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (rer > 0) ...[
              Text(
                rerLabel,
                style: TextStyle(color: iconColor),
              ),
              const SizedBox(width: 16),
            ],
            Spacer(),
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: 2),
            Text(
              '$kcal kcal',
              style: TextStyle(color: iconColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
