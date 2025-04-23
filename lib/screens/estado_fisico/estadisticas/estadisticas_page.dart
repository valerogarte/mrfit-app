import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:intl/intl.dart';

/// Widget reutilizable para pintar cada tarjeta de estadística.
class StatItemCard extends StatelessWidget {
  final Widget image;
  final String title;
  final String subtitle;

  const StatItemCard({
    Key? key,
    required this.image,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            child: image,
          ),
          const SizedBox(height: 4),
          Container(
            width: 100,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 100,
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.mutedAdvertencia,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget genérico que encapsula un FutureBuilder con scroll horizontal.
class FutureHorizontalList<T> extends StatelessWidget {
  final Future<T> future;
  final String errorMessage;
  final String emptyMessage;
  final Widget Function(T data) itemBuilder;

  const FutureHorizontalList({
    Key? key,
    required this.future,
    required this.errorMessage,
    required this.emptyMessage,
    required this.itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: FutureBuilder<T>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(errorMessage));
          } else if (!snapshot.hasData || (snapshot.data is Iterable && (snapshot.data as Iterable).isEmpty)) {
            return Center(child: Text(emptyMessage));
          }
          return itemBuilder(snapshot.data!);
        },
      ),
    );
  }
}

class EstadisticasPage extends ConsumerStatefulWidget {
  const EstadisticasPage({Key? key}) : super(key: key);

  @override
  ConsumerState<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends ConsumerState<EstadisticasPage> {
  late Future<Map<String, double>> _musculosUsadosFuture;
  late Future<Map<int, Map<String, dynamic>>> _ejerciciosMasUsadosFuture;

  @override
  void initState() {
    super.initState();
    final usuario = ref.read(usuarioProvider);
    _musculosUsadosFuture = usuario.getMusculosUsadosEnLastEntrenamientos();
    _ejerciciosMasUsadosFuture = usuario.getEjerciciosMasUsados();
  }

  Widget _buildHeader(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      alignment: Alignment.center, // Centra el contenido del contenedor
      child: Text(
        title,
        textAlign: TextAlign.center, // Centra el texto
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Sección: Músculos menos usados
        _buildHeader('Músculos menos usados'),
        FutureHorizontalList<Map<String, double>>(
          future: _musculosUsadosFuture,
          errorMessage: 'Error al cargar datos de músculos',
          emptyMessage: 'No hay datos de músculos disponibles',
          itemBuilder: (musculosUsados) {
            final muscleList = musculosUsados.entries.toList();
            muscleList.sort((a, b) => a.value.compareTo(b.value));
            final mid = muscleList.length ~/ 2;
            final menosUsados = muscleList.sublist(0, mid);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: menosUsados.map((entry) {
                  return StatItemCard(
                    image: Image.asset(
                      'assets/images/cuerpohumano/cuerpohumano-frontal.png',
                      fit: BoxFit.cover,
                    ),
                    title: entry.key[0].toUpperCase() + entry.key.substring(1),
                    subtitle: '${NumberFormat('#,##0.00', 'es_ES').format(entry.value)}%',
                  );
                }).toList(),
              ),
            );
          },
        ),
        // Sección: Músculos más usados
        _buildHeader('Músculos más usados'),
        FutureHorizontalList<Map<String, double>>(
          future: _musculosUsadosFuture,
          errorMessage: 'Error al cargar datos de músculos',
          emptyMessage: 'No hay datos de músculos disponibles',
          itemBuilder: (musculosUsados) {
            final muscleList = musculosUsados.entries.toList();
            muscleList.sort((a, b) => a.value.compareTo(b.value));
            final mid = muscleList.length ~/ 2;
            final masUsados = muscleList.sublist(mid).reversed.toList();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: masUsados.map((entry) {
                  return StatItemCard(
                    image: Image.asset(
                      'assets/images/cuerpohumano/cuerpohumano-frontal.png',
                      fit: BoxFit.cover,
                    ),
                    title: entry.key[0].toUpperCase() + entry.key.substring(1),
                    subtitle: '${NumberFormat('#,##0.00', 'es_ES').format(entry.value)}%',
                  );
                }).toList(),
              ),
            );
          },
        ),
        // Sección: Ejercicios más usados
        _buildHeader('Ejercicios más usados'),
        FutureHorizontalList<Map<int, Map<String, dynamic>>>(
          future: _ejerciciosMasUsadosFuture,
          errorMessage: 'Error al cargar datos de ejercicios',
          emptyMessage: 'No hay datos de ejercicios disponibles',
          itemBuilder: (ejerciciosMasUsados) {
            final sortedEjercicios = ejerciciosMasUsados.entries.toList()..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sortedEjercicios.map((entry) {
                  final ejercicio = entry.value['ejercicio'];
                  final count = entry.value['count'];
                  return StatItemCard(
                    image: Image.network(
                      ejercicio.imagenUno,
                      fit: BoxFit.cover,
                    ),
                    title: ejercicio.nombre,
                    subtitle: '$count veces',
                  );
                }).toList(),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
