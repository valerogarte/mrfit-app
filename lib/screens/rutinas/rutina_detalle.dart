import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/rutina/rutina.dart';
import 'rutina_listado_sesiones.dart';
import 'rutina_informacion.dart';
import 'rutina_editar_page.dart';

// Cambia a ConsumerStatefulWidget para acceder a providers
class RutinaPage extends ConsumerStatefulWidget {
  final Rutina rutina;
  const RutinaPage({super.key, required this.rutina});

  @override
  ConsumerState<RutinaPage> createState() => _RutinaPageState();
}

class _RutinaPageState extends ConsumerState<RutinaPage> {
  @override
  Widget build(BuildContext context) {
    // Acceso a usuarioProvider usando ref
    final usuario = ref.read(usuarioProvider);
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
                      if (ok) {
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context, true); // Notifica a la pantalla anterior que hubo un cambio
                      } else {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error al eliminar la rutina.')),
                        );
                      }
                    }
                  } else if (v == 2) {
                    // Archivar o Restaurar según grupo
                    final esGrupo1 = widget.rutina.grupoId == 1;
                    final confirma = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: AppColors.cardBackground,
                        title: Text(
                          esGrupo1 ? 'Archivar Rutina' : 'Restaurar Rutina',
                          style: const TextStyle(color: AppColors.textNormal),
                        ),
                        content: Text(
                          esGrupo1 ? '¿Seguro que quieres archivarla? Podrás verla en la sección de archivadas.' : '¿Seguro que quieres restaurarla? Volverá a la sección principal.',
                          style: const TextStyle(color: AppColors.textNormal),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: Text(esGrupo1 ? 'Archivar' : 'Restaurar'),
                          ),
                        ],
                      ),
                    );
                    if (confirma == true) {
                      if (esGrupo1) {
                        await widget.rutina.archivar();
                        // Si la rutina archivada es la actual, la desasocia del usuario
                        final rutinaActual = await usuario.getRutinaActual();
                        if (rutinaActual?.id == widget.rutina.id) {
                          await usuario.setRutinaActual(0);
                        }
                      } else {
                        await widget.rutina.restaurar();
                      }
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context, true);
                    }
                  }
                },
                itemBuilder: (_) {
                  final items = <PopupMenuEntry<int>>[
                    const PopupMenuItem(value: 0, child: Text('Editar', style: TextStyle(color: AppColors.textNormal))),
                  ];
                  // Solo muestra Archivar si grupoId == 1, Restaurar si grupoId == 2
                  if (widget.rutina.grupoId == 1) {
                    items.add(const PopupMenuItem(value: 2, child: Text('Archivar', style: TextStyle(color: AppColors.textNormal))));
                  } else if (widget.rutina.grupoId == 2) {
                    items.add(const PopupMenuItem(value: 2, child: Text('Restaurar', style: TextStyle(color: AppColors.textNormal))));
                  }
                  items.add(const PopupMenuItem(value: 1, child: Text('Eliminar', style: TextStyle(color: AppColors.textNormal))));
                  return items;
                },
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
