import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/rutina/rutina.dart';
import 'package:mrfit/providers/usuario_provider.dart';

class EditarRutinaPage extends ConsumerStatefulWidget {
  final Rutina rutina;
  const EditarRutinaPage({Key? key, required this.rutina}) : super(key: key);

  @override
  ConsumerState<EditarRutinaPage> createState() => _EditarRutinaPageState();
}

class _EditarRutinaPageState extends ConsumerState<EditarRutinaPage> {
  late TextEditingController _ctrl;
  late TextEditingController _descCtrl;
  bool esActual = false;
  int dificultad = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.rutina.titulo);
    _descCtrl = TextEditingController(text: widget.rutina.descripcion);
    dificultad = widget.rutina.dificultad;
    // comprobamos si ya es la rutina actual
    ref.read(usuarioProvider).getRutinaActual().then((r) {
      setState(() => esActual = r?.id == widget.rutina.id);
    });
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Rutina'),
        backgroundColor: AppColors.background,
        leading: BackButton(color: AppColors.textNormal),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.background),
            onPressed: () async {
              final confirma = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: AppColors.cardBackground,
                  title: const Text('Eliminar Rutina', style: TextStyle(color: AppColors.textNormal)),
                  content: const Text('¿Seguro que quieres eliminarla?', style: TextStyle(color: AppColors.textNormal)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar', style: TextStyle(color: AppColors.textNormal))),
                    ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eliminar')),
                  ],
                ),
              );
              if (confirma == true) {
                final ok = await widget.rutina.delete();
                if (ok)
                  Navigator.pop(context);
                else
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar la rutina.')));
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // campo título
            TextField(
              controller: _ctrl,
              style: const TextStyle(color: AppColors.textNormal),
              decoration: const InputDecoration(
                labelText: 'Título de la rutina',
                labelStyle: TextStyle(color: AppColors.textNormal),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.textNormal),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // campo descripción
            TextFormField(
              controller: _descCtrl,
              style: const TextStyle(color: AppColors.textNormal),
              decoration: const InputDecoration(
                labelText: 'Descripción',
                labelStyle: TextStyle(color: AppColors.textNormal),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.textNormal),
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            // switch rutina actual
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Rutina actual', style: TextStyle(color: AppColors.textNormal)),
                Switch(
                  value: esActual,
                  onChanged: (v) {
                    setState(() => esActual = v);
                    ref.read(usuarioProvider).setRutinaActual(v ? widget.rutina.id : null);
                  },
                  activeColor: AppColors.accentColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // selector dificultad
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: AppColors.textNormal),
                      onPressed: dificultad > 1 ? () => setState(() => dificultad--) : null,
                      splashRadius: 18,
                    ),
                    Row(
                      children: List.generate(
                          5,
                          (i) => GestureDetector(
                                onTap: () => setState(() => dificultad = i + 1),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1.0),
                                  width: 30,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: i < dificultad ? AppColors.accentColor : AppColors.appBarBackground,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              )),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.textNormal),
                      onPressed: dificultad < 5 ? () => setState(() => dificultad++) : null,
                      splashRadius: 18,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // NUEVO: botón Guardar al final
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor,
                foregroundColor: AppColors.background,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () async {
                final nuevo = _ctrl.text.trim();
                final nuevaDesc = _descCtrl.text.trim();
                if (nuevo.isNotEmpty && nuevo != widget.rutina.titulo) {
                  await widget.rutina.rename(nuevo);
                }
                // actualizar descripción si cambió
                if (nuevaDesc != widget.rutina.descripcion) {
                  await widget.rutina.setDescripcion(nuevaDesc);
                }
                // actualizar dificultad si cambió
                if (dificultad != widget.rutina.dificultad) {
                  await widget.rutina.setDificultad(dificultad);
                }
                Navigator.pop(context, true); // <-- Devuelve true para indicar cambios
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
