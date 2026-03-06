// ============================================================
// SiberKalkan - Animasyonlu Kalkan Widget
// Dosya Yolu: lib/widgets/shield_widget.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:siber_kalkan/utils/constants.dart';

class ShieldWidget extends StatefulWidget {
  final bool isSafe;
  final double size;

  const ShieldWidget({
    super.key,
    required this.isSafe,
    this.size = 200,
  });

  @override
  State<ShieldWidget> createState() => _ShieldWidgetState();
}

class _ShieldWidgetState extends State<ShieldWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isSafe ? AppColors.shieldSafe : AppColors.shieldDanger;
    final statusText = widget.isSafe ? 'Güvenli' : 'Tehdit Tespit Edildi!';
    final statusIcon = widget.isSafe ? Icons.shield : Icons.warning_rounded;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isSafe ? 1.0 : _pulseAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kalkan Dairesi
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  statusIcon,
                  size: widget.size * 0.55,
                  color: color,
                ),
              ),
              const SizedBox(height: 24),

              // Durum Metni
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                child: Text(statusText),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// AnimatedBuilder — AnimatedWidget yerine builder pattern
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimatedPulseWidget(
      animation: animation,
      builder: builder,
    );
  }
}

class _AnimatedPulseWidget extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const _AnimatedPulseWidget({
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}

