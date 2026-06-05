import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
import '../../../widgets/common/app_button.dart';
// Sesuaikan jumlah titik-titiknya dengan posisi folder Anda
import '../notifikasi/admin_akun_screen.dart';
// Sesuaikan dengan path import provider Anda
import '../../../../data/providers/admin_provider.dart';

class AdminKategoriScreen extends ConsumerStatefulWidget {
  const AdminKategoriScreen({super.key});

  @override
  ConsumerState<AdminKategoriScreen> createState() =>
      _AdminKategoriScreenState();
}

class _AdminKategoriScreenState extends ConsumerState<AdminKategoriScreen> {
  @override
  void initState() {
    super.initState();
    // Ambil data dari API Laravel saat halaman dibuka
    Future.microtask(() => ref.read(kategoriAdminProvider.notifier).fetch());
  }

  void _showFormDialog(BuildContext context, {Map<String, dynamic>? kategori}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FormKategoriSheet(kategoriData: kategori),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kategoriAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.textMain),
        title: const SizedBox.shrink(),
        actions: [const CustomNotifBell()],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(kategoriAdminProvider.notifier).fetch(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori Sampah',
                style: AppTextStyles.headlineLg.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Kelola jenis sampah, nilai poin, foto, dan status operasional.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              AppButton(
                label: '+ Tambah Kategori',
                onPressed: () => _showFormDialog(context),
              ),
              const SizedBox(height: 20),

              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (state.error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      state.error!,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                )
              else if (state.data.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text('Belum ada data kategori di database.'),
                  ),
                )
              else
                ...state.data.map((kategori) {
                  // JEBAKAN TRY-CATCH UNTUK MENDETEKSI FIELD MANA YANG ERROR
                  try {
                    final id = kategori['id'];
                    final name =
                        kategori['nama'] ??
                        kategori['nama_kategori'] ??
                        'Tanpa Nama';
                    final desc = kategori['deskripsi'] ?? '-';
                    final poin =
                        int.tryParse(kategori['poin_per_kg'].toString()) ?? 0;
                    final isActive =
                        kategori['is_active'] == 1 ||
                        kategori['is_active'] == true ||
                        kategori['is_active'] == '1';
                    final fotoUrl = kategori['foto'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _KategoriCard(
                        imageUrl: fotoUrl,
                        name: name,
                        desc: desc,
                        poinPerKg: poin,
                        isActive: isActive,
                        onEdit: () =>
                            _showFormDialog(context, kategori: kategori),
                        onToggle: () async {
                          final success = await ref
                              .read(kategoriAdminProvider.notifier)
                              .toggleStatus(id);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Status $name diperbarui!'),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  } catch (e) {
                    // Jika ada 1 item yang error parsing-nya, cetak log aslinya ke terminal
                    print('🚨 CRASH PARSING ITEM KATEGORI: $e');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      color: Colors.red.withOpacity(0.1),
                      child: Text(
                        'Gagal memuat item ini: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                }).toList(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _KategoriCard extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String desc;
  final int poinPerKg;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _KategoriCard({
    this.imageUrl,
    required this.name,
    required this.desc,
    required this.poinPerKg,
    required this.isActive,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        // PERBAIKAN: Gunakan Border.all agar warnanya seragam (Uniform)
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      // PERBAIKAN: Memotong isi di dalamnya agar mengikuti lengkungan border
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Trik Garis Tebal di Kiri
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              color: isActive ? AppColors.primary : AppColors.outline,
            ),
          ),

          // Konten Utama Kartu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Foto Barang / Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.mintContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl != null && imageUrl!.isNotEmpty
                            ? Image.network(
                                imageUrl!.startsWith('http')
                                    ? imageUrl!
                                    : 'http://10.0.2.2:8000/storage/$imageUrl',
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.broken_image,
                                  color: AppColors.outline,
                                  size: 22,
                                ),
                              )
                            : const Icon(
                                Icons.recycling_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.successContainer
                            : AppColors.surfaceDim,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.outline,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'Aktif' : 'Nonaktif',
                            style: AppTextStyles.labelSm.copyWith(
                              color: isActive
                                  ? AppColors.successText
                                  : AppColors.outline,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: AppTextStyles.headlineMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const Divider(height: 20, color: Color(0xFFE5E7EB)),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nilai Tukar',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$poinPerKg ',
                                  style: AppTextStyles.headlineMd.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Poin/Kg',
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: AppColors.primary.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _ActionBtn(icon: Icons.edit_rounded, onTap: onEdit),
                        const SizedBox(width: 8),
                        _ActionBtn(
                          icon: isActive
                              ? Icons.block_rounded
                              : Icons.check_circle_outline_rounded,
                          onTap: onToggle,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

class _FormKategoriSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? kategoriData;
  const _FormKategoriSheet({this.kategoriData});

  @override
  ConsumerState<_FormKategoriSheet> createState() => _FormKategoriSheetState();
}

class _FormKategoriSheetState extends ConsumerState<_FormKategoriSheet> {
  late TextEditingController _namaController;
  late TextEditingController _descController;
  late TextEditingController _poinController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final isEdit = widget.kategoriData != null;
    _namaController = TextEditingController(
      text: isEdit
          ? (widget.kategoriData!['nama'] ??
                widget.kategoriData!['nama_kategori'])
          : '',
    );
    _descController = TextEditingController(
      text: isEdit ? (widget.kategoriData!['deskripsi'] ?? '') : '',
    );
    _poinController = TextEditingController(
      text: isEdit ? widget.kategoriData!['poin_per_kg'].toString() : '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _descController.dispose();
    _poinController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _simpan() async {
    final nama = _namaController.text.trim();
    final desc = _descController.text.trim();
    final poin = int.tryParse(_poinController.text.trim()) ?? 0;

    if (nama.isEmpty || poin <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan poin harus diisi.')),
      );
      return;
    }

    final id = widget.kategoriData?['id'];
    final success = await ref
        .read(kategoriAdminProvider.notifier)
        .simpanKategori(
          id: id,
          nama: nama,
          deskripsi: desc,
          poin: poin,
          imageFile: _selectedImage,
        );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            id == null ? 'Kategori ditambahkan!' : 'Kategori diperbarui!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(kategoriAdminProvider).isSubmitting;
    final isEdit = widget.kategoriData != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEdit ? 'Edit Kategori' : 'Tambah Kategori',
                style: AppTextStyles.headlineMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_rounded,
                            color: AppColors.outline,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Foto',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _namaController,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              labelText: 'Nama Kategori',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descController,
            style: AppTextStyles.bodyMd,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Deskripsi',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _poinController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              labelText: 'Nilai Poin per Kg',
              suffixText: 'Poin/kg',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: isEdit ? 'Simpan Perubahan' : 'Simpan Kategori',
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : _simpan,
          ),
        ],
      ),
    );
  }
}
