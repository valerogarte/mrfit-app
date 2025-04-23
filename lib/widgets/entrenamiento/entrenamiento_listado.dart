import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/screens/entrenamiento_realizado/entrenamiento_realizado.dart';
import 'package:mrfit/screens/entrenamiento_realizado/entrenamiento_realizado_google.dart';

class ListadoEntrenamientos extends StatelessWidget {
  final List<dynamic> resumenEntrenamientos;
  final Future<void> Function(BuildContext context, int index, dynamic removedTraining) onDismissed;
  final VoidCallback onTrainingDeleted;

  const ListadoEntrenamientos({
    Key? key,
    required this.resumenEntrenamientos,
    required this.onDismissed,
    required this.onTrainingDeleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (resumenEntrenamientos.isEmpty) return const Center(child: Text('Sin entrenamientos realizados'));

    return ListView.builder(
      itemCount: resumenEntrenamientos.length,
      itemBuilder: (context, index) {
        final entrenamiento = resumenEntrenamientos[index];
        return Dismissible(
          key: ValueKey(entrenamiento['id']),
          background: Container(
            alignment: Alignment.centerRight,
            color: Colors.red,
            padding: const EdgeInsets.only(right: 20),
            child: const Text(
              'Eliminar entrenamiento',
              style: TextStyle(color: AppColors.whiteText),
            ),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.cardBackground,
                title: const Text('Eliminar Entrenamiento', style: TextStyle(color: AppColors.whiteText)),
                content: const Text(
                  '¿Estás seguro de que deseas eliminar este entrenamiento?',
                  style: TextStyle(color: AppColors.whiteText),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.mutedRed)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) async {
            await onDismissed(context, index, entrenamiento);
            onTrainingDeleted();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: ListTile(
              title: Row(
                children: [
                  Text(
                    entrenamiento['titulo'],
                    style: const TextStyle(color: AppColors.whiteText),
                  ),
                  if (entrenamiento['isGoogleFit'] == true)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Image.asset(
                        'assets/images/rrss/google-fit.png',
                        width: 20,
                        height: 20,
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 35),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.textColor),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yy').format(DateTime.parse(entrenamiento['inicio'])),
                              style: const TextStyle(color: AppColors.textColor),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer, color: AppColors.textColor),
                            const SizedBox(width: 8),
                            Text(
                              entrenamiento['duracion'],
                              style: const TextStyle(color: AppColors.textColor),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: AppColors.textColor),
                            const SizedBox(width: 8),
                            Text(
                              'X kcal',
                              style: const TextStyle(color: AppColors.textColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                if (entrenamiento['isGoogleFit'] == true) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EntrenamientoRealizadoGooglePage(entrenamientoJson: entrenamiento),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EntrenamientoRealizadoPage(id: entrenamiento['id']),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
