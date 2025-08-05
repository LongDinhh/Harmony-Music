import 'dart:ui';
import 'package:flutter/material.dart';

class GlassWrapper extends StatelessWidget {
  final Widget child;
  final double blurIntensity;
  final Color backgroundColor;
  final double opacity;
  final BorderRadius? borderRadius;
  final Border? border;

  const GlassWrapper({
    super.key,
    required this.child,
    this.blurIntensity = 10.0,
    this.backgroundColor = Colors.white,
    this.opacity = 0.1,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurIntensity,
          sigmaY: blurIntensity,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: opacity),
            borderRadius: borderRadius,
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}
