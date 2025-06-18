import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mrfit/models/rutina/sesion.dart';
import 'package:mrfit/models/rutina/rutina.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/screens/sesion/sesion_listado_ejercicios.dart';
import 'sesion_detalle.dart';
import 'sesion_musculos_involucrados.dart';
import 'editar_sesion_page.dart';

class SesionPage extends StatefulWidget {
  final Sesion sesion;
  final Rutina rutina;

  const SesionPage({
    super.key,
    required this.sesion,
    required this.rutina,
  });

  @override
  SesionPageState createState() => SesionPageState();
}

class SesionPageState extends State<SesionPage> {
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _editarSesion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarSesionPage(sesion: widget.sesion),
      ),
    );
    if (result is String && result.isNotEmpty) {
      setState(() {
        widget.sesion.titulo = result;
      });
      // Notifica a la pantalla anterior que hubo un cambio
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    }
  }

  Future<void> _eliminarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Eliminar Día de Entrenamiento', style: TextStyle(color: AppColors.textNormal)),
          content: const Text('¿Estás seguro de que deseas eliminar este día?', style: TextStyle(color: AppColors.textNormal)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmar == true) {
      await widget.sesion.delete();
      if (mounted) Navigator.pop(context, true); // Notifica cambio
    }
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logScreenView(
      screenName: 'sesion',
    );

    // Solo muestra el menú si la rutina no es de grupo 1 ni 2
    final bool mostrarMenu = widget.rutina.grupoId == 1 || widget.rutina.grupoId == 2;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(widget.sesion.titulo),
          backgroundColor: AppColors.background,
          actions: [
            if (mostrarMenu)
              PopupMenuButton<int>(
                color: AppColors.cardBackground,
                icon: const Icon(Icons.more_vert, color: AppColors.textNormal),
                onSelected: (v) async {
                  if (v == 0) {
                    await _editarSesion();
                  } else if (v == 1) {
                    await _eliminarSesion();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 0, child: Text('Editar', style: TextStyle(color: AppColors.textNormal))),
                  const PopupMenuItem(value: 1, child: Text('Eliminar', style: TextStyle(color: AppColors.textNormal))),
                ],
              ),
          ],
          bottom: TabBar(
            dividerColor: Colors.transparent,
            indicatorWeight: 0,
            indicator: BoxDecoration(),
            indicatorColor: Colors.transparent,
            labelColor: AppColors.mutedAdvertencia,
            unselectedLabelColor: AppColors.accentColor,
            tabs: const [
              Tab(text: 'Ejercicios'),
              Tab(text: 'Músculos invol.'),
              Tab(text: 'Información'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              SesionListadoEjerciciosPage(
                sesion: widget.sesion,
                rutina: widget.rutina,
              ),
              SesionMusculosInvolucradosPage(sesion: widget.sesion),
              SesionDetallePage(sesion: widget.sesion),
            ],
          ),
        ),
        backgroundColor: AppColors.background,
      ),
    );
  }
}
