import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
// Sesuaikan path import provider dan model Anda
import '../../../../data/providers/admin_provider.dart';
// Sesuaikan jumlah titik-titiknya dengan posisi folder Anda
import '../notifikasi/admin_akun_screen.dart';
import 'dart:async';

class AdminLogScreen extends ConsumerStatefulWidget {
  const AdminLogScreen({super.key});

  @override
  ConsumerState<AdminLogScreen> createState() => _AdminLogScreenState();
}

class _AdminLogScreenState extends ConsumerState<AdminLogScreen> {
  final _searchController = TextEditingController();
  int _currentPage = 1;
  Timer? _timer; // 👈 1. Definisikan Timer

  @override
  void initState() {
    super.initState();
    // 2. Inisialisasi Timer (refresh tiap 10 detik)
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      ref.read(logAktivitasProvider.notifier).fetch();
    });
  }

  @override
  void dispose() {
    // 3. Hapus Timer saat layar ditutup agar tidak terjadi memory leak
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Memanggil provider yang ada di admin_provider.dart Anda
    final logState = ref.watch(logAktivitasProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Log Aktivitas'),
        actions: const [
          CustomNotifBell(),
          SizedBox(width: 8), // Sedikit jarak
        ],
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                'A',
                style: AppTextStyles.bodySm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(logState),
    );
  }

  // Memisahkan logika body untuk menangani Custom State Anda
  // Memisahkan logika body untuk menangani Custom State Anda
  Widget _buildBody(LogAktivitasState logState) {
    // 1. Tangani status Loading
    if (logState.isLoading && logState.data.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // 2. Tangani status Error
    if (logState.error != null && logState.data.isEmpty) {
      return Center(
        child: Text(
          logState.error!,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

    // 3. Tangani Data Sukses
    final logs = logState.data;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        // Panggil provider untuk refresh data saat ditarik
        await ref.read(logAktivitasProvider.notifier).fetch();
      },
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(), // Wajib agar bisa di-scroll & di-refresh
        padding: const EdgeInsets.all(16),
        child: Container(
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
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent\nActivities',
                        style: AppTextStyles.headlineMd.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    
                  ],
                ),
              ),

              // Menampilkan Data Log
              if (logs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('Belum ada log aktivitas.')),
                )
              else
                ...logs.map((log) {
                  return _LogItem(
                    avatarColor: log.tipe == 'sistem'
                        ? AppColors.errorContainer
                        : AppColors.secondaryContainer,
                    avatarIcon: log.tipe == 'sistem'
                        ? Icons.settings_system_daydream
                        : Icons.history_rounded,
                    avatarIconColor: log.tipe == 'sistem'
                        ? AppColors.error
                        : AppColors.secondary,
                    title: log.admin,
                    action: log.aksi,
                    time: log.waktu,
                    detail: _TextDetail(text: log.aksi),
                    isLast: logs.last == log,
                  );
                }).toList(),

              // Footer / Pagination Statis
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Showing ${logs.length} entries',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    _LogPageBtn(icon: Icons.chevron_left_rounded, onTap: null),
                    const SizedBox(width: 4),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '1',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _LogPageBtn(icon: Icons.chevron_right_rounded, onTap: null),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// KOMPONEN DESAIN STATIS (TIDAK ADA YANG DIUBAH)
// ============================================================================

class _LogItem extends StatelessWidget {
  final Color avatarColor;
  final String? avatarText;
  final IconData? avatarIcon;
  final Color? avatarIconColor;
  final String title;
  final String action;
  final String time;
  final Widget detail;
  final bool isLast;

  const _LogItem({
    required this.avatarColor,
    this.avatarText,
    this.avatarIcon,
    this.avatarIconColor,
    required this.title,
    required this.action,
    required this.time,
    required this.detail,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.3),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: avatarText != null
                ? Text(
                    avatarText!,
                    style: AppTextStyles.bodySm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                : Icon(avatarIcon, size: 18, color: avatarIconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyMd.copyWith(height: 1.5),
                          children: [
                            TextSpan(
                              text: '$title ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            TextSpan(
                              text: action,
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.outline,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                detail,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextDetail extends StatelessWidget {
  final String text;
  final List<String> boldParts;
  const _TextDetail({required this.text, this.boldParts = const []});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.bodySm.copyWith(height: 1.5));
  }
}

class _LogPageBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _LogPageBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? AppColors.textMain : AppColors.outline,
        ),
      ),
    );
  }
}
