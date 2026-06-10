import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
import '/../../data/providers/auth_provider.dart';
import '/../../data/providers/nasabah_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/lonceng_notifikasi.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'edit_profil_screen.dart'; // 👈 Tambahkan baris ini

class AkunScreen extends ConsumerStatefulWidget {
  const AkunScreen({super.key});

  @override
  ConsumerState<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends ConsumerState<AkunScreen> {
  final _oldPwCtrl     = TextEditingController();
  final _newPwCtrl     = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _isSaving       = false;

  @override
  void dispose() {
    _oldPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  bool _isUploadingFoto = false;

  Future<void> _ubahFotoProfil() async {
    final picker = ImagePicker();
    // Buka galeri HP
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      setState(() => _isUploadingFoto = true);
      
      // Kirim ke backend melalui provider
      final ok = await ref.read(authProvider.notifier).updateFotoProfil(File(pickedFile.path));
      
      setState(() => _isUploadingFoto = false);
      
      if (ok) {
        _showSnackbar('Foto profil berhasil diperbarui!');
      } else {
        _showSnackbar('Gagal memperbarui foto profil', isError: true);
      }
    }
  }

  Future<void> _handleChangePassword() async {
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      _showSnackbar('Konfirmasi password tidak cocok.', isError: true);
      return;
    }
    if (_newPwCtrl.text.length < 8) {
      _showSnackbar('Password baru minimal 8 karakter.', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    final result = await ref.read(authProvider.notifier).changePassword(
      passwordLama:       _oldPwCtrl.text,
      passwordBaru:       _newPwCtrl.text,
      konfirmasiPassword: _confirmPwCtrl.text,
    );
    setState(() => _isSaving = false);
    if (!mounted) return;
    if (result.success) {
      _oldPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      _showSnackbar('Password berhasil diubah!');
    } else {
      _showSnackbar(result.message, isError: true);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar?',
            style: AppTextStyles.headlineMd
                .copyWith(fontWeight: FontWeight.w700)),
        content: Text(
            'Anda akan keluar dari akun ini.',
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal',
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user      = ref.watch(currentUserProvider);
    final dashboard = ref.watch(dashboardProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
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
      
      // 👇 1. BUNGKUS SELURUH BODY DENGAN RefreshIndicator 👇
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          // Paksa Riverpod menghapus cache lama dan mengambil data terbaru dari Laravel
          ref.invalidate(currentUserProvider);
          ref.invalidate(dashboardProvider);
          
          // Beri jeda animasi sebentar agar tarikannya terasa natural
          await Future.delayed(const Duration(milliseconds: 800));
        },
        
        // 👇 2. TAMBAHKAN PHYSICS AGAR SELALU BISA DITARIK 👇
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), 
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Card ────────────────────────────────────────────
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
                    // ── FOTO PROFIL DENGAN IKON KAMERA ──
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 84, 
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDim,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _isUploadingFoto 
                            ? const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(strokeWidth: 3),
                              )
                            : (user?.fotoUrl != null && user!.fotoUrl!.isNotEmpty)
                                ? Image.network(
                                    user.fotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_rounded, size: 40, color: AppColors.onSurfaceVariant),
                                  )
                                : const Icon(Icons.person_rounded, size: 40, color: AppColors.onSurfaceVariant),
                        ),
                        GestureDetector(
                          onTap: _isUploadingFoto ? null : _ubahFotoProfil,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    Text(user?.namaLengkap ?? '-', style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('ID Nasabah: ${user?.idNasabah ?? '-'}', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    _ProfileInfoRow(icon: Icons.mail_outline_rounded, value: user?.email ?? '-'),
                    const SizedBox(height: 8),
                    _ProfileInfoRow(icon: Icons.phone_outlined, value: user?.noHp ?? '-'),
                    const SizedBox(height: 16),
                    
                    // ── TOMBOL EDIT PROFIL ──
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditProfilScreen()),
                          );
                        },
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit Profil'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Poin Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF004D35), Color(0xFF006948)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(children: [
                        Text('TOTAL POIN', style: AppTextStyles.labelSm.copyWith(color: Colors.white.withOpacity(0.8), letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text(dashboard.totalPoinFormatted, style: AppTextStyles.dataDisplay.copyWith(fontSize: 28, color: Colors.white)),
                      ]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text('Akun & Keamanan', style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Kelola kata sandi profil Anda di sini.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5)),
              const SizedBox(height: 16),

              // ── Ubah Password ───────────────────────────────────────────
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
                    AppTextField(label: 'Password Lama', hintText: 'Masukkan password saat ini', controller: _oldPwCtrl, isPassword: true),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Password Baru', hintText: 'Minimal 8 karakter', controller: _newPwCtrl, isPassword: true),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Konfirmasi Password Baru', hintText: 'Ulangi password baru', controller: _confirmPwCtrl, isPassword: true),
                    const SizedBox(height: 20),
                    AppButton(label: 'Simpan Perubahan', isLoading: _isSaving, onPressed: _isSaving ? null : _handleChangePassword),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Logout Button ───────────────────────────────────────────
              AppButton(
                label: 'Keluar',
                variant: ButtonVariant.secondary,
                prefixIcon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                onPressed: _handleLogout,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────
class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _ProfileInfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
      const SizedBox(width: 8),
      Text(value, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
    ]);
  }
}