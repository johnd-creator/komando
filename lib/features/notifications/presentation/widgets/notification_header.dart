import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class NotificationHeader extends StatelessWidget {
  const NotificationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 328,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/bg-asset.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0069D7).withValues(alpha: 0.88),
                  const Color(0xFF075EC4).withValues(alpha: 0.80),
                  const Color(0xFF064FA8).withValues(alpha: 0.90),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Badge(
                      smallSize: 10,
                      backgroundColor: const Color(0xFFFFC928),
                      child: IconButton(
                        onPressed: () {},
                        tooltip: 'Notifikasi',
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.42),
                          ),
                        ),
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Image.asset(
                          'assets/logo.png',
                          width: 74,
                          height: 74,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '1Komando',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Serikat Pekerja PLN IP Services',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          '',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
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
