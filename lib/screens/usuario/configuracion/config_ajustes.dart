import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/utils/colors.dart';

class ConfiguracionAjustesPage extends ConsumerStatefulWidget {
  // Changed to ConsumerStatefulWidget
  final String campo;
  const ConfiguracionAjustesPage({super.key, required this.campo});

  @override
  ConfiguracionAjustesPageState createState() => ConfiguracionAjustesPageState();
}

class ConfiguracionAjustesPageState extends ConsumerState<ConfiguracionAjustesPage> {
  // Changed to ConsumerState
  final formKey = GlobalKey<FormState>();
  late TextEditingController _controller;
  String? selectedGender;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _fetchInitialValue();
  }

  void _fetchInitialValue() {
    dynamic currentValue = "";
    switch (widget.campo) {
      case 'Entrenador':
        currentValue = true;
        break;
      case 'Voz del Entrenador':
        currentValue = '{"name":"es-ES-SMTl01","locale":"spa-x-lvariant-l01"}';
        break;
      case 'Volumen del Entrenador':
        currentValue = 3;
        break;
      case 'Unidades':
        currentValue = "cms";
        break;
      default:
        break;
    }
    setState(() {
      _controller.text = currentValue.toString();
    });
  }

  Widget buildInputField() {
    return TextFormField(
      controller: _controller,
      keyboardType: widget.campo == 'Unidades' ? TextInputType.text : TextInputType.number,
      decoration: InputDecoration(labelText: widget.campo),
      validator: (value) => (value == null || value.isEmpty) ? 'Ingrese un valor' : null,
    );
  }

  void _guardar() async {
    if (formKey.currentState!.validate()) {
      // final user = ref.read(usuarioProvider);
      // final String value = _controller.text.trim();

      Navigator.pop(context, _controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildInputField(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    );
  }
}
