import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
import '/../../data/providers/nasabah_provider.dart';
import '/../../data/providers/auth_provider.dart';
import '../../widgets/common/lonceng_notifikasi.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback? onGoToTukar;
  const HomeScreen({super.key, this.onGoToTukar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(unreadNotifCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(dashboardProvider.notifier).fetch(),
          child: CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                floating: true,
                backgroundColor: AppColors.background,
                elevation: 0,
                scrolledUnderElevation: 0,
                leadingWidth: 56,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDim,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 24,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'Bank Sampah',
                  style: AppTextStyles.headlineMd.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: AppColors.textMain,
                          ),
                          onPressed: () {},
                        ),
                        if (unread > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Poin Card
                      dashboard.isLoading
                          ? _PoinCardSkeleton()
                          : _PoinCard(
                              totalPoin: dashboard.totalPoinFormatted,
                              nilaiRupiah: dashboard.nilaiRupiah,
                            ),

                      const SizedBox(height: 16),

                      // Quick Access
                      Row(
                        children: [
                          Expanded(child: _KatalogCard()),
                          const SizedBox(width: 12),
                          Expanded(child: _TukarPoinCard(onTap: onGoToTukar)),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Transaksi Terakhir
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaksi Terakhir',
                            style: AppTextStyles.headlineMd.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              children: [
                                Text(
                                  'Lihat Semua',
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (dashboard.isLoading)
                        ...List.generate(
                          3,
                          (_) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _TransaksiSkeleton(),
                          ),
                        )
                      else if (dashboard.transaksiTerakhir.isEmpty)
                        _EmptyTransaksi()
                      else
                        ...dashboard.transaksiTerakhir.map((t) {
                          final isCredit = (t['tipe'] as String?) == 'setoran';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _TransactionItem(
                              title: t['judul'] as String? ?? '-',
                              subtitle: t['waktu'] as String? ?? '-',
                              poin: t['poin'] as String? ?? '0',
                              isCredit: isCredit,
                            ),
                          );
                        }),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub Widgets ───────────────────────────────────────────────────────────────

class _PoinCard extends StatelessWidget {
  final String totalPoin;
  final String nilaiRupiah;
  const _PoinCard({required this.totalPoin, required this.nilaiRupiah});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D35), Color(0xFF006948)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.wallet_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TOTAL POIN',
                style: AppTextStyles.labelSm.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            totalPoin,
            style: AppTextStyles.dataDisplay.copyWith(
              fontSize: 40,
              letterSpacing: -1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sync_alt_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Setara dengan $nilaiRupiah',
                  style: AppTextStyles.bodySm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PoinCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _TransaksiSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _EmptyTransaksi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: AppColors.outline,
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada transaksi',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _KatalogCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/katalog'),
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.recycling_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const Spacer(),
            Text(
              'Katalog Harga',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Lihat daftar harga sampah',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.secondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TukarPoinCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _TukarPoinCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const Spacer(),
            Text(
              'Tukar Poin',
              style: AppTextStyles.labelMd.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text('Klaim hadiahmu', style: AppTextStyles.bodySm),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String poin;
  final bool isCredit;

  const _TransactionItem({
    required this.title,
    required this.subtitle,
    required this.poin,
    required this.isCredit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCredit
                  ? AppColors.successContainer
                  : AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add_rounded : Icons.remove_rounded,
              color: isCredit ? AppColors.success : AppColors.outline,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySm),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                poin,
                style: AppTextStyles.labelMd.copyWith(
                  color: isCredit ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text('Poin', style: AppTextStyles.bodySm.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
