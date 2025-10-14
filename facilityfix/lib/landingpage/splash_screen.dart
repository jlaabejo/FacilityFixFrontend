import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onDone});
  final VoidCallback? onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF426CC2);
  static const double _logoSize = 200;

  late final AnimationController _c;
  late final Animation<double> _logoOpacity; // 0 → 1 (first)
  late final Animation<double> _circleBounce; // 0 → logo size (bounce)
  late final Animation<double> _circleExpand; // logo → screen
  late final Animation<Color?> _bgColor; // white → blue (final)

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );

    // Animation timeline
    _logoOpacity = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.00, 0.30, curve: Curves.easeIn),
    );

    _circleBounce = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.30, 0.60, curve: Curves.elasticOut),
    );

    _circleExpand = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.60, 0.90, curve: Curves.easeInOut),
    );

    _bgColor = ColorTween(begin: Colors.white, end: _blue).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.90, 1.00, curve: Curves.easeIn),
      ),
    );

    _c.forward().whenComplete(() => widget.onDone?.call());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // 1) Circle bounces up to the same size as logo
          final double bounceDiameter = _circleBounce.value * _logoSize;

          // 2) Circle expands to fill the screen
          final double diag = sqrt(w * w + h * h);
          final double expandDiameter =
              _logoSize + _circleExpand.value * (diag - _logoSize);

          // Smooth transition between phases
          final double circleDiameter = max(bounceDiameter, expandDiameter);

          return Container(
            width: w,
            height: h,
            color: _bgColor.value ?? Colors.white,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Blue circle behind the logo
                Container(
                  width: circleDiameter,
                  height: circleDiameter,
                  decoration: const BoxDecoration(
                    color: _blue,
                    shape: BoxShape.circle,
                  ),
                ),

                // Centered logo
                Opacity(
                  opacity: _logoOpacity.value,
                  child: SizedBox(
                    width: _logoSize,
                    height: _logoSize,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
