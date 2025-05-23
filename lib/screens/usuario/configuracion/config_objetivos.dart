import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/providers/usuario_provider.dart';

class ConfiguracionObjetivosPage extends ConsumerStatefulWidget {
  final String campo;
  const ConfiguracionObjetivosPage({Key? key, required this.campo}) : super(key: key);

  @override
  ConsumerState<ConfiguracionObjetivosPage> createState() => _ConfiguracionObjetivosPageState();
}

class _ConfiguracionObjetivosPageState extends ConsumerState<ConfiguracionObjetivosPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _controller;
  late FocusNode _timeFieldFocusNode; // Add a FocusNode for time fields
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _timeFieldFocusNode = FocusNode(); // Initialize the FocusNode
    _timeFieldFocusNode.addListener(() async {
      if (_timeFieldFocusNode.hasFocus) {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          setState(() {
            _controller.text = time.format(context);
          });
        }
        _timeFieldFocusNode.unfocus(); // Unfocus after selecting time
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _fetchInitialValue();
      _isInitialized = true;
    }
  }

  void _fetchInitialValue() {
    final user = ref.read(usuarioProvider);
    String current = '';
    switch (widget.campo) {
      case 'Objetivo Pasos':
        current = user.objetivoPasosDiarios?.toString() ?? '';
        break;
      case 'Objetivo Actividad':
        current = user.objetivoTiempoEntrenamiento > 0 ? user.objetivoTiempoEntrenamiento.toString() : '';
        break;
      case 'Objetivo Entrenamiento Semanal':
        current = user.objetivoEntrenamientoSemanal > 0 ? user.objetivoEntrenamientoSemanal.toString() : '';
        break;
      case 'Objetivo Kcal':
        current = user.objetivoKcal?.toString() ?? '';
        break;
      default:
        current = '';
    }
    _controller.text = current;
  }

  Widget _buildInput() {
    switch (widget.campo) {
      default:
        return TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: widget.campo,
            border: const OutlineInputBorder(),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Ingrese un valor' : null,
        );
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(usuarioProvider);
    final val = _controller.text.trim();
    bool ok = false;
    switch (widget.campo) {
      case 'Objetivo Pasos':
        final intVal = int.tryParse(val) ?? 0;
        ok = await user.setObjetivoPasosDiarios(intVal);
        break;
      case 'Objetivo Actividad':
        final intVal = int.tryParse(val) ?? 0;
        ok = await user.setObjetivoTiempoEntrenamiento(intVal);
        break;
      case 'Objetivo Entrenamiento Semanal':
        final intVal = int.tryParse(val) ?? 0;
        ok = await user.setObjetivoEntrenamientoSemanal(intVal);
        break;
      case 'Objetivo Kcal':
        final intVal = int.tryParse(val) ?? 0;
        ok = await user.setObjetivoKcal(intVal);
        break;
    }
    if (ok) {
      ref.refresh(usuarioProvider);
      Navigator.pop(context, _controller.text.trim());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar')),
      );
    }
  }

  @override
  void dispose() {
    _timeFieldFocusNode.dispose(); // Dispose the FocusNode
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInput(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardBackground,
                      foregroundColor: AppColors.mutedRed,
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _guardar,
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
