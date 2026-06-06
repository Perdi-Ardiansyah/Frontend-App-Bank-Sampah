import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
import '/../../data/providers/nasabah_provider.dart';
import '/../../data/models/transaksi_model.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/lonceng_notifikasi.dart';

class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key});

  @override
  ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        ref.read(riwayatProvider.notifier).fetchPenukaran();
      } else {
        ref.read(riwayatProvider.notifier).fetchSetoran();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riwayatProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      
      // ── APPBAR STANDAR KITA ──
      appBar: AppBar(
        title: Text(
          'Bank Sampah',
          style: AppTextStyles.headlineMd.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: const [
          LoncengNotifikasi(),
        ],
      ),
      
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _tabController.index == 0
            ? ref.read(riwayatProvider.notifier).fetchSetoran()
            : ref.read(riwayatProvider.notifier).fetchPenukaran(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Riwayat Aktivitas',
                style: AppTextStyles.headlineLg.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),

              // Saldo Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Saldo Poin',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          state.totalPoinFormatted,
                          style: AppTextStyles.dataDisplay.copyWith(
                            color: AppColors.textMain,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Pts',
                            style: AppTextStyles.bodyLg.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            color: AppColors.success,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            state.poinBulanIniFormatted,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.successText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelStyle: AppTextStyles.labelMd,
                  unselectedLabelStyle: AppTextStyles.bodyMd,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  tabs: const [
                    Tab(text: 'Riwayat Setoran'),
                    Tab(text: 'Riwayat Penukaran'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Loading
              if (state.isLoading)
                ...List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDim,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )
              // Setoran list
              else if (_tabController.index == 0) ...[
                if (state.setoran.isEmpty)
                  const _EmptyState(label: 'Belum ada riwayat setoran')
                else
                  ...state.setoran.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SetoranItem(item: s),
                    ),
                  ),
              ]
              // Penukaran list
              else ...[
                if (state.penukaran.isEmpty)
                  const _EmptyState(label: 'Belum ada riwayat penukaran')
                else
                  ...state.penukaran.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PenukaranItem(item: p),
                    ),
                  ),
              ],

              const SizedBox(height: 16),

              // Pagination
              if (!state.isLoading && state.lastPage > 1)
                _PaginationRow(
                  currentPage: state.currentPage,
                  lastPage: state.lastPage,
                  onPageChange: (p) {
                    if (_tabController.index == 0) {
                      ref.read(riwayatProvider.notifier).fetchSetoran(page: p);
                    } else {
                      ref.read(riwayatProvider.notifier).fetchPenukaran(page: p);
                    }
                  },
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

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
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetoranItem extends StatelessWidget {
  final SetoranModel item;
  const _SetoranItem({required this.item});

  TransactionStatus get _status {
    switch (item.status) {
      case 'selesai':
        return TransactionStatus.selesai;
      case 'pending':
        return TransactionStatus.pending;
      default:
        return TransactionStatus.cancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.status == 'selesai'
                  ? AppColors.primary
                  : AppColors.surfaceDim,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.recycling_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.kategoriNama,
                      style: AppTextStyles.labelMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.poinFormatted,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.beratFormatted} • ${item.lokasiTps ?? ""}',
                  style: AppTextStyles.bodySm,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.tanggal.day} ${_bulan(item.tanggal.month)} ${item.tanggal.year}, '
                      '${item.tanggal.hour.toString().padLeft(2, '0')}:'
                      '${item.tanggal.minute.toString().padLeft(2, '0')}',
                      style: AppTextStyles.bodySm,
                    ),
                    StatusBadge(status: _status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _bulan(int m) {
    const list = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return list[m];
  }
}

class _PenukaranItem extends StatelessWidget {
  final PenukaranModel item;
  const _PenukaranItem({required this.item});

  TransactionStatus get _status {
    switch (item.status) {
      case 'selesai':
        return TransactionStatus.selesai;
      default:
        return TransactionStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.produkNama,
                        style: AppTextStyles.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      item.poinFormatted,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('Qty: ${item.jumlah}', style: AppTextStyles.bodySm),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.tanggal.day} ${_bulan(item.tanggal.month)} ${item.tanggal.year}',
                      style: AppTextStyles.bodySm,
                    ),
                    StatusBadge(status: _status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _bulan(int m) {
    const list = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return list[m];
  }
}

class _PaginationRow extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final void Function(int) onPageChange;

  const _PaginationRow({
    required this.currentPage,
    required this.lastPage,
    required this.onPageChange,
  });

  @override
  Widget build(BuildContext context) {
    final pages = List.generate(lastPage > 3 ? 3 : lastPage, (i) => i + 1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PageBtn(
          icon: Icons.chevron_left_rounded,
          onTap: currentPage > 1 ? () => onPageChange(currentPage - 1) : null,
        ),
        const SizedBox(width: 8),
        ...pages.map(
          (p) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onPageChange(p),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p == currentPage
                      ? AppColors.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: p != currentPage
                      ? Border.all(
                          color: AppColors.outlineVariant.withOpacity(0.5),
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$p',
                  style: AppTextStyles.labelMd.copyWith(
                    color: p == currentPage ? Colors.white : AppColors.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _PageBtn(
          icon: Icons.chevron_right_rounded,
          onTap: currentPage < lastPage
              ? () => onPageChange(currentPage + 1)
              : null,
        ),
      ],
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _PageBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppColors.textMain : AppColors.outline,
        ),
      ),
    );
  }
}
