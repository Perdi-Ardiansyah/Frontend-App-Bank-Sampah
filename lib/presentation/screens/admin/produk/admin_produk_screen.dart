import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
import '../../../widgets/common/app_button.dart';
// Sesuaikan jumlah titik-titiknya dengan posisi folder Anda
import '../notifikasi/admin_akun_screen.dart';
// Import provider admin Anda
import '../../../../data/providers/admin_provider.dart';
import '../../../../core/network/api_client.dart'; // Sesuaikan path jika perlu

class AdminProdukScreen extends ConsumerStatefulWidget {
  const AdminProdukScreen({super.key});

  @override
  ConsumerState<AdminProdukScreen> createState() => _AdminProdukScreenState();
}

class _AdminProdukScreenState extends ConsumerState<AdminProdukScreen> {
  final _searchController = TextEditingController();
  String _activeFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Aktif', 'Habis'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(produkAdminProvider.notifier).fetch());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFormProdukSheet(
    BuildContext context, {
    Map<String, dynamic>? produk,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormProdukSheet(produkData: produk),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(produkAdminProvider);
    final query = _searchController.text.toLowerCase();

    // Memfilter data asli dari API secara dinamis berdasarkan input pencarian dan tab filter
    final filteredData = state.data.where((p) {
      final name = (p['nama'] ?? p['nama_produk'] ?? '')
          .toString()
          .toLowerCase();
      final stok = int.tryParse(p['stok'].toString()) ?? 0;
      final isActive = p['is_active'] == 1 || p['is_active'] == true;

      final matchFilter =
          _activeFilter == 'Semua' ||
          (_activeFilter == 'Aktif' && isActive && stok > 0) ||
          (_activeFilter == 'Habis' && stok == 0);
      final matchSearch = query.isEmpty || name.contains(query);

      return matchFilter && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.textMain),
        title: const Text('Manajemen Produk'),
        actions: [const CustomNotifBell()],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(produkAdminProvider.notifier).fetch(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manajemen Produk',
                style: AppTextStyles.headlineLg.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Kelola katalog barang penukaran poin nasabah.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              AppButton(
                label: '+ Tambah Produk',
                onPressed: () => _showFormProdukSheet(context),
              ),
              const SizedBox(height: 16),

              // Search & filter card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _searchController,
                      style: AppTextStyles.bodyMd,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari produk...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: AppColors.outline,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 48,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: _filters.map((f) {
                        final isActive = _activeFilter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _activeFilter = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.outlineVariant.withOpacity(
                                          0.4,
                                        ),
                                ),
                              ),
                              child: Text(
                                f,
                                style: AppTextStyles.labelSm.copyWith(
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
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
              else if (filteredData.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text('Produk tidak ditemukan.'),
                  ),
                )
              else
                ...filteredData.map((produk) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ProdukCard(
                      produk: produk,
                      onEdit: () =>
                          _showFormProdukSheet(context, produk: produk),
                      onToggle: () async {
                        final id = produk['id'];
                        final success = await ref
                            .read(produkAdminProvider.notifier)
                            .toggleStatus(id);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Status produk diperbarui!'),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Produk Card Dinamis ──────────────────────────────────────────────────────
// ─── Produk Card Dinamis ──────────────────────────────────────────────────────
class _ProdukCard extends StatelessWidget {
  final Map<String, dynamic> produk;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _ProdukCard({
    required this.produk,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final name = (produk['nama'] ?? produk['nama_produk'] ?? 'Tanpa Nama').toString();

    final poin = int.tryParse((produk['biaya_poin'] ?? produk['poin']).toString()) ?? 0;
    final stok = int.tryParse(produk['stok'].toString()) ?? 0;
    final isActive = produk['is_active'] == 1 || produk['is_active'] == true;
    final isHabis = stok == 0;

    // 👇 URL GAMBAR SEKARANG DITANGANI SEPENUHNYA OLEH API CLIENT 👇
    final rawFotoUrl = (produk['foto'] ?? produk['foto_url'] ?? '').toString();
    final finalImageUrl = ApiClient.getImageUrl(rawFotoUrl);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                color: AppColors.surfaceDim,
                child: finalImageUrl.isNotEmpty
                    ? Image.network(
                        finalImageUrl, // 👈 Memanggil URL yang sudah bersih
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: AppColors.outline,
                        ),
                      )
                    : Center(
                        child: Icon(
                          _getIconForProduk(name),
                          size: 56,
                          color: AppColors.outline.withOpacity(0.4),
                        ),
                      ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (isHabis || !isActive)
                        ? AppColors.errorContainer
                        : AppColors.successContainer,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    !isActive ? 'Nonaktif' : (isHabis ? 'Habis' : 'Aktif'),
                    style: AppTextStyles.labelSm.copyWith(
                      color: (isHabis || !isActive)
                          ? AppColors.errorText
                          : AppColors.successText,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BIAYA POIN',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatNumber(poin),
                              style: AppTextStyles.headlineMd.copyWith(
                                color: AppColors.textMain,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'STOK',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$stok',
                          style: AppTextStyles.headlineMd.copyWith(
                            color: isHabis
                                ? AppColors.error
                                : AppColors.textMain,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 15),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMain,
                          side: BorderSide(
                            color: AppColors.outlineVariant.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onToggle,
                        icon: Icon(
                          isActive
                              ? Icons.block_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 15,
                        ),
                        label: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isActive
                              ? AppColors.error
                              : AppColors.primary,
                          side: BorderSide(
                            color: isActive
                                ? AppColors.error.withOpacity(0.4)
                                : AppColors.primary.withOpacity(0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
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

  IconData _getIconForProduk(String name) {
    final n = name.toLowerCase();
    if (n.contains('sikat')) return Icons.brush_rounded;
    if (n.contains('tas') || n.contains('kantong')) return Icons.shopping_bag_rounded;
    if (n.contains('botol') || n.contains('tumbler')) return Icons.water_drop_rounded;
    if (n.contains('beras') || n.contains('minyak') || n.contains('gula')) return Icons.bakery_dining_rounded;
    return Icons.inventory_2_rounded;
  }

  String _formatNumber(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return result.toString();
  }
}

// ─── Add & Edit Form Produk Sheet ─────────────────────────────────────────────
class _FormProdukSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? produkData;
  const _FormProdukSheet({this.produkData});

  @override
  ConsumerState<_FormProdukSheet> createState() => _FormProdukSheetState();
}

class _FormProdukSheetState extends ConsumerState<_FormProdukSheet> {
  late TextEditingController _namaController;
  late TextEditingController _descController;
  late TextEditingController _poinController;
  late TextEditingController _stokController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final isEdit = widget.produkData != null;
    _namaController = TextEditingController(
      text: isEdit
          ? (widget.produkData!['nama'] ?? widget.produkData!['nama_produk'])
          : '',
    );
    _descController = TextEditingController(
      text: isEdit ? (widget.produkData!['deskripsi'] ?? '') : '',
    );
    _poinController = TextEditingController(
      text: isEdit ? widget.produkData!['poin'].toString() : '',
    );
    _stokController = TextEditingController(
      text: isEdit ? widget.produkData!['stok'].toString() : '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _descController.dispose();
    _poinController.dispose();
    _stokController.dispose();
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
    final stok = int.tryParse(_stokController.text.trim()) ?? 0;

    if (nama.isEmpty || poin <= 0 || stok < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi dengan benar.')),
      );
      return;
    }

    final id = widget.produkData?['id'];
    final success = await ref
        .read(produkAdminProvider.notifier)
        .simpanProduk(
          id: id,
          nama: nama,
          deskripsi: desc,
          poin: poin,
          stok: stok,
          imageFile: _selectedImage,
        );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            id == null ? 'Produk berhasil ditambahkan!' : 'Produk diperbarui!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(produkAdminProvider).isSubmitting;
    final isEdit = widget.produkData != null;

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
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEdit ? 'Edit Produk' : 'Tambah Produk',
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

          // Upload foto area
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            color: AppColors.outline,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Unggah Foto',
                            style: TextStyle(
                              fontSize: 11,
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
              labelText: 'Nama Produk',
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
              labelText: 'Deskripsi Produk',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _poinController,
                  style: AppTextStyles.bodyMd,
                  decoration: InputDecoration(
                    labelText: 'Biaya Poin',
                    suffixText: 'Pts',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stokController,
                  style: AppTextStyles.bodyMd,
                  decoration: InputDecoration(
                    labelText: 'Jumlah Stok',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppButton(
            label: isEdit ? 'Simpan Perubahan' : 'Simpan Produk',
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : _simpan,
          ),
        ],
      ),
    );
  }
}
