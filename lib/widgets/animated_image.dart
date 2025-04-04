// ./lib/widgets/animated_image.dart

import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/ejercicio/ejercicio.dart';

class AnimatedImage extends StatefulWidget {
  final Ejercicio ejercicio;
  final double width;
  final double? height; // cambiado a opcional

  const AnimatedImage({
    Key? key,
    required this.ejercicio,
    required this.width,
    this.height,
  }) : super(key: key);

  @override
  _AnimatedImageState createState() => _AnimatedImageState();
}

class _AnimatedImageState extends State<AnimatedImage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool showFirstImage = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            showFirstImage = !showFirstImage;
          });
          _controller.forward(from: 0);
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ejercicio.imagenMovimiento.isNotEmpty) {
      return Image.network(
        widget.ejercicio.imagenMovimiento,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: AppColors.whiteText),
      );
    }

    final bool hasImagenUno = widget.ejercicio.imagenUno.isNotEmpty;
    final bool hasImagenDos = widget.ejercicio.imagenDos.isNotEmpty;

    if (hasImagenUno && !hasImagenDos) {
      return Image.network(
        widget.ejercicio.imagenUno,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: AppColors.whiteText),
      );
    }

    if (!hasImagenUno && hasImagenDos) {
      return Image.network(
        widget.ejercicio.imagenDos,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: AppColors.whiteText),
      );
    }

    return Image.network(
      showFirstImage ? widget.ejercicio.imagenUno : widget.ejercicio.imagenDos,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: AppColors.whiteText),
    );
  }
}
