import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/widgets/section_header.dart';
import '../bloc/dues_bloc.dart';
import '../bloc/dues_event.dart';
import '../bloc/dues_state.dart';
import '../widgets/dues_empty_view.dart';
import '../widgets/dues_error_view.dart';
import '../widgets/dues_loading_view.dart';
import '../widgets/dues_no_member_view.dart';
import '../widgets/dues_payment_card.dart';
import '../widgets/dues_summary_section.dart';

class MyDuesScreen extends StatefulWidget {
  const MyDuesScreen({super.key});

  @override
  State<MyDuesScreen> createState() => _MyDuesScreenState();
}

class _MyDuesScreenState extends State<MyDuesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    context.read<DuesBloc>().add(LoadMyDues());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocConsumer<DuesBloc, DuesState>(
        listener: (context, state) {
          // Trigger animation once when data loads — not inside builder
          if (state.status == DuesStatus.success) {
            _animationController.forward();
          }
        },
        builder: (context, state) {
          if (state.status == DuesStatus.loading ||
              state.status == DuesStatus.initial) {
            return const DuesLoadingView();
          }
          if (state.status == DuesStatus.error) {
            return DuesErrorView(
              message: state.errorMessage ?? 'Terjadi kesalahan',
              onRetry: () => context.read<DuesBloc>().add(LoadMyDues()),
            );
          }
          if (!state.hasMember) {
            return const DuesNoMemberView();
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<DuesBloc>().add(RefreshMyDues()),
            child: CustomScrollView(
              slivers: [
                const FeaturePageHeader(
                  title: 'Iuran Saya',
                  icon: Icons.account_balance_wallet_outlined,
                  subtitle: 'Riwayat pembayaran iuran anggota',
                ),
                if (state.summary != null)
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                      ),
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(
                                  0.0,
                                  0.5,
                                  curve: Curves.easeOut,
                                ),
                              ),
                            ),
                        child: DuesSummarySection(
                          summary: state.summary!,
                          defaultAmount: state.defaultAmount,
                        ),
                      ),
                    ),
                  ),
                if (state.payments.isEmpty)
                  SliverFillRemaining(
                    child: DuesEmptyView(
                      animationController: _animationController,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList.builder(
                      itemCount: state.payments.length,
                      itemBuilder: (context, index) {
                        final card = DuesPaymentCard(
                          payment: state.payments[index],
                          isLast: index == state.payments.length - 1,
                        );
                        // Only animate first 10 items — skip animation for items below the fold
                        if (index >= 10) return card;
                        return FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              (0.3 + (index * 0.05)).clamp(0.0, 1.0),
                              (0.5 + (index * 0.05)).clamp(0.0, 1.0),
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.15),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(
                                      (0.3 + (index * 0.05)).clamp(0.0, 1.0),
                                      (0.5 + (index * 0.05)).clamp(0.0, 1.0),
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                ),
                            child: card,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
