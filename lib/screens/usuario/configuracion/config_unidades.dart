import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/providers/usuario_provider.dart';

class ConfiguracionUnidadesPage extends ConsumerStatefulWidget {
  final String campo;
  const ConfiguracionUnidadesPage({super.key, required this.campo});

  @override
  _ConfiguracionUnidadesPageState createState() => _ConfiguracionUnidadesPageState();
}

class _ConfiguracionUnidadesPageState extends ConsumerState<ConfiguracionUnidadesPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selected;

  static const Map<String, List<Map<String, String>>> _options = {
    'Unidad Distancia': [
      {'value': 'km', 'label': 'Kilómetros'},
      {'value': 'miles', 'label': 'Millas'},
    ],
    'Unidad Tamaño': [
      {'value': 'cm', 'label': 'Centímetros'},
      {'value': 'pulg', 'label': 'Pulgadas'},
    ],
    'Unidades Peso': [
      {'value': 'metrico', 'label': 'Métrico (kg)'},
      {'value': 'imperial', 'label': 'Imperial (lb)'},
    ],
    'Primer Día Semana': [
      {'value': '0', 'label': 'Lunes'},
      {'value': '1', 'label': 'Martes'},
      {'value': '2', 'label': 'Miércoles'},
      {'value': '3', 'label': 'Jueves'},
      {'value': '4', 'label': 'Viernes'},
      {'value': '5', 'label': 'Sábado'},
      {'value': '6', 'label': 'Domingo'},
    ],
  };

  @override
  void initState() {
    super.initState();
    final user = ref.read(usuarioProvider);
    switch (widget.campo) {
      case 'Unidad Distancia':
        _selected = user.unidadDistancia;
        break;
      case 'Unidad Tamaño':
        _selected = user.unidadTamano;
        break;
      case 'Unidades Peso':
        _selected = user.unidadesPeso;
        break;
      case 'Primer Día Semana':
        _selected = user.primerDiaSemana.toString();
        break;
    }
  }

  Future<void> _guardar() async {
    if (_selected == null) return;
    final user = ref.read(usuarioProvider);
    bool success = false;
    switch (widget.campo) {
      case 'Unidad Distancia':
        success = await user.setUnidadDistancia(_selected!);
        break;
      case 'Unidad Tamaño':
        success = await user.setUnidadTamano(_selected!);
        break;
      case 'Unidades Peso':
        success = await user.setUnidadesPeso(_selected!);
        break;
      case 'Primer Día Semana':
        success = await user.setPrimerDiaSemana(int.parse(_selected!));
        break;
    }
    if (success) {
      ref.refresh(usuarioProvider);
      Navigator.pop(context, _selected);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar')));
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
