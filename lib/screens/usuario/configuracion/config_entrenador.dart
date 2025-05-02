import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/providers/usuario_provider.dart';

class ConfiguracionEntrenadorPage extends ConsumerStatefulWidget {
  final String campo;
  const ConfiguracionEntrenadorPage({Key? key, required this.campo}) : super(key: key);

  @override
  _ConfiguracionEntrenadorPageState createState() => _ConfiguracionEntrenadorPageState();
}

class _ConfiguracionEntrenadorPageState extends ConsumerState<ConfiguracionEntrenadorPage> {
  String? _selected;

  static const Map<String, List<Map<String, String>>> _options = {
    'Entrenador Activo': [
      {'value': 'true', 'label': 'Sí'},
      {'value': 'false', 'label': 'No'},
    ],
    'Voz del Entrenador': [
      {'value': '1', 'label': 'Voz 1'},
      {'value': '2', 'label': 'Voz 2'},
      {'value': '3', 'label': 'Voz 3'},
    ],
    'Volumen del Entrenador': [
      {'value': 'bajo', 'label': 'Bajo'},
      {'value': 'medio', 'label': 'Medio'},
      {'value': 'alto', 'label': 'Alto'},
    ],
  };

  @override
  void initState() {
    super.initState();
    final user = ref.read(usuarioProvider);
    switch (widget.campo) {
      case 'Entrenador Activo':
        _selected = user.entrenadorActivo ? 'true' : 'false';
        break;
      case 'Voz del Entrenador':
        _selected = user.vozEntrenador.toString();
        break;
      case 'Volumen del Entrenador':
        _selected = user.volumenMaximo.toString();
        break;
    }
  }

  Future<void> _guardar() async {
    if (_selected == null) return;
    final user = ref.read(usuarioProvider);
    bool success = false;
    switch (widget.campo) {
      case 'Entrenador Activo':
        success = await user.setEntrenadorActivo(_selected == 'true');
        break;
      case 'Voz del Entrenador':
        success = await user.setVozEntrenador(int.parse(_selected!));
        break;
      case 'Volumen del Entrenador':
        success = await user.setSonido(_selected.toString());
        break;
    }
    if (success) {
      ref.refresh(usuarioProvider);
      Navigator.pop(context, _selected);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options[widget.campo] ?? [];
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.campo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMedium)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: options.map((opt) {
              final selected = opt['value'] == _selected;
              return ChoiceChip(
                label: Text(opt['label']!),
                selected: selected,
                onSelected: (_) => setState(() => _selected = opt['value']),
                backgroundColor: Colors.grey[200],
                selectedColor: AppColors.mutedAdvertencia,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: AppColors.mutedRed),
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
