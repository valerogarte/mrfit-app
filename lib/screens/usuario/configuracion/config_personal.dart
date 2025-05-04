import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/providers/usuario_provider.dart';

class ConfiguracionPersonalDialog extends ConsumerStatefulWidget {
  final String campo;
  const ConfiguracionPersonalDialog({super.key, required this.campo});

  @override
  _ConfiguracionPersonalDialogState createState() => _ConfiguracionPersonalDialogState();

  static Future<void> selectBirthDate(BuildContext context, WidgetRef ref) async {
    final usuario = ref.read(usuarioProvider);
    DateTime initialDate = usuario.fechaNacimiento;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != initialDate) {
      await usuario.setFechaNacimiento(picked);
      ref.refresh(usuarioProvider);
    }
  }
}

class _ConfiguracionPersonalDialogState extends ConsumerState<ConfiguracionPersonalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _controller;
  String? selectedGender;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _fetchInitialValue();
  }

  void _fetchInitialValue() async {
    final user = ref.read(usuarioProvider);
    String currentValue = "";
    switch (widget.campo) {
      case 'Altura':
        currentValue = (await user.getCurrentHeight(1)).toString();
        break;
      case 'Género':
        currentValue = user.genero;
        if (currentValue.toLowerCase() == 'hombre') {
          currentValue = 'Hombre';
        } else if (currentValue.toLowerCase() == 'mujer') {
          currentValue = 'Mujer';
        }
        selectedGender = currentValue;
        break;
      case 'Experiencia':
        currentValue = user.experiencia;
        break;
      default:
        break;
    }
    setState(() {
      _controller.text = currentValue;
    });
  }

  Widget buildInputField() {
    switch (widget.campo) {
      case 'Altura':
        return TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: widget.campo),
          validator: (value) => (value == null || value.isEmpty) ? 'Ingrese un valor' : null,
        );
      case 'Género':
        final List<String> generos = ['Hombre', 'Mujer'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Column(
              children: generos.map((gen) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ChoiceChip(
                    label: Container(
                      width: double.infinity,
                      child: Text(gen, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    selected: _controller.text == gen,
                    onSelected: (selected) {
                      setState(() {
                        _controller.text = selected ? gen : '';
                        selectedGender = selected ? gen : null;
                      });
                    },
                    padding: const EdgeInsets.all(8),
                    backgroundColor: Colors.grey[200],
                    selectedColor: AppColors.mutedAdvertencia,
                  ),
                );
              }).toList(),
            ),
            if (_controller.text.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('Seleccione un género', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        );
      case 'Experiencia':
        final user = ref.read(usuarioProvider);
        final List<Map<String, String>> experiencias = user.getTipoExperiencia();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Column(
              children: experiencias.map((exp) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ChoiceChip(
                    label: Container(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exp['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(exp['desc']!, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    selected: _controller.text == exp['title'],
                    onSelected: (selected) {
                      setState(() {
                        _controller.text = selected ? exp['title']! : '';
                      });
                    },
                    padding: const EdgeInsets.all(8),
                    backgroundColor: Colors.grey[200],
                    selectedColor: AppColors.mutedAdvertencia,
                  ),
                );
              }).toList(),
            ),
            if (_controller.text.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('Seleccione una experiencia', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        );
      case 'Volumen Máximo':
        final user = ref.read(usuarioProvider);
        return FutureBuilder<Map<String, double>>(
          future: user.getCurrentMrPoints(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Cargando...');
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No se encontraron datos de Volumen Máximo.');
            } else {
              final data = snapshot.data!;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.8,
                    children: data.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.asset(
                                  'assets/images/cuerpohumano/cuerpohumano-frontal.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.key[0].toUpperCase() + entry.key.substring(1),
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${NumberFormat('#,##0.00', 'es_ES').format(entry.value)} kg',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mutedAdvertencia,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }
          },
        );
      default:
        return TextFormField(
          controller: _controller,
          decoration: InputDecoration(labelText: widget.campo),
          validator: (value) => (value == null || value.isEmpty) ? 'Ingrese un valor' : null,
        );
    }
  }

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(usuarioProvider);
      final String value = _controller.text.trim();
      bool success = false;
      switch (widget.campo) {
        case 'Altura':
          success = await user.setAltura(double.tryParse(value));
          break;
        case 'Género':
          success = await user.setGenero(value);
          break;
        case 'Experiencia':
          success = await user.setExperiencia(value);
          break;
        default:
          break;
      }
      if (success) {
        ref.refresh(usuarioProvider);
        Navigator.pop(context, _controller.text);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Habilitamos scroll
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildInputField(),
              const SizedBox(height: 20),
              widget.campo == 'Volumen Máximo'
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardBackground,
                            foregroundColor: AppColors.mutedRed,
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    )
                  : Row(
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
        ),
      ),
    );
  }
}
