import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/widgets/animated_image.dart';
import 'package:mrfit/screens/ejercicios/detalle/ejercicio_detalle.dart';
import 'package:mrfit/models/modelo_datos.dart';
import 'package:mrfit/models/rutina/sesion.dart';
import 'package:mrfit/widgets/chart/pills_dificultad.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';

part 'ejercicios_buscar_logic.dart';

class EjerciciosBuscarPage extends StatefulWidget {
  final Sesion? sesion;
  final Entrenamiento? entrenamiento;

  const EjerciciosBuscarPage({
    super.key,
    this.sesion,
    this.entrenamiento,
  }) : assert(sesion != null || entrenamiento != null, 'Debe proporcionar session o entrenamiento');

  @override
  EjerciciosBuscarPageState createState() => EjerciciosBuscarPageState();
}

class EjerciciosBuscarPageState extends State<EjerciciosBuscarPage> with EjerciciosBuscarLogic {
  // Variables y controladores
  @override
  List<Ejercicio> _ejercicios = [];
  @override
  bool _isLoading = false;
  @override
  final List<Ejercicio> _ejerciciosSeleccionados = [];
  @override
  final TextEditingController _nombreController = TextEditingController();
  // Listas de datos para los selectores
  @override
  List<Musculo> _musculos = [];
  @override
  List<Equipamiento> _equipamientos = [];
  @override
  List<Categoria> _categorias = [];
  // Variables para los valores seleccionados
  @override
  Musculo? _musculoPrimarioSeleccionado;
  @override
  Musculo? _musculoSecundarioSeleccionado;
  @override
  Equipamiento? _equipamientoSeleccionado;
  @override
  Categoria? _categoriaSeleccionada;
  bool _mostrarFiltrosAvanzados = false;
  @override
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    // Cálculo del ancho de los filtros
    final double paddingHorizontal = 16.0;
    final double spacing = 8.0;
    final double filterWidth = (MediaQuery.of(context).size.width - (paddingHorizontal * 2) - spacing) / 2;

