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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _fetchInitialValue();
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
      case 'Objetivo Kcal':
        current = user.objetivoKcal?.toString() ?? '';
        break;
      default:
        current = '';
    }
    _controller.text = current;
  }

  Widget _buildInput() {
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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(usuarioProvider);
    final val = int.tryParse(_controller.text.trim()) ?? 0;
    bool ok = false;
    switch (widget.campo) {
      case 'Objetivo Pasos':
        ok = await user.setObjetivoPasosDiarios(val);
        break;
      case 'Objetivo Actividad':
        ok = await user.setObjetivoTiempoEntrenamiento(val);
        break;
      case 'Objetivo Kcal':
        ok = await user.setObjetivoKcal(val);
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
