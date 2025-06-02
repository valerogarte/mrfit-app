import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

class BlinkingBar extends StatefulWidget {
  final double width;
  final double height;
  const BlinkingBar({super.key, required this.width, required this.height});

  @override
  BlinkingBarState createState() => BlinkingBarState();
}

class BlinkingBarState extends State<BlinkingBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(Tween(begin: 0.3, end: 1.0)),
      child: Container(
        width: widget.width,
        height: widget.height,
        color: AppColors.textNormal,
      ),
    );
  }
}
