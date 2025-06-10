import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/screens/rutinas/rutina_detalle.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/models/rutina/rutina.dart';
import 'package:mrfit/models/rutina/grupo.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/widgets/not_found/not_found.dart';
import 'package:mrfit/widgets/chart/pills_dificultad.dart';
import 'package:mrfit/main.dart';

class RutinasPage extends ConsumerStatefulWidget {
  const RutinasPage({super.key});
  @override
  ConsumerState<RutinasPage> createState() => _RutinasPageState();
}

class _RutinasPageState extends ConsumerState<RutinasPage> {
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
      final ids = fetchedRutinas.map((r) => r.grupoId).toSet();
      final gruposList = await Future.wait(ids.map((id) => Grupo.loadById(id)));
      final gruposMap = {for (var g in gruposList.whereType<Grupo>()) g.id: g};

      final temp = <Grupo, List<Rutina>>{};
      for (var r in fetchedRutinas) {
        if (gruposMap.containsKey(r.grupoId)) {
          temp.putIfAbsent(gruposMap[r.grupoId]!, () => []).add(r);
        }
      }

      final gruposOrdenados = temp.keys.toList()..sort((a, b) => (b.peso ?? 0).compareTo(a.peso ?? 0));

      final sortedMap = <Grupo, List<Rutina>>{};
      for (var g in gruposOrdenados) {
        temp[g]!.sort((r1, r2) => (r2.peso).compareTo(r1.peso));
        sortedMap[g] = temp[g]!;
      }

      setState(() {
        gruposConRutinas = sortedMap;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      // ignore: use_build_context_synchronously
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
    for (var r in updated) {
      r.setPeso(r.peso);
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

  void _handleBackButton() {
    // Maneja el evento de retroceso personalizado (por ejemplo, botón en UI).
    if (Navigator.of(context).canPop()) {
      // Retrocede una ruta si es posible.
      Navigator.of(context).pop();
    } else {
      // Si no hay rutas previas, navega a la raíz y limpia el stack.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyApp()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        // Permite retroceder si hay rutas en el stack.
        if (Navigator.of(context).canPop()) {
          return;
        }
        // Navegación diferida para evitar el lock del Navigator.
        Future.microtask(() {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MyApp()),
            (route) => false,
          );
        });
        // No se cierra la app, se redirige a la raíz.
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("Rutinas"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackButton,
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
                            child: SizedBox(
                              height: 120,
                              child: grupo.id == 1
                                  ? ReorderableListView(
                                      padding: EdgeInsets.zero, // <-- quitamos padding
                                      scrollDirection: Axis.horizontal,
                                      onReorder: (a, b) => _onReorderRutinas(grupo, a, b),
                                      proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, child: child),
                                      children: rutinas.map((rutina) {
                                        final esActual = rutina.id == rutinaActualId;
                                        return Container(
                                          key: ValueKey(rutina.id),
                                          width: 200,
                                          height: 120,
                                          margin: const EdgeInsets.only(right: 10),
                                          child: Card(
                                            margin: EdgeInsets.zero, // <-- quitamos margen
                                            color: AppColors.cardBackground, // Siempre el color de fondo de la tarjeta
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                              side: esActual ? const BorderSide(color: AppColors.mutedAdvertencia, width: 2) : BorderSide.none,
                                            ),
                                            shadowColor: Colors.transparent,
                                            elevation: esActual ? 8 : 4,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () async {
                                                final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => RutinaPage(rutina: rutina)),
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
                                              color: AppColors.cardBackground, // Siempre el color de fondo de la tarjeta
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                                side: esActual ? const BorderSide(color: AppColors.mutedAdvertencia, width: 2) : BorderSide.none,
                                              ),
                                              elevation: esActual ? 8 : 4,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(20),
                                                onTap: () async {
                                                  final result = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => RutinaPage(rutina: rutina),
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
                          // Agrega un espaciado de 40 al final de la última fila
                          if (i == gruposConRutinas.keys.length - 1) const SizedBox(height: 80),
                        ],
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _mostrarDialogoNuevoPlan,
          backgroundColor: gruposConRutinas.isEmpty ? AppColors.mutedAdvertencia : AppColors.appBarBackground,
          child: const Icon(Icons.add, color: AppColors.background),
        ),
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
                    color: AppColors.textNormal,
                  ),
                ),
                const SizedBox(height: 8),
                // Dificultad pills (igual que en rutina_listado_sesiones.dart)
                buildDificultadPills(rutina.dificultad, 6, 12),
                if (esActual)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "Rutina Actual",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedAdvertencia, // Color del texto "Rutina Actual"
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
