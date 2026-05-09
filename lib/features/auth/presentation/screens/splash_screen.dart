import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 0.8,
                focal: Alignment(0, -0.3),
                focalRadius: 0.1,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xF2FFFFFF),
                  Color(0xE6FFFFFF),
                  Color(0xCCFFFFFF),
                  Color(0x99FFFFFF),
                  Color(0x55FFFFFF),
                  Color(0x22FFFFFF),
                  Colors.transparent,
                ],
                stops: [
                  0.0,
                  0.10,
                  0.20,
                  0.35,
                  0.55,
                  0.75,
                  0.90,
                  1.0,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 92,
                    height: 92,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1Komando',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: const Color(0xFF061B4E),
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Serikat Pekerja PLN Indonesia Power Services',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF061B4E).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Color(0xFF061B4E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
