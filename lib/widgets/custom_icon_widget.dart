import 'package:flutter/material.dart';

class CustomIconWidget extends StatelessWidget {
  final IconData iconData;
  final double size;
  final Color color;

  CustomIconWidget({
    required this.iconData,
    this.size = 24.0,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      iconData,
      size: size,
      color: color,
    );
  }
}
