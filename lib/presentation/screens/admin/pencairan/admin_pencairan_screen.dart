import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';

// Gunakan path provider Anda yang valid
import '../../../../data/providers/admin_provider.dart';

class AdminPencairanScreen extends ConsumerWidget {
  const AdminPencairanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pencairanAdminProvider);

    // 👈 FILTER OTOMATIS: Hanya ambil data yang statusnya 'pending'
    final pendingList = state.data.where((p) => p.status == 'pending').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.textMain),
        title: const Text('Persetujuan Pencairan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(pencairanAdminProvider.notifier).fetch(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(pencairanAdminProvider.notifier).fetch(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mintContainer,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  'OPERASIONAL',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Persetujuan Pencairan',
                style: AppTextStyles.headlineLg.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tinjau dan konfirmasi permintaan penarikan saldo kas nasabah.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Total tertunda card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF004D35), Color(0xFF006948)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL NOMINAL TERTUNDA',
                      style: AppTextStyles.labelSm.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.totalTertundaFormatted,
                      style: AppTextStyles.dataDisplay.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.pending_actions_rounded,
                          color: AppColors.inversePrimary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${pendingList.length} permintaan menunggu',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.inversePrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // List Rendering menggunakan pendingList
              if (state.isLoading)
                ...List.generate(
                  2,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDim,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                )
              else if (pendingList.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 48,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada permintaan pencairan.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...pendingList.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PencairanCard(
                      item: p,
                      // Hapus pengiriman global state (isSubmitting/isThisItemSpinning)
                      onSelesai: () async {
                        final ok = await ref
                            .read(pencairanAdminProvider.notifier)
                            .selesaikan(p.id);
                        if (!context.mounted) return;
                        _showSnackbar(
                          context,
                          ok,
                          ok
                              ? 'Pencairan berhasil diselesaikan.'
                              : ref.read(pencairanAdminProvider).error ??
                                  'Gagal.',
                        );
                      },
                      onTolak: () async {
                        final ok = await ref
                            .read(pencairanAdminProvider.notifier)
                            .tolak(p.id);
                        if (!context.mounted) return;
                        _showSnackbar(
                          context,
                          ok,
                          ok
                              ? 'Pencairan ditolak, poin dikembalikan.'
                              : ref.read(pencairanAdminProvider).error ??
                                  'Gagal.',
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackbar(BuildContext context, bool ok, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// 👇 DIUBAH MENJADI STATEFUL WIDGET 👇
class _PencairanCard extends StatefulWidget {
  final PencairanAdminModel item;
  final Future<void> Function() onSelesai;
  final Future<void> Function() onTolak;

  const _PencairanCard({
    required this.item,
    required this.onSelesai,
    required this.onTolak,
  });

  @override
  State<_PencairanCard> createState() => _PencairanCardState();
}

class _PencairanCardState extends State<_PencairanCard> {
  // Variabel loading dipisah agar UI lebih informatif
  bool _isLoadingSelesai = false;
  bool _isLoadingTolak = false;

  // Mengunci semua tombol di kartu ini jika salah satu sedang loading
  bool get _isAnyLoading => _isLoadingSelesai || _isLoadingTolak;

  Future<void> _handleSelesai() async {
    setState(() => _isLoadingSelesai = true);
    await widget.onSelesai();
    if (mounted) setState(() => _isLoadingSelesai = false);
  }

  Future<void> _handleTolak() async {
    setState(() => _isLoadingTolak = true);
    await widget.onTolak();
    if (mounted) setState(() => _isLoadingTolak = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.item.initials,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.namaNasabah,
                      style: AppTextStyles.labelMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.item.tanggal,
                      style: AppTextStyles.bodySm.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  'Pending',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.warningText,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nominal Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  'Nominal Pencairan',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.nominalFormatted,
                  style: AppTextStyles.headlineMd.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── KOTAK RINCIAN METODE PENCAIRAN ──
          if (widget.item.catatan != null && widget.item.catatan!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.item.catatan!,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textMain,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAnyLoading ? null : _handleTolak,
                  icon: _isLoadingTolak
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.outlineVariant,
                          ),
                        )
                      : const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMain,
                    side: BorderSide(
                      color: AppColors.outlineVariant.withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isAnyLoading ? null : _handleSelesai,
                  icon: _isLoadingSelesai
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                        ),
                  label: const Text('Selesai'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}