    // Widgets de filtros
    Widget filtrosBasicos = Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        SizedBox(
          width: filterWidth,
          child: _buildFilterTile(
            title: 'Músculo',
            subtitle: _musculoPrimarioSeleccionado?.titulo ?? 'Cualquiera',
            imageUrl: _musculoPrimarioSeleccionado?.imagen ?? '',
            onTap: _seleccionarMusculoPrimario,
          ),
        ),
        SizedBox(
          width: filterWidth,
          child: _buildFilterTile(
            title: 'Equipo',
            subtitle: _equipamientoSeleccionado?.titulo ?? 'Cualquiera',
            imageUrl: _equipamientoSeleccionado?.imagen ?? '',
            onTap: _seleccionarEquipamiento,
          ),
        ),
      ],
    );

    Widget filtrosAvanzados = Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        // Filtros básicos
        SizedBox(
          width: filterWidth,
          child: _buildFilterTile(
            title: 'Músculo',
            subtitle: _musculoPrimarioSeleccionado?.titulo ?? 'Cualquiera',
            imageUrl: _musculoPrimarioSeleccionado?.imagen ?? '',
            onTap: _seleccionarMusculoPrimario,
          ),
        ),
        SizedBox(
          width: filterWidth,
          child: _buildFilterTile(
            title: 'Equipo',
            subtitle: _equipamientoSeleccionado?.titulo ?? 'Cualquiera',
            imageUrl: _equipamientoSeleccionado?.imagen ?? '',
            onTap: _seleccionarEquipamiento,
          ),
        ),
        // Filtros avanzados
        SizedBox(
          width: filterWidth,
          child: _buildFilterTile(
            title: 'Secundario',
            subtitle: _musculoSecundarioSeleccionado?.titulo ?? 'Cualquiera',
            imageUrl: _musculoSecundarioSeleccionado?.imagen ?? '',
            onTap: _seleccionarMusculoSecundario,
          ),
        ),
        SizedBox(
          width: filterWidth,
          child: _buildFilterTile(
            title: 'Categoría',
            subtitle: _categoriaSeleccionada?.titulo ?? 'Cualquiera',
            imageUrl: _categoriaSeleccionada?.imagen ?? '',
            onTap: _seleccionarCategoria,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buscar Ejercicios'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
              child: Column(
                children: [
                  // Fila con el campo "Nombre" y el botón de filtros
                  Row(
                    children: [
                      // Campo de entrada "Nombre"
                      Expanded(
                        child: TextField(
                          controller: _nombreController,
                          style: const TextStyle(color: AppColors.textNormal),
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            labelStyle: TextStyle(color: AppColors.textNormal),
                          ),
                          onChanged: _onFilterChanged,
                        ),
                      ),
                      // Botón de "Filtros Avanzados"
                      IconButton(
                        icon: Icon(
                          _mostrarFiltrosAvanzados ? Icons.filter_alt_off : Icons.filter_alt,
                          color: AppColors.accentColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _mostrarFiltrosAvanzados = !_mostrarFiltrosAvanzados;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Uso de AnimatedCrossFade para los filtros
                  AnimatedCrossFade(
                    firstChild: filtrosBasicos,
                    secondChild: filtrosAvanzados,
                    crossFadeState: _mostrarFiltrosAvanzados ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                  const SizedBox(height: 10),
                  // Lista de ejercicios encontrados
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20.0),
                          topRight: Radius.circular(20.0),
                        ),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: _ejercicios.length + 1, // +1 para el espacio extra
                              itemBuilder: (context, index) {
                                if (index == _ejercicios.length) {
                                  // Espacio extra al final para evitar que el botón tape el último ítem
                                  return const SizedBox(height: 80);
                                }
                                final ejercicio = _ejercicios[index];
                                final isSelected = _ejerciciosSeleccionados.contains(ejercicio);

                                // Obtener los músculos tipo "P"
                                final primaryMuscles = ejercicio.musculosInvolucrados.where((m) => m.tipo == 'P').map((m) => m.musculo.titulo).join(', ');

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.mutedAdvertencia : AppColors.cardBackground,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      // Imagen con icono de información, igualando estilo a sesion_listado_ejercicios.dart
                                      GestureDetector(
                                        onTap: () async {
                                          final loadedEjercicio = await Ejercicio.loadById(ejercicio.id);
                                          Navigator.push(
                                            // ignore: use_build_context_synchronously
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EjercicioDetallePage(
                                                ejercicio: loadedEjercicio,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(20.0),
                                              child: AnimatedImage(
                                                ejercicio: ejercicio,
                                                width: 105,
                                                height: 70,
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 4,
                                              right: 4,
                                              child: Icon(
                                                Icons.info_outline,
                                                color: AppColors.mutedAdvertencia,
                                                size: 16,
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(1.0, 1.0),
                                                    blurRadius: 3.0,
                                                    color: Colors.black,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Información del ejercicio con comportamiento independiente
                                      Expanded(
                                        child: InkWell(
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                _ejerciciosSeleccionados.remove(ejercicio);
                                              } else {
                                                _ejerciciosSeleccionados.add(ejercicio);
                                              }
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Nueva fila con el nombre y el widget pills a la derecha
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start, // Forzar alineación superior
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        ejercicio.nombre,
                                                        style: TextStyle(
                                                          color: isSelected ? AppColors.background : AppColors.textNormal,
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment: Alignment.topRight,
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(right: 8.0),
                                                        child: buildDificultadPills(int.parse(ejercicio.dificultad.titulo), 6, 12),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  primaryMuscles.isNotEmpty ? primaryMuscles : 'Sin músculos principales',
                                                  style: TextStyle(
                                                    color: isSelected ? AppColors.background : AppColors.textMedium,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  )
                ],
              ),
            ),
            // Botón "Añadir" flotante en la parte inferior
            if (_ejerciciosSeleccionados.isNotEmpty)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: ElevatedButton(
                  onPressed: _agregarEjerciciosSeleccionados,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppColors.accentColor,
                  ),
                  child: Text(
                    'Añadir (${_ejerciciosSeleccionados.length})',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
