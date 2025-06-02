part of 'ejercicios_buscar.dart';

// Declare abstract getters and setters for private fields used in the mixin.
abstract class _EjerciciosBuscarFields {
  List<Musculo> get _musculos;
  set _musculos(List<Musculo> value);

  List<Equipamiento> get _equipamientos;
  set _equipamientos(List<Equipamiento> value);

  List<Categoria> get _categorias;
  set _categorias(List<Categoria> value);

  // ignore: unused_element
  bool get _isLoading;
  set _isLoading(bool value);

  TextEditingController get _nombreController;

  // ignore: unused_element
  List<Ejercicio> get _ejercicios;
  set _ejercicios(List<Ejercicio> value);

  List<Ejercicio> get _ejerciciosSeleccionados;

  Timer? get _debounce;
  set _debounce(Timer? value);

  Musculo? get _musculoPrimarioSeleccionado;
  set _musculoPrimarioSeleccionado(Musculo? value);

  Musculo? get _musculoSecundarioSeleccionado;
  set _musculoSecundarioSeleccionado(Musculo? value);

  Categoria? get _categoriaSeleccionada;
  set _categoriaSeleccionada(Categoria? value);

  Equipamiento? get _equipamientoSeleccionado;
  set _equipamientoSeleccionado(Equipamiento? value);
}

