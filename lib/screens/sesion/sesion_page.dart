import 'package:flutter/material.dart';
import '../../models/rutina/sesion.dart';
import '../../utils/colors.dart';
import '../ejercicios/listado/ejercicios_listado.dart';
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
          title: Text(widget.sesion.titulo),
          backgroundColor: AppColors.appBarBackground,
          bottom: TabBar(
            indicatorColor: AppColors.advertencia,
            labelColor: AppColors.advertencia,
            unselectedLabelColor: AppColors.background,
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
