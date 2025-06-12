// ./lib/widgets/animated_image.dart

import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';

class AnimatedImage extends StatefulWidget {
  final Ejercicio ejercicio;
  final double width;
  final double? height;
  final bool showCopyRight;

  const AnimatedImage({
    super.key,
    required this.ejercicio,
    required this.width,
    this.height,
    this.showCopyRight = false,
  });

  @override
  AnimatedImageState createState() => AnimatedImageState();
}

class AnimatedImageState extends State<AnimatedImage> with SingleTickerProviderStateMixin {
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

  /// Devuelve un widget fallback del tamaño de la imagen, con "MrFit" centrado y tamaño de fuente adaptativo.
  Widget _mrFitFallbackTitle(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
            children: [
              TextSpan(text: 'Mr', style: const TextStyle(color: AppColors.mutedAdvertencia)),
              TextSpan(text: 'Fit', style: const TextStyle(color: AppColors.textNormal)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (widget.ejercicio.imagenMovimiento.isNotEmpty) {
      imageWidget = Image.network(
        widget.ejercicio.imagenMovimiento,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) => Center(child: _mrFitFallbackTitle(context)),
      );
    } else {
      final bool hasImagenUno = widget.ejercicio.imagenUno.isNotEmpty;
      final bool hasImagenDos = widget.ejercicio.imagenDos.isNotEmpty;

      if (hasImagenUno && !hasImagenDos) {
        imageWidget = Image.network(
          widget.ejercicio.imagenUno,
          width: widget.width,
          height: widget.height,
          errorBuilder: (context, error, stackTrace) => Center(child: _mrFitFallbackTitle(context)),
        );
      } else if (!hasImagenUno && hasImagenDos) {
        imageWidget = Image.network(
          widget.ejercicio.imagenDos,
          width: widget.width,
          height: widget.height,
          errorBuilder: (context, error, stackTrace) => Center(child: _mrFitFallbackTitle(context)),
        );
      } else {
        imageWidget = Image.network(
          showFirstImage ? widget.ejercicio.imagenUno : widget.ejercicio.imagenDos,
          width: widget.width,
          height: widget.height,
          errorBuilder: (context, error, stackTrace) => Center(child: _mrFitFallbackTitle(context)),
        );
      }
    }

    if (widget.showCopyRight) {
      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          imageWidget,
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(125), // Fondo negro con 50% de transparencia
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20), // Esquina superior derecha redondeada
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '© ${widget.ejercicio.imagenCopyright}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          fontSize: 8,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(0, 0),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8), // Espacio horizontal después del texto
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return imageWidget;
    }
  }
}
