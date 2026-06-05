import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
// Sesuaikan path import provider dan model Anda
import '../../../../data/providers/admin_provider.dart';
// Sesuaikan jumlah titik-titiknya dengan posisi folder Anda
import '../notifikasi/admin_akun_screen.dart';

class AdminLogScreen extends ConsumerStatefulWidget {
  const AdminLogScreen({super.key});

  @override
  ConsumerState<AdminLogScreen> createState() => _AdminLogScreenState();
}

class _AdminLogScreenState extends ConsumerState<AdminLogScreen> {
  final _searchController = TextEditingController();
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    // Memanggil provider yang ada di admin_provider.dart Anda
    final logState = ref.watch(logAktivitasProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [const CustomNotifBell()],
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
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
      body: _buildBody(logState),
    );
  }

  // Memisahkan logika body untuk menangani Custom State Anda
  // Memisahkan logika body untuk menangani Custom State Anda
  Widget _buildBody(LogAktivitasState logState) {
    // 1. Tangani status Loading
    if (logState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // 2. Tangani status Error
    if (logState.error != null) {
      return Center(
        child: Text(
          logState.error!,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

    // 3. Tangani Data Sukses
    final logs = logState.data;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with search
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
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      style: AppTextStyles.bodySm,
                      decoration: InputDecoration(
                        hintText: 'Search logs...',
                        hintStyle: AppTextStyles.bodySm.copyWith(
                          color: AppColors.outline.withOpacity(0.7),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: AppColors.outline,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.outlineVariant.withOpacity(0.4),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.outlineVariant.withOpacity(0.4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Menampilkan Data Dinamis
            if (logs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text('Belum ada log aktivitas.')),
              )
            else
              ...logs.map((log) {
                // Menentukan ikon dan warna berdasarkan tipe log (opsional, bisa Anda sesuaikan)
                Color avatarColor = AppColors.secondaryContainer;
                IconData avatarIcon = Icons.history_rounded;
                Color avatarIconColor = AppColors.secondary;

                if (log.tipe == 'sistem') {
                  avatarColor = AppColors.errorContainer;
                  avatarIcon = Icons.settings_system_daydream;
                  avatarIconColor = AppColors.error;
                }

                return _LogItem(
                  avatarColor: avatarColor,
                  avatarIcon: avatarIcon,
                  avatarIconColor: avatarIconColor,
                  // Menggunakan properti asli dari LogAktivitasModel
                  title: log.admin,
                  action: log.aksi,
                  time: log
                      .waktu, // Anda juga bisa menggunakan log.tanggal jika perlu
                  detail: _TextDetail(
                    text: log.aksi,
                  ), // Karena tidak ada properti 'keterangan', saya pakai 'aksi'
                  isLast: logs.last == log,
                );
              }).toList(),

            // Pagination (Bisa dibuat dinamis nanti jika API mendukung pagination)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Showing ${_currentPage} of ${logs.length}\nentries',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  _LogPageBtn(
                    icon: Icons.chevron_left_rounded,
                    onTap: _currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  const SizedBox(width: 4),
                  // Pagination Statis Sementara
                  ...List.generate(3, (i) {
                    final p = i + 1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => setState(() => _currentPage = p),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _currentPage == p
                                ? AppColors.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$p',
                            style: AppTextStyles.labelMd.copyWith(
                              color: _currentPage == p
                                  ? Colors.white
                                  : AppColors.textMain,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  _LogPageBtn(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => setState(() => _currentPage++),
                  ),
                ],
              ),
            ),
          ],
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
