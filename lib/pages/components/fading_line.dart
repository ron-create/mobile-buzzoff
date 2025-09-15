import 'package:flutter/material.dart';

class FadingLine extends StatelessWidget {
  final double height;
  final Color color;
  final double opacity;

  const FadingLine({
    super.key,
    this.height = 2.0,
    this.color = Colors.blue,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withOpacity(0),
            color.withOpacity(opacity),
            color.withOpacity(opacity),
            color.withOpacity(0),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
    );
  }
}
