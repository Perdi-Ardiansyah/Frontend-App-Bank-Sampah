import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/providers/admin_provider.dart';
import '../../auth/login_screen.dart';


// ══════════════════════════════════════════════════════════════════════════════
// 1. WIDGET LONCENG NOTIFIKASI (BISA DIPAKAI DI SEMUA HALAMAN)
// ══════════════════════════════════════════════════════════════════════════════
class CustomNotifBell extends ConsumerWidget {
  const CustomNotifBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notifikasiProvider);
    
    // Cek apakah ada notifikasi yang isRead == false
    final hasUnread = state.data.any((n) => !n.isRead);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () {
            // Navigasi tumpuk (push) ke halaman Notifikasi
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminNotifikasiScreen()),
            );
          },
        ),
        if (hasUnread && !state.isLoading) // Titik merah muncul jika ada yang belum dibaca
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}


// ══════════════════════════════════════════════════════════════════════════════
// 2. HALAMAN AKUN / PROFIL (TAB UTAMA)
// ══════════════════════════════════════════════════════════════════════════════
class AdminAkunScreen extends StatefulWidget {
  const AdminAkunScreen({super.key});

  @override
  State<AdminAkunScreen> createState() => _AdminAkunScreenState();
}

class _AdminAkunScreenState extends State<AdminAkunScreen> {
  final _oldPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _isSaving = false;

  Future<void> _prosesLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Konfirmasi', style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin keluar dari akun Admin?', style: AppTextStyles.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Keluar', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token'); 

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda telah berhasil keluar.')));
        // Buka blokir kode ini jika LoginScreen sudah ada
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [
          CustomNotifBell(), // 👈 Gunakan Widget Lonceng yang baru dibuat
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('SA', style: AppTextStyles.headlineMd.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  Text('Super Admin', style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('ID Admin: ADM-00001', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.mail_outline_rounded, size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text('admin@banksampah.id', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.mintContainer, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Super Admin • Akses Penuh', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Akun & Keamanan', style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Kelola kata sandi dan pantau aktivitas notifikasi Anda di sini.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5)),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.mintContainer, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.sync_lock_rounded, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text('Ubah Password', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
                  ]),
                  const SizedBox(height: 20),
                  AppTextField(label: 'Password Lama', hintText: 'Masukkan password saat ini', controller: _oldPwController, isPassword: true),
                  const SizedBox(height: 14),
                  AppTextField(label: 'Password Baru', hintText: 'Minimal 8 karakter', controller: _newPwController, isPassword: true),
                  const SizedBox(height: 14),
                  AppTextField(label: 'Konfirmasi Password Baru', hintText: 'Ulangi password baru', controller: _confirmPwController, isPassword: true),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Simpan Perubahan',
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : () async {
                      final oldPw = _oldPwController.text.trim();
                      final newPw = _newPwController.text.trim();
                      final confirmPw = _confirmPwController.text.trim();

                      if (oldPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom password wajib diisi!'), backgroundColor: AppColors.error));
                        return;
                      }
                      if (newPw != confirmPw) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak cocok!'), backgroundColor: AppColors.error));
                        return;
                      }

                      setState(() => _isSaving = true);
                      try {
                        final res = await ApiClient.instance.post('/ubah-password', data: {
                          'password_lama': oldPw,
                          'password_baru': newPw,
                          'konfirmasi_password': confirmPw, 
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? 'Password berhasil diubah!'), backgroundColor: AppColors.success));
                          _oldPwController.clear(); _newPwController.clear(); _confirmPwController.clear();
                        }
                      } catch (e) {
                        if (mounted) {
                          String errorMsg = 'Gagal mengubah password.';
                          if (e is DioException && e.response?.data != null) {
                            errorMsg = e.response?.data['message'] ?? errorMsg;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error));
                        }
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _prosesLogout(context),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Keluar Akun'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorContainer, foregroundColor: AppColors.errorText,
                  elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════════════════════
// 3. HALAMAN NOTIFIKASI (KINI BERDIRI SENDIRI, DIPANGGIL VIA NAVIGATOR.PUSH)
// ══════════════════════════════════════════════════════════════════════════════
class AdminNotifikasiScreen extends ConsumerStatefulWidget {
  const AdminNotifikasiScreen({super.key});

  @override
  ConsumerState<AdminNotifikasiScreen> createState() => _AdminNotifikasiScreenState();
}

class _AdminNotifikasiScreenState extends ConsumerState<AdminNotifikasiScreen> {
  String _activeFilter = 'Semua';
  
