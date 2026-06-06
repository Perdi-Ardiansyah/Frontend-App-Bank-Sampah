import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';
import '/../../data/providers/nasabah_provider.dart';
import '/../../data/models/produk_model.dart';
import '../../widgets/common/lonceng_notifikasi.dart';

class KatalogScreen extends ConsumerStatefulWidget {
  const KatalogScreen({super.key});

  @override
  ConsumerState<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends ConsumerState<KatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(katalogProvider);
    final query   = _searchController.text.toLowerCase();
    final filtered = state.kategori
        .where((k) =>
            query.isEmpty ||
            k.nama.toLowerCase().contains(query) ||
            k.deskripsi.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.textMain),
        title: const Text('Bank Sampah'),
        actions: [
          const LoncengNotifikasi(), 
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Katalog Harga',
                style: AppTextStyles.headlineLg
                    .copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Panduan poin yang didapatkan dari berbagai jenis sampah yang Anda setor.',
              style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 16),

            // Search
            TextFormField(
              controller: _searchController,
              style: AppTextStyles.bodyMd,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari jenis sampah...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.outline, size: 20),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 50),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            size: 18, color: AppColors.outline),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: state.isLoading
                  ? GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75, // 👈 Disesuaikan agar pas dengan foto
                      children: List.generate(
                          6,
                          (_) => Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceDim,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                              )),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  size: 40, color: AppColors.outline),
                              const SizedBox(height: 8),
                              Text('Kategori tidak ditemukan.',
                                  style: AppTextStyles.bodyMd.copyWith(
                                      color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () =>
                              ref.read(katalogProvider.notifier).fetch(),
                          child: GridView.builder(
                            itemCount: filtered.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75, // 👈 Rasio kartu diubah menjadi lebih tinggi
                            ),
                            itemBuilder: (_, i) =>
                                _KatalogCard(item: filtered[i]),
                          ),
                        ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── KARTU KATALOG BERBASIS FOTO ─────────────────────────────────────────────
class _KatalogCard extends StatelessWidget {
  final KategoriModel item;
  const _KatalogCard({required this.item});

  @override
  Widget build(BuildContext context) {
    print('Cek Gambar [${item.nama}]: ${item.imageUrl}');
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Area Gambar (Mendominasi Kartu) ──
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias, // Agar ujung gambar ikut melengkung
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover, // Gambar akan otomatis mengisi ruang
                      errorBuilder: (context, error, stackTrace) {
                        // Jika gambar gagal dimuat (misal server mati/link rusak)
                        return const Center(
                          child: Icon(Icons.broken_image_rounded, color: AppColors.outline, size: 32)
                        );
                      },
                    )
                  // Fallback jika tidak ada gambar di database
                  : const Center(
                      child: Icon(Icons.recycling_rounded, color: AppColors.outline, size: 32)
                    ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // ── 2. Area Teks & Informasi ──
          Text(
            item.nama,
            style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            item.deskripsi,
            style: AppTextStyles.bodySm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item.poinPerKg}',
                  style: AppTextStyles.headlineMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('Poin/kg',
                    style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.primary.withOpacity(0.7))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}