mixin EjerciciosBuscarLogic on State<EjerciciosBuscarPage> implements _EjerciciosBuscarFields {
  @override
  void initState() {
    super.initState();
    _loadFiltrosData();
  }

  Future<void> _loadFiltrosData() async {
    final data = await ModeloDatos().getDatosFiltrosEjercicios();
    if (data != null) {
      setState(() {
        // Convertir y ordenar la lista de músculos alfabéticamente por título
        _musculos = (data['musculos'] as List).map((json) => Musculo.fromJson(json)).toList()..sort((a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()));

        // Convertir y ordenar la lista de equipamientos alfabéticamente por título
        _equipamientos = (data['equipamientos'] as List).map((json) => Equipamiento.fromJson(json)).toList()..sort((a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()));

        // Convertir y ordenar la lista de categorías alfabéticamente por título
        _categorias = (data['categorias'] as List).map((json) => Categoria.fromJson(json)).toList()..sort((a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()));
      });
      _buscarEjercicios();
    } else {
      // Manejar error si es necesario
    }
  }

  Future<void> _buscarEjercicios() async {
    setState(() {
      _isLoading = true;
    });
    final filtros = {
      'nombre': _nombreController.text,
      'musculo_primario': _musculoPrimarioSeleccionado != null ? _musculoPrimarioSeleccionado!.id.toString() : '',
      'musculo_secundario': _musculoSecundarioSeleccionado != null ? _musculoSecundarioSeleccionado!.id.toString() : '',
      'categoria': _categoriaSeleccionada != null ? _categoriaSeleccionada!.id.toString() : '',
      'equipamiento': _equipamientoSeleccionado != null ? _equipamientoSeleccionado!.id.toString() : '',
    };
    // Cast filtros to Map<String, String>
    final nuevosEjercicios = await ModeloDatos().buscarEjercicios(filtros.cast<String, String>());
    if (nuevosEjercicios != null) {
      final ejerciciosFiltrados = nuevosEjercicios.where((ejercicio) => !_ejerciciosSeleccionados.contains(ejercicio)).toList();
      setState(() {
        _ejercicios = ejerciciosFiltrados;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged([String? _]) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _buscarEjercicios);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<T?> _mostrarSelector<T>({
    required String titulo,
    required List<T> items,
    required String Function(T) itemAsString,
    required String Function(T)? imageUrl,
    T? valorSeleccionado,
  }) async {
    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Para permitir el borde redondeado
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.mutedAdvertencia,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ListTile(
                          leading: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.clear, color: AppColors.textMedium),
                          ),
                          title: const Text(
                            'Cualquiera',
                            style: TextStyle(color: AppColors.textMedium),
                          ),
                          onTap: () => Navigator.pop(context, null),
                        ),
                        ...items.map((T item) {
                          return ListTile(
                            leading: const Icon(Icons.circle, size: 16, color: AppColors.textMedium),
                            title: Text(
                              itemAsString(item),
                              style: const TextStyle(color: AppColors.textMedium),
                            ),
                            onTap: () => Navigator.pop(context, item),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _seleccionarMusculoPrimario() async {
    final Musculo? musculoSeleccionado = await _mostrarSelector<Musculo>(
      titulo: 'Seleccione Músculo Principal',
      items: _musculos,
      itemAsString: (Musculo m) => m.titulo,
      imageUrl: (Musculo m) => m.imagen,
      valorSeleccionado: _musculoPrimarioSeleccionado,
    );
    setState(() {
      _musculoPrimarioSeleccionado = musculoSeleccionado;
    });
    _onFilterChanged();
  }

  void _seleccionarMusculoSecundario() async {
    final Musculo? musculoSeleccionado = await _mostrarSelector<Musculo>(
      titulo: 'Seleccione Músculo Secundario',
      items: _musculos,
      itemAsString: (Musculo m) => m.titulo,
      imageUrl: (Musculo m) => m.imagen,
      valorSeleccionado: _musculoSecundarioSeleccionado,
    );
    setState(() {
      _musculoSecundarioSeleccionado = musculoSeleccionado;
    });
    _onFilterChanged();
  }

  void _seleccionarCategoria() async {
    final Categoria? categoriaSeleccionada = await _mostrarSelector<Categoria>(
      titulo: 'Seleccione Categoría',
      items: _categorias,
      itemAsString: (Categoria c) => c.titulo,
      imageUrl: (Categoria c) => c.imagen,
      valorSeleccionado: _categoriaSeleccionada,
    );
    setState(() {
      _categoriaSeleccionada = categoriaSeleccionada;
    });
    _onFilterChanged();
  }

  void _seleccionarEquipamiento() async {
    final Equipamiento? equipamientoSeleccionado = await _mostrarSelector<Equipamiento>(
      titulo: 'Seleccione Equipamiento',
      items: _equipamientos,
      itemAsString: (Equipamiento e) => e.titulo,
      imageUrl: (Equipamiento e) => e.imagen,
      valorSeleccionado: _equipamientoSeleccionado,
    );
    setState(() {
      _equipamientoSeleccionado = equipamientoSeleccionado;
    });
    _onFilterChanged();
  }

  Widget _buildFilterTile({
    required String title,
    required String subtitle,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    final bool tieneValor = subtitle.trim().isNotEmpty && subtitle.trim().toLowerCase() != 'cualquiera';

    // Mantener altura uniforme para todos los filtros, independientemente de si tienen valor o no
    const double valorFontSize = 14;

    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 22);
                    },
                  ),
                )
              else
                const Icon(Icons.arrow_drop_down, color: AppColors.textNormal, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textNormal,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      tieneValor ? subtitle : 'Cualquiera',
                      style: TextStyle(
                        color: tieneValor ? AppColors.accentColor : AppColors.textMedium,
                        fontSize: valorFontSize,
                        fontWeight: tieneValor ? FontWeight.bold : FontWeight.normal,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _agregarEjerciciosSeleccionados() async {
    bool errorOcurrido = false;
    if (widget.sesion != null) {
      for (final ejercicio in _ejerciciosSeleccionados) {
        final nuevoEjercicio = await widget.sesion!.insertarEjercicioPersonalizado(ejercicio);
        if (nuevoEjercicio == 0) {
          errorOcurrido = true;
          break;
        }
      }
    } else if (widget.entrenamiento != null) {
      for (final ejercicio in _ejerciciosSeleccionados) {
        final nuevo = await widget.entrenamiento!.insertarEjercicioRealizado(ejercicio);
        if (nuevo == null) {
          errorOcurrido = true;
          break;
        }
        await nuevo.insertSerieRealizada();
      }
    }
    if (errorOcurrido) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al agregar los ejercicios.')),
      );
    } else {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }
}