  // 👇 1. UBAH FILTER: Hapus 'Sistem', Masukkan 'Setoran' dan 'Stok'
  final List<String> _filters = ['Semua', 'Verifikasi', 'Pencairan', 'Setoran', 'Stok'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notifikasiProvider.notifier).fetch());
  }

  // 👇 2. MESIN DESAIN BARU: Beri warna dan ikon sesuai tipe dari Laravel
  Map<String, dynamic> _getStyleByTipe(String tipe) {
    final t = tipe.toLowerCase();
    
    // Tipe 1: Verifikasi (Biru/Mint)
    if (t.contains('verifikasi')) {
      return {
        'tagColor': AppColors.mintContainer, 
        'tagTextColor': AppColors.primary, 
        'icon': Icons.person_add_rounded, 
        'iconBg': AppColors.mintContainer, 
        'iconColor': AppColors.primary, 
        'label': 'VERIFIKASI'
      };
    }
    
    // Tipe 2: Pencairan (Oranye/Kuning)
    if (t.contains('pencairan') || t.contains('penukaran')) {
      return {
        'tagColor': AppColors.warningContainer, 
        'tagTextColor': AppColors.warningText ?? AppColors.warning, 
        'icon': Icons.account_balance_wallet_rounded, 
        'iconBg': AppColors.warningContainer, 
        'iconColor': AppColors.warning, 
        'label': 'PENCAIRAN'
      };
    }
    
    // Tipe 3: Stok Habis (Merah)
    if (t.contains('stok') || t.contains('habis')) {
      return {
        'tagColor': AppColors.errorContainer, 
        'tagTextColor': AppColors.error, 
        'icon': Icons.inventory_2_outlined, 
        'iconBg': AppColors.errorContainer, 
        'iconColor': AppColors.error, 
        'label': 'STOK HABIS'
      };
    }
    
    // Tipe 4: Setoran Baru (Hijau)
    if (t.contains('setoran')) {
      return {
        'tagColor': AppColors.success.withOpacity(0.15), // Pakai opacity jika tidak ada successContainer
        'tagTextColor': AppColors.success, 
        'icon': Icons.recycling_rounded, 
        'iconBg': AppColors.success.withOpacity(0.15), 
        'iconColor': AppColors.success, 
        'label': 'SETORAN BARU'
      };
    }

    // Default Fallback (Jika ada tipe yang tidak dikenali)
    return {
      'tagColor': AppColors.surfaceContainer, 
      'tagTextColor': AppColors.onSurfaceVariant, 
      'icon': Icons.notifications_active_rounded, 
      'iconBg': AppColors.surfaceContainer, 
      'iconColor': AppColors.onSurfaceVariant, 
      'label': 'INFO'
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notifikasiProvider);
    final filteredData = state.data.where((n) {
      if (_activeFilter == 'Semua') return true;
      return n.tipe.toLowerCase().contains(_activeFilter.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.textMain), // 👈 Tombol Back Otomatis
        title: const Text('Notifikasi'),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(notifikasiProvider.notifier).tandaiSemuaDibaca(),
            icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary),
            label: Text('Tandai Dibaca', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(notifikasiProvider.notifier).fetch(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final isActive = _activeFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeFilter = f),
                        child: _NotifChip(label: f, isActive: isActive),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (state.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
              else if (filteredData.isEmpty)
                Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Text('Tidak ada notifikasi.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.outline))))
              else
                ...filteredData.map((notif) {
                  final style = _getStyleByTipe(notif.tipe);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NotifCard(
                      tagLabel: style['label'], tagColor: style['tagColor'], tagTextColor: style['tagTextColor'],
                      icon: style['icon'], iconBg: style['iconBg'], iconColor: style['iconColor'],
                      title: notif.judul, desc: notif.pesan, time: notif.tanggal, isUnread: !notif.isRead,
                    ),
                  );
                }),
              const SizedBox(height: 28),
              Text('Tips Efisiensi', style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF004D35), Color(0xFF006948)]), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Persetujuan Massal', style: AppTextStyles.headlineMd.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Hemat waktu dengan menyetujui hingga 10 permintaan verifikasi sekaligus di menu Verifikasi.', style: AppTextStyles.bodyMd.copyWith(color: Colors.white.withOpacity(0.85), height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: _TipsCard(icon: Icons.access_time_rounded, iconColor: AppColors.warning, iconBg: AppColors.warningContainer, title: 'Jam Sibuk', desc: 'Senin pagi biasanya volume setoran tinggi.')),
                  SizedBox(width: 12),
                  Expanded(child: _TipsCard(icon: Icons.security_rounded, iconColor: AppColors.primary, iconBg: AppColors.mintContainer, title: 'Otentikasi', desc: 'Pastikan 2FA aktif untuk keamanan admin.')),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// KOMPONEN PENDUKUNG UI
// ══════════════════════════════════════════════════════════════════════════════
class _NotifChip extends StatelessWidget {
  final String label; final bool isActive;
  const _NotifChip({required this.label, this.isActive = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: isActive ? AppColors.primary : AppColors.surfaceWhite, borderRadius: BorderRadius.circular(50), border: Border.all(color: isActive ? AppColors.primary : AppColors.outlineVariant.withOpacity(0.4))),
      child: Text(label, style: AppTextStyles.labelSm.copyWith(color: isActive ? Colors.white : AppColors.onSurfaceVariant)),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final String tagLabel, title, desc, time;
  final Color tagColor, tagTextColor, iconBg, iconColor;
  final IconData icon; final bool isUnread;
  const _NotifCard({required this.tagLabel, required this.tagColor, required this.tagTextColor, required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.desc, required this.time, this.isUnread = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: isUnread ? AppColors.primary.withOpacity(0.2) : AppColors.outlineVariant.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(50)), child: Text(tagLabel, style: AppTextStyles.labelSm.copyWith(color: tagTextColor, fontSize: 9, letterSpacing: 0.5))),
              const Spacer(),
              Text(time, style: AppTextStyles.bodySm.copyWith(color: AppColors.outline, fontSize: 11)),
              if (isUnread) ...[const SizedBox(width: 6), Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle))],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, size: 20, color: iconColor)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700, fontSize: 13)), const SizedBox(height: 4), Text(desc, style: AppTextStyles.bodySm.copyWith(height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis)])),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final IconData icon; final Color iconColor, iconBg; final String title, desc;
  const _TipsCard({required this.icon, required this.iconColor, required this.iconBg, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: iconColor)),
          const SizedBox(height: 10),
          Text(title, style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(desc, style: AppTextStyles.bodySm.copyWith(height: 1.4), maxLines: 2),
        ],
      ),
    );
  }
}