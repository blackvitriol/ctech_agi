import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onProfileTap;

  const AnimatedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onProfileTap,
  });

  @override
  State<AnimatedAppBar> createState() => _AnimatedAppBarState();

  @override
  Size get preferredSize {
    return const Size.fromHeight(kToolbarHeight);
  }
}

class _AnimatedAppBarState extends State<AnimatedAppBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159, // Full rotation in radians
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: SweepGradient(
                  center: Alignment.center,
                  startAngle: _rotationAnimation.value,
                  endAngle: _rotationAnimation.value + 2 * 3.14159,
                  colors: [
                    Colors.blue.withOpacity(0.8),
                    Colors.purple.withOpacity(0.6),
                    Colors.green.withOpacity(0.7),
                    Colors.orange.withOpacity(0.5),
                    Colors.blue.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
