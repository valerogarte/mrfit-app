import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert'; // <-- nuevo

class ConfiguracionEntrenadorPage extends ConsumerStatefulWidget {
  final String campo;
  const ConfiguracionEntrenadorPage({Key? key, required this.campo}) : super(key: key);

  @override
  _ConfiguracionEntrenadorPageState createState() => _ConfiguracionEntrenadorPageState();
}

class _ConfiguracionEntrenadorPageState extends ConsumerState<ConfiguracionEntrenadorPage> {
  String? _selected;
  final FlutterTts _flutterTts = FlutterTts(); // instancia de TTS
  List<Map<String, String>> _voiceOptions = []; // opciones cargadas

  static const Map<String, List<Map<String, String>>> _presetOptions = {
    'Entrenador Activo': [
      {'value': 'true', 'label': 'Sí'},
      {'value': 'false', 'label': 'No'},
    ],
    'Volumen del Entrenador': [
      {'value': "0", 'label': 'Sin sonido (0)'},
      {'value': "1", 'label': 'Volumen mínimo (0.1)'},
      {'value': "2", 'label': 'Volumen mínimo-bajo (0.2)'},
      {'value': "3", 'label': 'Volumen bajo (0.3)'},
      {'value': "4", 'label': 'Volumen medio-bajo (0.4)'},
      {'value': "5", 'label': 'Volumen medio (0.5)'},
      {'value': "6", 'label': 'Volumen medio-alto (0.6)'},
      {'value': "7", 'label': 'Volumen alto (0.7)'},
      {'value': "8", 'label': 'Volumen muy alto (0.8)'},
      {'value': "9", 'label': 'Volumen muy alto-máximo (0.9)'},
      {'value': "10", 'label': 'Volumen máximo (1)'},
    ],
  };

  int _missCounter = 0;
  int _mrCounter = 0;
  int _mxCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadVoiceOptions(); // cargar voces
    final user = ref.read(usuarioProvider);
    switch (widget.campo) {
      case 'Entrenador Activo':
        _selected = user.entrenadorActivo ? 'true' : 'false';
        break;
      case 'Voz del Entrenador':
        if (user.entrenadorVoz.isNotEmpty) {
          try {
            final decoded = jsonDecode(user.entrenadorVoz);
            final Map<String, dynamic> data = decoded is List
                ? decoded.cast<Map<String, dynamic>>().first
                : decoded is Map<String, dynamic>
                    ? decoded
                    : <String, dynamic>{};
            _selected = data['name'] as String? ?? user.entrenadorVoz;
          } catch (_) {
            _selected = user.entrenadorVoz;
          }
        }
        break;
      case 'Volumen del Entrenador':
        _selected = user.entrenadorVolumen.toString();
        break;
    }
  }

  Future<void> _loadVoiceOptions() async {
    final voices = await _flutterTts.getVoices;
    setState(() {
      _missCounter = 0;
      _mrCounter = 0;
      _mxCounter = 0;
      _voiceOptions = voices.where((v) => (v['name'] as String).toLowerCase().startsWith('es')).map<Map<String, String>>((v) {
        final features = (v['features'] as String?)?.toLowerCase() ?? '';
        final genderField = (v['gender'] as String?)?.toLowerCase();
        final gender = genderField != null
            ? genderField
            : features.contains('gender=female')
                ? 'female'
                : features.contains('gender=male')
                    ? 'male'
                    : '';
        String label;
        if (gender == 'female') {
          _missCounter++;
          label = 'Miss Voice $_missCounter';
        } else if (gender == 'male') {
          _mrCounter++;
          label = 'Mr Voice $_mrCounter';
        } else {
          _mxCounter++;
          label = 'Mx Voice $_mxCounter';
        }

        return {
          'value': v['name'] as String,
          'label': label, // lo que ve el usuario
          'locale': v['locale'] as String, // el locale real para TTS
        };
      }).toList();
    });
  }

  List<Map<String, String>> _getOptions(String campo) {
    if (campo == 'Voz del Entrenador') {
      return _voiceOptions;
    }
    return _presetOptions[campo] ?? [];
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
        final opt = _voiceOptions.firstWhere((v) => v['value'] == _selected!);
        await _flutterTts.setVoice({
          'name': _selected!,
          'locale': opt['locale']!,
        });
        // ahora guardamos JSON con name y locale
        final voJson = jsonEncode({
          'name': _selected!,
          'locale': opt['locale']!,
        });
        success = await user.setEntrenadorVoz(voJson);
        break;
      case 'Volumen del Entrenador':
        final selectedInt = int.parse(_selected!);
        await _flutterTts.setVolume(selectedInt / 10.0);
        success = await user.setEntrenadorVolumen(selectedInt);
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

  // Ajusta la voz o el volumen según el campo seleccionado, luego habla
  Future<void> _probar() async {
    await _flutterTts.stop();
    if (_selected == null) return;

    if (widget.campo == 'Voz del Entrenador') {
      // usa la voz seleccionada
      final opt = _voiceOptions.firstWhere((v) => v['value'] == _selected);
      await _flutterTts.setVoice({
        'name': _selected!,
        'locale': opt['locale']!, // usar locale real
      });
    } else if (widget.campo == 'Volumen del Entrenador') {
      // ajustar volumen según opción numérica seleccionada
      final volInt = int.parse(_selected!);
      await _flutterTts.setVolume(volInt / 10.0);
    }

    await _flutterTts.speak('¡Hola! Te acompañaré en todos tus entrenamientos. ¿Estás preparado?');
  }

  @override
  Widget build(BuildContext context) {
    final options = _getOptions(widget.campo);
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
                child: IconButton(
                  onPressed: _probar,
                  icon: Icon(Icons.volume_up, color: AppColors.mutedAdvertencia),
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
