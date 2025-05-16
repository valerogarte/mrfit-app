import 'package:flutter/material.dart';
import 'package:mrfit/models/rutina/ejercicio_personalizado.dart';
import 'package:mrfit/models/rutina/serie_personalizada.dart';
import 'package:mrfit/widgets/ejercicio/ejercicio_tiempo_recomendado_por_repeticion.dart';
import 'package:mrfit/utils/colors.dart';
import 'dart:async';

class SesionGestionSerieDetalle extends StatefulWidget {
  final int setIndex;
  final SeriePersonalizada serieP;
  final EjercicioPersonalizado ejercicioP;
  final VoidCallback onDelete;
  final VoidCallback onSave;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const SesionGestionSerieDetalle({
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
  _SesionGestionSerieDetalleState createState() => _SesionGestionSerieDetalleState();
}

class _SesionGestionSerieDetalleState extends State<SesionGestionSerieDetalle> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _speedController;
  late TextEditingController _restController;

  // Timer para incremento/decremento continuo
  Timer? _holdTimer;

  void _startHold(Function action) {
    // Ejecuta la acción inmediatamente
    action();
    // Luego inicia el timer para repetir la acción cada 80ms
    _holdTimer = Timer.periodic(const Duration(milliseconds: 80), (_) => action());
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

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
  }

  // Cada vez que el widget se actualiza (el padre cambia isExpanded),
  // forzamos la animación de apertura/cierre.
  @override
  void didUpdateWidget(covariant SesionGestionSerieDetalle oldWidget) {
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
    _holdTimer?.cancel();
    _controller.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _speedController.dispose();
    _restController.dispose();
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

    if (repeticiones < 0 || peso < 0 || velocidadRepeticion < 0 || descanso < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los valores no pueden ser negativos.')),
      );
      return;
    }

    widget.serieP
      ..repeticiones = repeticiones
      ..peso = peso
      ..velocidadRepeticion = velocidadRepeticion
      ..descanso = descanso;
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
          backgroundColor: AppColors.background,
          title: const Text('Eliminar Serie', style: TextStyle(color: AppColors.textNormal)),
          content: const Text('¿Estás seguro de que deseas eliminar esta serie?', style: TextStyle(color: AppColors.textNormal)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
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
      backgroundColor: AppColors.background,
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
                color: AppColors.textNormal,
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
    void decrement() {
      double currentValue = double.tryParse(controller.text) ?? 0.0;
      if (currentValue <= 0) return; // no bajamos de 0
      currentValue -= step;
      if (currentValue < 0) currentValue = 0;
      if (!isDecimal) currentValue = currentValue.roundToDouble();
      controller.text = currentValue.toStringAsFixed(isDecimal ? 1 : 0);
      onChanged(controller.text);
    }

    void increment() {
      double currentValue = double.tryParse(controller.text) ?? 0.0;
      currentValue += step;
      if (!isDecimal) currentValue = currentValue.roundToDouble();
      controller.text = currentValue.toStringAsFixed(isDecimal ? 1 : 0);
      onChanged(controller.text);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: decrement,
            onLongPressStart: (_) => _startHold(decrement),
            onLongPressEnd: (_) => _stopHold(),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.textNormal, width: 1),
                shape: const CircleBorder(),
              ),
              onPressed: decrement,
              child: const Icon(Icons.remove, size: 20, color: AppColors.textNormal),
            ),
          ),
          // Campo de texto
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textNormal),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: AppColors.textNormal),
                suffixText: suffixText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
          GestureDetector(
            onTap: increment,
            onLongPressStart: (_) => _startHold(increment),
            onLongPressEnd: (_) => _stopHold(),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.textNormal, width: 1),
                shape: const CircleBorder(),
              ),
              onPressed: increment,
              child: const Icon(Icons.add, size: 20, color: AppColors.textNormal),
            ),
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
              color: AppColors.textMedium,
              fontSize: 14,
            ),
          ),
          // Rotamos la flechita para indicar expansión
          trailing: RotationTransition(
            turns: Tween(begin: 0.0, end: 0.5).animate(_animation),
            child: const Icon(Icons.expand_more, color: AppColors.textMedium),
          ),
          onTap: widget.onToggleExpand,
        ),
        // Para animar la expansión, usamos SizeTransition con el controller
        SizeTransition(
          sizeFactor: _animation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              color: AppColors.background,
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
                    step: 0.5,
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
                                color: AppColors.mutedAdvertencia,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.info_outline, color: AppColors.mutedAdvertencia, size: 16),
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
                            Icon(Icons.delete, size: 20, color: AppColors.textMedium),
                            SizedBox(width: 4),
                            Text('Eliminar Serie', style: TextStyle(color: AppColors.textMedium)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _saveAndCollapse,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.save, size: 20, color: AppColors.textMedium),
                            SizedBox(width: 4),
                            Text('Guardar', style: TextStyle(color: AppColors.textMedium)),
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
