import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

class MedalCard extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData icon;
  final String value;
  final String units;
  final String date;
  final String type;

  static const double _aspectRatio = 0.75;

  const MedalCard({
    super.key,
    this.width,
    this.height,
    required this.icon,
    required this.value,
    required this.units,
    required this.date,
    required this.type,
  }) : assert((width != null) ^ (height != null), 'Debes proporcionar width o height, no ambos.');

  @override
  Widget build(BuildContext context) {
    final double w = width ?? (height! * _aspectRatio);
    final double h = height ?? (width! / _aspectRatio);

    final formattedValue = value.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );

    Color mainColor = AppColors.mutedAdvertencia;
    switch (type) {
      case 'blue':
        mainColor = AppColors.accentColor;
        break;
      case 'gold':
        mainColor = AppColors.mutedAdvertencia;
        break;
      case 'silver':
        mainColor = AppColors.mutedSilver;
        break;
      case 'bronze':
        mainColor = AppColors.mutedBronze;
        break;
      case 'disabled':
        mainColor = AppColors.cardBackground;
        break;
      default:
        mainColor = AppColors.mutedAdvertencia;
        break;
    }

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(Colors.white, mainColor, 0.7)!,
        Color.lerp(Colors.black, mainColor, 0.4)!,
      ],
    );

    return Container(
      width: w,
      height: h,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(Colors.white, mainColor, 0.95)!,
              Color.lerp(Colors.black, mainColor, 0.6)!,
            ],
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 0,
              offset: Offset(-1, -1),
            ),
            BoxShadow(
              color: AppColors.textNormal.withAlpha(75),
              blurRadius: 0,
              offset: Offset(1, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 35,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      icon,
                      size: w * 0.4,
                      color: Colors.black,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 0,
                          color: Colors.black.withAlpha(75),
                        ),
                        Shadow(
                          offset: Offset(-0.75, -0.75),
                          blurRadius: 2,
                          color: AppColors.textNormal.withAlpha(100),
                        ),
                      ],
                    ),
                    Icon(
                      icon,
                      size: w * 0.4,
                      color: AppColors.textNormal,
                    ),
                    ShaderMask(
                      shaderCallback: (Rect bounds) => gradient.createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Icon(
                        icon,
                        size: w * 0.4,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 40,
              child: SizedBox(
                width: w,
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGradientText(formattedValue, w * 0.15, gradient, mainColor),
                      _buildGradientText(units.toUpperCase(), w * 0.12, gradient, mainColor),
                    ],
                  ),
                ),
              ),
            ),
            if (date.isNotEmpty)
              Expanded(
                flex: 25,
                child: Center(
                  child: _buildGradientText(date.toUpperCase(), w * 0.12, gradient, mainColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientText(String text, double fontSize, Gradient gradient, Color shadowColor) {
    return Stack(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: shadowColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            height: 0.8,
            shadows: [
              Shadow(
                offset: Offset(0.5, 0.5),
                blurRadius: 0,
                color: Colors.black.withAlpha(80),
              ),
              Shadow(
                offset: Offset(-0.25, -0.25),
                blurRadius: 2,
                color: AppColors.textNormal.withAlpha(125),
              ),
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: (Rect bounds) => gradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              height: 0.8,
              color: shadowColor,
            ),
          ),
        ),
      ],
    );
  }
}
