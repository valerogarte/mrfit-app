import 'package:flutter/material.dart';
import 'package:mrfit/models/rutina/sesion.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/screens/ejercicios/listado/ejercicios_listado.dart';
import 'sesion_detalle.dart';
import 'sesion_musculos_involucrados.dart';

class SesionPage extends StatefulWidget {
  final Sesion sesion;

  const SesionPage({
    Key? key,
    required this.sesion,
  }) : super(key: key);

  @override
  _SesionPageState createState() => _SesionPageState();
}

class _SesionPageState extends State<SesionPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(widget.sesion.titulo),
          backgroundColor: AppColors.background,
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
        body: TabBarView(
          children: [
            EjerciciosListadoPage(sesion: widget.sesion),
            SesionMusculosInvolucradosPage(sesion: widget.sesion),
            SesionDetallePage(sesion: widget.sesion),
          ],
        ),
        backgroundColor: AppColors.background,
      ),
    );
  }
}
