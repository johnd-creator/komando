import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/widgets/section_header.dart';

class DuesNoMemberView extends StatelessWidget {
  const DuesNoMemberView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const FeaturePageHeader(
          title: 'Iuran Saya',
          icon: Icons.account_balance_wallet_outlined,
        ),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.grey.shade200, Colors.grey.shade100],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_off_outlined,
                      size: 48,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Profil Belum Terhubung',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(
                      'Hubungi admin untuk menghubungkan akun Anda dengan data anggota.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
