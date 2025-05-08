// planes.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/screens/sesion/sesion_listado_page.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/models/rutina/rutina.dart';
import 'package:mrfit/models/rutina/grupo.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/widgets/not_found/not_found.dart';

class PlanesPage extends ConsumerStatefulWidget {
  const PlanesPage({Key? key}) : super(key: key);
  @override
  ConsumerState<PlanesPage> createState() => _PlanesPageState();
}

class _PlanesPageState extends ConsumerState<PlanesPage> {
  Map<Grupo, List<Rutina>> gruposConRutinas = {};
  bool isLoading = true;
  int? rutinaActualId;

  @override
  void initState() {
    super.initState();
    fetchPlanes();
  }

  Future<void> fetchPlanes() async {
    setState(() => isLoading = true);
    final usuario = ref.read(usuarioProvider);
    final rutinaActual = await usuario.getRutinaActual();
    rutinaActualId = rutinaActual?.id;
    final fetchedRutinas = await usuario.getRutinas();

    if (fetchedRutinas != null) {
      final ids = fetchedRutinas.where((r) => r.grupoId != null).map((r) => r.grupoId!).toSet();
      final gruposList = await Future.wait(ids.map((id) => Grupo.loadById(id)));
      final gruposMap = {for (var g in gruposList.whereType<Grupo>()) g.id: g};

      final temp = <Grupo, List<Rutina>>{};
      for (var r in fetchedRutinas) {
        if (r.grupoId != null && gruposMap.containsKey(r.grupoId)) {
          temp.putIfAbsent(gruposMap[r.grupoId]!, () => []).add(r);
        }
      }

      final gruposOrdenados = temp.keys.toList()..sort((a, b) => (b.peso ?? 0).compareTo(a.peso ?? 0));

      final sortedMap = <Grupo, List<Rutina>>{};
      for (var g in gruposOrdenados) {
        temp[g]!..sort((r1, r2) => (r2.peso ?? 0).compareTo(r1.peso ?? 0));
        sortedMap[g] = temp[g]!;
      }

      setState(() {
        gruposConRutinas = sortedMap;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar los datos.')),
      );
    }
  }

  void _onReorderRutinas(Grupo grupo, int oldIndex, int newIndex) {
    final list = List<Rutina>.from(gruposConRutinas[grupo]!);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);

    final length = list.length;
    final updated = <Rutina>[];
    for (var i = 0; i < length; i++) {
      updated.add(Rutina(
        id: list[i].id,
        titulo: list[i].titulo,
        descripcion: list[i].descripcion,
        imagen: list[i].imagen,
        fechaCreacion: list[i].fechaCreacion,
        usuarioId: list[i].usuarioId,
        grupoId: list[i].grupoId,
        peso: length - i,
        dificultad: list[i].dificultad,
      ));
    }
    setState(() => gruposConRutinas[grupo] = updated);
    for (var r in updated) r.setPeso(r.peso!);
  }

  Future<void> _establecerRutinaActual(Rutina rutina) async {
    final usuario = ref.read(usuarioProvider);
    if (rutinaActualId == rutina.id) {
      await usuario.setRutinaActual(null);
      setState(() => rutinaActualId = null);
    } else {
      final ok = await usuario.setRutinaActual(rutina.id);
      if (ok) {
        setState(() => rutinaActualId = rutina.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al establecer la rutina actual.')),
        );
      }
    }
  }

  Future<void> _mostrarDialogoNuevoPlan() async {
    String nuevoTitulo = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Nuevo Plan', style: TextStyle(color: AppColors.textNormal)),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Título de la rutina',
            labelStyle: TextStyle(color: AppColors.textNormal),
          ),
          style: const TextStyle(color: AppColors.textNormal),
          onChanged: (v) => nuevoTitulo = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nuevoTitulo.isNotEmpty) {
                Navigator.pop(context);
                final usuario = ref.read(usuarioProvider);
                await usuario.crearRutina(titulo: nuevoTitulo);
                await fetchPlanes();
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Rutinas"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : gruposConRutinas.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: NotFoundData(
                    title: 'Sin rutinas',
                    textNoResults: 'Puedes crear la primera pulsando "+".',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: gruposConRutinas.keys.length,
                  itemBuilder: (ctx, i) {
                    final grupo = gruposConRutinas.keys.elementAt(i);
                    final rutinas = gruposConRutinas[grupo]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            grupo.titulo,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textNormal),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 120,
                            child: grupo.id == 1
                                ? ReorderableListView(
                                    padding: EdgeInsets.zero, // <-- quitamos padding
                                    scrollDirection: Axis.horizontal,
                                    onReorder: (a, b) => _onReorderRutinas(grupo, a, b),
                                    children: rutinas.map((rutina) {
                                      final esActual = rutina.id == rutinaActualId;
                                      return Container(
                                        key: ValueKey(rutina.id),
                                        width: 200,
                                        height: 120,
                                        margin: const EdgeInsets.only(right: 10),
                                        child: Card(
                                          margin: EdgeInsets.zero, // <-- quitamos margen
                                          color: esActual ? AppColors.mutedAdvertencia : AppColors.cardBackground,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          shadowColor: Colors.transparent,
                                          elevation: esActual ? 8 : 4,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(20),
                                            onTap: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => SesionListadoPage(rutina: rutina)),
                                              );
                                              if (result == true) {
                                                await fetchPlanes(); // Refresca la lista si hubo cambios (eliminación o edición)
                                              }
                                            },
                                            child: _contenidoTarjeta(rutina, esActual),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: rutinas.map((rutina) {
                                        final esActual = rutina.id == rutinaActualId;
                                        return Container(
                                          width: 200,
                                          height: 120,
                                          margin: const EdgeInsets.only(right: 10),
                                          child: Card(
                                            shadowColor: Colors.transparent,
                                            margin: EdgeInsets.zero,
                                            color: esActual ? AppColors.mutedAdvertencia : AppColors.cardBackground,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            elevation: esActual ? 8 : 4,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () async {
                                                final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => SesionListadoPage(rutina: rutina),
                                                  ),
                                                );
                                                if (result == true) {
                                                  await fetchPlanes();
                                                }
                                              },
                                              child: _contenidoTarjeta(rutina, esActual),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevoPlan,
        backgroundColor: gruposConRutinas.isEmpty ? AppColors.mutedAdvertencia : AppColors.accentColor,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
    );
  }

  Widget _contenidoTarjeta(Rutina rutina, bool esActual) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rutina.titulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: esActual ? AppColors.background : AppColors.textNormal,
                  ),
                ),
                if (esActual)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "Rutina Actual",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.background,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
