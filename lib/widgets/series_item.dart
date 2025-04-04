import 'package:flutter/material.dart';
import 'package:mrfit/models/rutina/ejercicio_personalizado.dart';
import 'package:mrfit/models/rutina/serie_personalizada.dart';
import '../widgets/ejercicio/ejercicio_tiempo_recomendado_por_repeticion.dart';
import '../utils/colors.dart';

class SeriesItem extends StatefulWidget {
  final int setIndex;
  final SeriePersonalizada serieP;
  final EjercicioPersonalizado ejercicioP;
  final VoidCallback onDelete;
  final VoidCallback onSave;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const SeriesItem({
    Key? key,
    required this.setIndex,
    required this.serieP,
    required this.ejercicioP,
    required this.onDelete,
    required this.onSave,
    required this.isExpanded,
    required this.onToggleExpand,
  }) : super(key: key);

  @override
  _SeriesItemState createState() => _SeriesItemState();
}

class _SeriesItemState extends State<SeriesItem> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _speedController;
  late TextEditingController _restController;
  late TextEditingController _rirController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Inicialmente, si isExpanded es true, comenzamos abiertos
    if (widget.isExpanded) {
      _controller.value = 1.0;
    }

    _repsController = TextEditingController(text: widget.serieP.repeticiones.toString());
    _weightController = TextEditingController(text: widget.serieP.peso.toString());
    _speedController = TextEditingController(text: widget.serieP.velocidadRepeticion.toString());
    _restController = TextEditingController(text: widget.serieP.descanso.toString());
    _rirController = TextEditingController(text: widget.serieP.rer.toString());
  }

  // Cada vez que el widget se actualiza (el padre cambia isExpanded),
  // forzamos la animación de apertura/cierre.
  @override
  void didUpdateWidget(covariant SeriesItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _speedController.dispose();
    _restController.dispose();
    _rirController.dispose();
    super.dispose();
  }

  // Para que conserve el estado interno si se sale y vuelve
  @override
  bool get wantKeepAlive => true;

  void _saveAndCollapse() async {
    int repeticiones = int.tryParse(_repsController.text) ?? 0;
    double peso = double.tryParse(_weightController.text) ?? 0.0;
    double velocidadRepeticion = double.tryParse(_speedController.text) ?? 0.0;
    int descanso = int.tryParse(_restController.text) ?? 0;
    int rer = int.tryParse(_rirController.text) ?? 0;

    if (repeticiones < 0 || peso < 0 || velocidadRepeticion < 0 || descanso < 0 || rer < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los valores no pueden ser negativos.')),
      );
      return;
    }

    widget.serieP
      ..repeticiones = repeticiones
      ..peso = peso
      ..velocidadRepeticion = velocidadRepeticion
      ..descanso = descanso
      ..rer = rer;
    widget.serieP.save();

    // Notificamos al padre para que recalcule (tiempo, volumen, etc.)
    widget.onSave();

    // Tras guardar, contraemos esta serie:
    widget.onToggleExpand();
  }

  void _deleteSerie() async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Eliminar Serie', style: TextStyle(color: AppColors.whiteText)),
          content: const Text('¿Estás seguro de que deseas eliminar esta serie?', style: TextStyle(color: AppColors.whiteText)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.whiteText)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mutedRed),
              child: const Text('Eliminar Serie'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      widget.serieP.delete();
      widget.onDelete();
    }
  }

  void _showSeriesInfoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tiempo recomendado por repetición',
              style: TextStyle(
                color: AppColors.whiteText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            EjercicioTiempoRecomendadoPorRepeticion(
              ejercicio: widget.ejercicioP.ejercicio,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: AppColors.accentColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? suffixText,
    required ValueChanged<String> onChanged,
    bool isDecimal = false,
    double step = 1.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Botón para restar
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.whiteText, width: 1),
              shape: const CircleBorder(),
            ),
            onPressed: () {
              double currentValue = double.tryParse(controller.text) ?? 0.0;
              if (currentValue <= 0) return; // no bajamos de 0
              currentValue -= step;
              if (!isDecimal) currentValue = currentValue.roundToDouble();
              controller.text = currentValue.toStringAsFixed(isDecimal ? 1 : 0);
              onChanged(controller.text);
            },
            child: const Icon(Icons.remove, size: 20, color: AppColors.whiteText),
          ),
          // Campo de texto
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.whiteText),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: AppColors.whiteText),
                suffixText: suffixText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
          // Botón para sumar
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.whiteText, width: 1),
              shape: const CircleBorder(),
            ),
            onPressed: () {
              double currentValue = double.tryParse(controller.text) ?? 0.0;
              currentValue += step;
              if (!isDecimal) currentValue = currentValue.roundToDouble();
              controller.text = currentValue.toStringAsFixed(isDecimal ? 1 : 0);
              onChanged(controller.text);
            },
            child: const Icon(Icons.add, size: 20, color: AppColors.whiteText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Para AutomaticKeepAliveClientMixin

    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 30, // ajustar según se requiera
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentColor),
            ),
            child: Center(
              child: Text(
                '${widget.setIndex + 1}',
                style: const TextStyle(
                  color: AppColors.accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            '${widget.serieP.repeticiones} reps, '
            '${widget.serieP.peso}kg '
            'y ${widget.serieP.descanso}s',
            style: const TextStyle(
              color: AppColors.textColor,
              fontSize: 14,
            ),
          ),
          // Rotamos la flechita para indicar expansión
          trailing: RotationTransition(
            turns: Tween(begin: 0.0, end: 0.5).animate(_animation),
            child: const Icon(Icons.expand_more, color: AppColors.textColor),
          ),
          onTap: widget.onToggleExpand,
        ),
        // Para animar la expansión, usamos SizeTransition con el controller
        SizeTransition(
          sizeFactor: _animation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              color: AppColors.cardBackground,
              child: Column(
                children: [
                  _buildInputField(
                    label: 'Repeticiones',
                    controller: _repsController,
                    onChanged: (value) {
                      setState(() {
                        widget.serieP.repeticiones = int.tryParse(value) ?? 0;
                      });
                    },
                    isDecimal: false,
                  ),
                  _buildInputField(
                    label: 'Peso',
                    controller: _weightController,
                    suffixText: 'kg',
                    onChanged: (value) {
                      setState(() {
                        widget.serieP.peso = double.tryParse(value) ?? 0.0;
                      });
                    },
                    isDecimal: true,
                  ),
                  _buildInputField(
                    label: 'Velocidad de las repeticiones',
                    controller: _speedController,
                    onChanged: (value) {
                      setState(() {
                        widget.serieP.velocidadRepeticion = double.tryParse(value) ?? 0.0;
                      });
                    },
                    isDecimal: true,
                    step: 0.2,
                  ),
                  GestureDetector(
                    onTap: _showSeriesInfoModal,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0, bottom: 8.0, left: 70.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Text(
                              'Recomendación ${widget.ejercicioP.ejercicio.sumaTiempos()}s por repetición',
                              style: const TextStyle(
                                color: AppColors.advertencia,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.info_outline, color: AppColors.advertencia, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildInputField(
                    label: 'Descanso (segundos)',
                    controller: _restController,
                    onChanged: (value) {
                      setState(() {
                        widget.serieP.descanso = int.tryParse(value) ?? 0;
                      });
                    },
                    isDecimal: false,
                  ),
                  _buildInputField(
                    label: 'RIR',
                    controller: _rirController,
                    onChanged: (value) {
                      setState(() {
                        widget.serieP.rer = int.tryParse(value) ?? 0;
                      });
                    },
                    isDecimal: false,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _deleteSerie,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.mutedRed),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.delete, size: 20, color: AppColors.textColor),
                            SizedBox(width: 4),
                            Text('Eliminar Serie', style: TextStyle(color: AppColors.textColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _saveAndCollapse,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.save, size: 20, color: AppColors.textColor),
                            SizedBox(width: 4),
                            Text('Guardar', style: TextStyle(color: AppColors.textColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
