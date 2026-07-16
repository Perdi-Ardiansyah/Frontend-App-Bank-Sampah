import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/nasabah_provider.dart';

class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notifikasiProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.textMain),
        title: const Text('Notifikasi'),
        actions: [
          // Tombol 1: Tandai Dibaca (Hanya muncul jika ada notifikasi belum dibaca)
          if (notifState.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notifikasiProvider.notifier).markAllRead(),
              child: Text(
                'Tandai Dibaca',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

          // 👇 TOMBOL 2: BERSINKAN SEMUA NOTIFIKASI 👇
          if (notifState.items.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.error,
              ),
              tooltip: 'Bersihkan Semua',
              onPressed: () async {
                // Menampilkan dialog konfirmasi pembatalan/penghapusan
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surfaceWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Hapus Semua Notifikasi?'),
                    content: const Text(
                      'Semua riwayat pemberitahuan Anda akan dihapus permanen dari aplikasi.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                // Jika dikonfirmasi "Ya", panggil fungsi bersihkanNotifikasi()
                if (confirm == true) {
                  final ok = await ref
                      .read(notifikasiProvider.notifier)
                      .bersihkanNotifikasi();

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Kotak masuk berhasil dibersihkan!'
                            : 'Gagal menghapus notifikasi.',
                      ),
                      backgroundColor: ok ? AppColors.success : AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(notifikasiProvider.notifier).fetch(),
        child: notifState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifState.items.isEmpty
            ? ListView(
                // Menggunakan ListView agar fitur Pull-to-Refresh tetap bekerja saat data kosong
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.notifications_off_outlined,
                            size: 64,
                            color: AppColors.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada notifikasi',
                            style: AppTextStyles.headlineMd.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Semua pemberitahuan akan muncul di sini.',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifState.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final n = notifState.items[index];
                  return _NotifItem(
                    tipe: n.tipe,
                    judul: n.judul,
                    pesan: n.pesan,
                    time: n.timeAgo,
                    isUnread: !n.isRead,
                  );
                },
              ),
      ),
    );
  }
}

// ── Helper Widget (Dipindahkan dari AkunScreen) ──
class _NotifItem extends StatelessWidget {
  final String tipe;
  final String judul;
  final String pesan;
  final String time;
  final bool isUnread;

  const _NotifItem({
    required this.tipe,
    required this.judul,
    required this.pesan,
    required this.time,
    required this.isUnread,
  });

  IconData get _icon {
    switch (tipe) {
      case 'setoran':
        return Icons.check_circle_outline_rounded;
      case 'penukaran':
        return Icons.card_giftcard_rounded;
      case 'promo':
        return Icons.campaign_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color get _iconColor {
    switch (tipe) {
      case 'setoran':
        return AppColors.success;
      case 'promo':
        return AppColors.warning;
      default:
        return AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isUnread
          ? AppColors.mintContainer.withOpacity(0.5)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 28, color: _iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        judul,
                        style: AppTextStyles.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  pesan,
                  style: AppTextStyles.bodySm.copyWith(height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.outline,
                    fontSize: 11,
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
