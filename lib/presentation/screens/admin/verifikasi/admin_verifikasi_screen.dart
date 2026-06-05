import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
import '/../../data/providers/admin_provider.dart';
import '/../../data/services/admin_service.dart' hide NasabahPendingModel;

class AdminVerifikasiScreen extends ConsumerWidget {
  const AdminVerifikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verifikasiProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.textMain),
        title: const Text('Validasi Nasabah Baru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(verifikasiProvider.notifier).fetch(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(verifikasiProvider.notifier).fetch(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header tag
              Row(children: [
                const Icon(Icons.verified_user_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('MODUL VERIFIKASI',
                    style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primary, letterSpacing: 1)),
              ]),
              const SizedBox(height: 10),
              Text('Validasi Nasabah Baru',
                  style: AppTextStyles.headlineLg
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Tinjau dan aktifkan akun nasabah yang baru mendaftar.',
                style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 16),

              // Stats Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Menunggu Verifikasi',
                            style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.inversePrimary)),
                        const Icon(Icons.pending_actions_rounded,
                            color: AppColors.inversePrimary, size: 22),
                      ],
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '${state.totalPending} ',
                          style: AppTextStyles.dataDisplay.copyWith(
                              color: Colors.white, fontSize: 36),
                        ),
                        TextSpan(
                          text: 'Akun',
                          style: AppTextStyles.bodyLg.copyWith(
                              color: Colors.white.withOpacity(0.8)),
                        ),
                      ]),
                    ),
                    Divider(color: Colors.white.withOpacity(0.2), height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rata-rata waktu tunggu:',
                            style: AppTextStyles.bodyMd.copyWith(
                                color: Colors.white.withOpacity(0.8))),
                        Text('2 Jam',
                            style: AppTextStyles.labelMd.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Loading
              if (state.isLoading)
                ...List.generate(2, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(height: 200,
                      decoration: BoxDecoration(color: AppColors.surfaceDim,
                          borderRadius: BorderRadius.circular(16))),
                ))
              else if (state.data.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  alignment: Alignment.center,
                  child: Column(children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 48, color: AppColors.success),
                    const SizedBox(height: 12),
                    Text('Semua nasabah sudah diverifikasi!',
                        style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant)),
                  ]),
                )
              else
                ...state.data.map((nasabah) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NasabahCard(
                    nasabah:      nasabah,
                    isSubmitting: state.isSubmitting,
                    onAktifkan:   () async {
                      final ok = await ref
                          .read(verifikasiProvider.notifier)
                          .aktifkan(nasabah.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok
                            ? '${nasabah.namaLengkap} berhasil diaktifkan.'
                            : ref.read(verifikasiProvider).error ?? 'Gagal.'),
                        backgroundColor: ok ? AppColors.success : AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ));
                    },
                  ),
                )),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _NasabahCard extends StatelessWidget {
  final NasabahPendingModel nasabah;
  final bool isSubmitting;
  final VoidCallback onAktifkan;

  const _NasabahCard({
    required this.nasabah,
    required this.isSubmitting,
    required this.onAktifkan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: AppColors.mintContainer, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(nasabah.initials,
                    style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nasabah.namaLengkap,
                        style: AppTextStyles.headlineMd.copyWith(
                            fontWeight: FontWeight.w700, fontSize: 18)),
                    Row(children: [
                      const Icon(Icons.mail_outline_rounded,
                          size: 12, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(nasabah.email,
                          style: AppTextStyles.bodySm.copyWith(fontSize: 12)),
                    ]),
                  ],
                ),
              ),
            ]),
          ),

          // Detail info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              _Row('Tanggal Daftar', nasabah.tanggalDaftar),
              const SizedBox(height: 8),
              _Row('Tipe Nasabah',   nasabah.tipeNasabah),
              const SizedBox(height: 8),
              _Row('Lokasi Area',    nasabah.lokasiArea),
            ]),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onAktifkan,
                  icon: isSubmitting
                      ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Aktifkan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.outlineVariant.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_rounded,
                    color: AppColors.onSurfaceVariant, size: 20),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant)),
        Text(value,
            style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}