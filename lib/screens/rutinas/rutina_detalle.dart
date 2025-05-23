import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/rutina/rutina.dart';
import 'rutina_listado_sesiones.dart';
import 'rutina_informacion.dart';
import 'editar_rutina_page.dart';

class RutinaPage extends StatefulWidget {
  final Rutina rutina;
  const RutinaPage({Key? key, required this.rutina}) : super(key: key);

  @override
  _RutinaPageState createState() => _RutinaPageState();
}

class _RutinaPageState extends State<RutinaPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(widget.rutina.titulo),
          backgroundColor: AppColors.background,
          actions: [
            if (widget.rutina.grupoId == 1 || widget.rutina.grupoId == 2)
              PopupMenuButton<int>(
                color: AppColors.cardBackground,
                icon: Icon(Icons.more_vert, color: AppColors.textNormal),
                onSelected: (v) async {
                  if (v == 0) {
                    // Editar
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditarRutinaPage(rutina: widget.rutina)),
                    );
                    // Recargar rutina desde la base de datos si se guardó
                    if (result == true) {
                      final updated = await Rutina.loadById(widget.rutina.id);
                      if (updated != null) {
                        setState(() {
                          widget.rutina.titulo = updated.titulo;
                          widget.rutina.descripcion = updated.descripcion;
                          widget.rutina.dificultad = updated.dificultad;
                          // Agrega aquí otros campos si es necesario
                        });
                      }
                    }
                  } else if (v == 1) {
                    // Eliminar
                    final confirma = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: AppColors.cardBackground,
                        title: const Text('Eliminar Rutina', style: TextStyle(color: AppColors.textNormal)),
                        content: const Text('¿Seguro que quieres eliminarla?', style: TextStyle(color: AppColors.textNormal)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (confirma == true) {
                      final ok = await widget.rutina.delete();
                      if (ok)
                        Navigator.pop(context, true); // Notifica a la pantalla anterior que hubo un cambio
                      else
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error al eliminar la rutina.')),
                        );
                    }
                  } else if (v == 2) {
                    // Archivar
                    final confirma = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: AppColors.cardBackground,
                        title: const Text('Archivar Rutina', style: TextStyle(color: AppColors.textNormal)),
                        content: const Text('¿Seguro que quieres archivarla? Podrás verla en la sección de archivadas.', style: TextStyle(color: AppColors.textNormal)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Archivar'),
                          ),
                        ],
                      ),
                    );
                    if (confirma == true) {
                      await widget.rutina.archivar();
                      Navigator.pop(context, true); // Igual que al eliminar
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 0, child: Text('Editar', style: TextStyle(color: AppColors.textNormal))),
                  const PopupMenuItem(value: 2, child: Text('Archivar', style: TextStyle(color: AppColors.textNormal))),
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
              Tab(text: 'Sesiones'),
              Tab(text: 'Información'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RutinaListadoSesionesPage(rutina: widget.rutina),
            RutinaInformacionPage(rutina: widget.rutina),
          ],
        ),
      ),
    );
  }
}
