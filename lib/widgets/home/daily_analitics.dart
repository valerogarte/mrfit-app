import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

/// Widget reutilizable para solicitar consentimiento de analítica.
/// Separa la lógica visual para cumplir SRP y facilitar el mantenimiento.
class AnalyticsConsentWidget extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const AnalyticsConsentWidget({
    super.key,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos el color mutedAdvertencia como fondo para destacar la advertencia.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mutedAdvertencia,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primera fila: ícono y pregunta
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "MrFit es 100% gratis y sin anuncios",
                style: TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Para detectar errores y mejorar necesitamos recopilar datos de uso. Será 100% anónimo.",
                style: TextStyle(color: AppColors.background),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segunda fila: botones de respuesta
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onReject,
                child: const Text("No", style: TextStyle(color: AppColors.appBarBackground)),
              ),
              // Botón "Sí" con fondo personalizado y bordes redondeados
              TextButton(
                onPressed: onAccept,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text(
                  "Acepto",
                  style: TextStyle(
                    color: AppColors.textNormal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
