import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDark;

  const AppLogo({
    super.key,
    this.size = 36.0,
    this.showText = true,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Modern minimal logo mark: Letter P + speech bubble / globe gradient icon
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withOpacity(0.8),
                const Color(0xFF6366F1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Stylized 'P' & translation icon
              Text(
                'P',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.58,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              Positioned(
                right: size * 0.15,
                bottom: size * 0.15,
                child: Container(
                  width: size * 0.26,
                  height: size * 0.26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.translate_rounded,
                      size: size * 0.18,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.35),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: size * 0.65,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                fontFamily: 'Inter',
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              children: [
                const TextSpan(text: 'Poly'),
                TextSpan(
                  text: 'Lingo',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
