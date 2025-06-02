import 'package:flutter/material.dart';
import 'package:mrfit/models/rutina/sesion.dart';
import 'package:mrfit/utils/colors.dart';

class EditarSesionPage extends StatefulWidget {
  final Sesion sesion;
  const EditarSesionPage({super.key, required this.sesion});

  @override
  State<EditarSesionPage> createState() => _EditarSesionPageState();
}

class _EditarSesionPageState extends State<EditarSesionPage> {
  late TextEditingController _controller;
  bool _saving = false;
  int _dificultad = 1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.sesion.titulo);
    _dificultad = widget.sesion.dificultad;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nuevoTitulo = _controller.text.trim();
    if (nuevoTitulo.isEmpty) return;
    setState(() => _saving = true);
    try {
      if (nuevoTitulo != widget.sesion.titulo) {
        await widget.sesion.rename(nuevoTitulo);
      }
      if (_dificultad != widget.sesion.dificultad) {
        await widget.sesion.setDificultad(_dificultad);
      }
      // ignore: use_build_context_synchronously
      Navigator.pop(context, nuevoTitulo);
    } catch (_) {
      setState(() => _saving = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar el día de entrenamiento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Sesión'),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textNormal),
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Título de la sesión',
                labelStyle: TextStyle(color: AppColors.textNormal),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: AppColors.textNormal),
              autofocus: true,
              onSubmitted: (_) => _guardar(),
            ),
            const SizedBox(height: 32),
            // Selector de dificultad (igual que en editar_rutina_page.dart)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dificultad', style: TextStyle(color: AppColors.textNormal)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: AppColors.textNormal),
                      onPressed: _dificultad > 1 ? () => setState(() => _dificultad--) : null,
                      splashRadius: 18,
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => GestureDetector(
                          onTap: () => setState(() => _dificultad = i + 1),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.0),
                            width: 30,
                            height: 60,
                            decoration: BoxDecoration(
                              color: i < _dificultad ? AppColors.accentColor : AppColors.appBarBackground,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.textNormal),
                      onPressed: _dificultad < 5 ? () => setState(() => _dificultad++) : null,
                      splashRadius: 18,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background)) : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
