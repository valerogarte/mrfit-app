import 'package:flutter/material.dart';
import 'package:mrfit/models/entrenamiento/serie_realizada.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/modelo_datos.dart';
import 'package:mrfit/models/entrenamiento/ejercicio_realizado.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/providers/usuario_provider.dart';

class EntrenamientoSeries extends ConsumerStatefulWidget {
  final String setIndex;
  final SerieRealizada set;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final Future<void> Function() onDelete;
  final Future<void> Function() onComplete;
  final Future<void> Function() onUpdate;
  final EjercicioRealizado ejercicioRealizado;

  const EntrenamientoSeries({
    super.key,
    required this.setIndex,
    required this.set,
    required this.repsController,
    required this.weightController,
    required this.isExpanded,
    required this.onExpand,
    required this.onCollapse,
    required this.onDelete,
    required this.onComplete,
    required this.onUpdate,
    required this.ejercicioRealizado,
  });

  @override
  ConsumerState<EntrenamientoSeries> createState() => EntrenamientoSeriesState();
}

class EntrenamientoSeriesState extends ConsumerState<EntrenamientoSeries> with SingleTickerProviderStateMixin {
  bool isEditing = false;
  Color _selectedEmojiColor = AppColors.textMedium;
  List<Map<String, dynamic>>? _avgRerLabel;

  @override
  void initState() {
    super.initState();
    // Si la serie ya está realizada, asignamos el color del emoji correspondiente
    if (widget.set.realizada && widget.set.rer > 0) {
      final opcion = ModeloDatos.getDifficultyOptions(value: widget.set.rer);
      if (opcion != null) {
        _selectedEmojiColor = opcion['iconColor'];
      }
    }
    _loadSuelesIrALabel();
  }

  // Método que carga de forma asíncrona el promedio y obtiene el literal de dificultad para cada detalle de serie
  Future<void> _loadSuelesIrALabel() async {
    try {
      final ep = await widget.ejercicioRealizado.ejercicio.getNumeroSeriesPromedioRealizadasPorEntrenamiento();
      final detalles = ep['detallesSeries'] as List;
      // Para cada detalle, transformar el "rer" en su literal y obtener el iconColor
      List<Map<String, dynamic>> labels = detalles.map((detalle) {
        final int rerValue = detalle['rer'] as int;
        final option = rerValue > 0 ? ModeloDatos.getDifficultyOptions(value: rerValue) : null;
        final label = option?['label'] ?? "";
        final iconColor = option?['iconColor'] ?? AppColors.textMedium;
        return {"label": label, "iconColor": iconColor};
      }).toList();
      if (!mounted) return;
      setState(() {
        _avgRerLabel = labels;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _avgRerLabel = null;
      });
    }
  }

  @override
  void didUpdateWidget(covariant EntrenamientoSeries oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      setState(() {
        isEditing = widget.isExpanded;
      });
    }
    if (oldWidget.set.realizada != widget.set.realizada) {
      setState(() {});
    }
  }

  // Función para mostrar el modal bottom sheet de dificultad
  void _showDifficultySheet() {
    final usuario = ref.read(usuarioProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${widget.set.repeticiones} reps, ${widget.set.peso} kg',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textNormal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...ModeloDatos.getDifficultyOptions()
                      .map((option) => _buildDifficultyTile(
                            option['value'],
                            option['label'],
                            option['description'],
                            option['iconColor'],
                            usuario,
                          ))
                      .toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget para cada opción de dificultad, con título en negrita y descripción
  Widget _buildDifficultyTile(int value, String label, String description, Color iconColor, Usuario usuario) {
    return ListTile(
      leading: Icon(Icons.star, color: iconColor),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textNormal,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(color: AppColors.textNormal),
      ),
      onTap: () async {
        setState(() {
          widget.set.setRer(value);
          _selectedEmojiColor = iconColor;
        });
        // Evento analytics: selección de dificultad en la serie
        await FirebaseAnalytics.instance.logEvent(
          name: 'entrenamiento_set_dificultad',
          parameters: {
            'ejercicio_id': widget.ejercicioRealizado.ejercicio.id,
            'ejercicio_nombre': widget.ejercicioRealizado.ejercicio.nombre,
            'serie_id': widget.set.id,
            'dificultad_valor': value,
            'dificultad_label': label,
            'repeticiones': widget.set.repeticiones,
            'peso': widget.set.peso,
            'user': usuario.username,
          },
        );
        Navigator.pop(context);
      },
    );
  }

  // Campo ajustable para peso y repeticiones
  Widget _buildAdjustableField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textNormal,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.textNormal),
                    ),
                    padding: const EdgeInsets.all(4.0),
                    child: const Icon(Icons.remove, color: AppColors.textNormal),
                  ),
                  onPressed: onDecrement,
                ),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textNormal),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (label == 'Repeticiones') {
                          widget.set.repeticiones = int.tryParse(value) ?? widget.set.repeticiones;
                        } else if (label == 'Peso (kg)') {
                          widget.set.peso = double.tryParse(value) ?? widget.set.peso;
                        }
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.textNormal),
                    ),
                    padding: const EdgeInsets.all(4.0),
                    child: const Icon(Icons.add, color: AppColors.textNormal),
                  ),
                  onPressed: onIncrement,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int indexSerie = (int.tryParse(widget.setIndex) ?? 1) - 1;
    final String? dificultadLabel = _avgRerLabel != null && _avgRerLabel!.length > indexSerie ? _avgRerLabel![indexSerie]["label"].toLowerCase() : null;
    final Color? dificultadColor = _avgRerLabel != null && _avgRerLabel!.length > indexSerie ? _avgRerLabel![indexSerie]["iconColor"] : null;
    return Column(
      children: [
        Container(
          color: AppColors.cardBackground,
          child: ListTile(
            title: Row(
              children: [
                widget.set.realizada == true
                    ? Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.accentColor),
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                widget.setIndex,
                                style: const TextStyle(
                                  color: AppColors.textNormal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.set.repeticiones} reps, ${widget.set.peso} kg',
                            style: const TextStyle(
                              color: AppColors.textNormal,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.accentColor),
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                widget.setIndex,
                                style: const TextStyle(
                                  color: AppColors.textNormal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Serie ',
                                  style: TextStyle(
                                    color: AppColors.textNormal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: widget.setIndex,
                                  style: const TextStyle(
                                    color: AppColors.textNormal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (dificultadLabel != null && dificultadLabel.isNotEmpty) ...[
                                  const TextSpan(
                                    text: ' - Sueles ir ',
                                    style: TextStyle(
                                      color: AppColors.textNormal,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  TextSpan(
                                    text: dificultadLabel,
                                    style: TextStyle(
                                      color: dificultadColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.set.realizada == true)
                  IconButton(
                    icon: Icon(Icons.emoji_emotions, color: _selectedEmojiColor),
                    onPressed: _showDifficultySheet,
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textMedium),
                  onSelected: (String result) {
                    if (result == 'editar') {
                      widget.onExpand();
                    } else if (result == 'eliminar') {
                      widget.onDelete();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return widget.isExpanded
                        ? <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'eliminar',
                              child: Text('Eliminar'),
                            ),
                          ]
                        : <PopupMenuEntry<String>>[
                            if (!isEditing)
                              const PopupMenuItem<String>(
                                value: 'editar',
                                child: Text('Editar'),
                              ),
                            const PopupMenuItem<String>(
                              value: 'eliminar',
                              child: Text('Eliminar'),
                            ),
                          ];
                  },
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: widget.isExpanded
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildAdjustableField(
                        label: 'Repeticiones',
                        controller: widget.repsController,
                        onIncrement: () {
                          setState(() {
                            widget.set.repeticiones++;
                            widget.repsController.text = widget.set.repeticiones.toString();
                          });
                        },
                        onDecrement: () {
                          setState(() {
                            if (widget.set.repeticiones > 0) {
                              widget.set.repeticiones--;
                              widget.repsController.text = widget.set.repeticiones.toString();
                            }
                          });
                        },
                      ),
                      _buildAdjustableField(
                        label: 'Peso (kg)',
                        controller: widget.weightController,
                        onIncrement: () {
                          setState(() {
                            widget.set.peso += 0.5;
                            widget.weightController.text = widget.set.peso.toString();
                          });
                        },
                        onDecrement: () {
                          setState(() {
                            if (widget.set.peso > 0) {
                              widget.set.peso -= 0.5;
                              widget.weightController.text = widget.set.peso.toString();
                            }
                          });
                        },
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          isEditing ? await widget.onUpdate() : widget.onComplete();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appBarBackground,
                        ),
                        child: Text(
                          isEditing ? 'Actualizar Set' : 'Set completo',
                          style: const TextStyle(color: AppColors.textNormal),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
