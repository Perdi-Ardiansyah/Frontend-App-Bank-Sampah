import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../../core/theme/app_colors.dart';
import '/../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/app_button.dart';
import '../../../../data/providers/admin_provider.dart'; 
// Sesuaikan jumlah titik-titiknya dengan posisi folder Anda
import '../notifikasi/admin_akun_screen.dart';

class AdminSetorScreen extends ConsumerStatefulWidget {
  const AdminSetorScreen({super.key});

  @override
  ConsumerState<AdminSetorScreen> createState() => _AdminSetorScreenState();
}

class _AdminSetorScreenState extends ConsumerState<AdminSetorScreen> {
  TextEditingController? _nasabahSearchController;
  final _beratController = TextEditingController(text: '0.0');
  final _catatanController = TextEditingController();
  
  int? _selectedKategoriId; 
  int? _selectedNasabahId;

  @override
  void dispose() {
    _beratController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _submitSetoran() async {
    if (_selectedNasabahId == null) {
      _showError(context, 'Pilih nasabah dari daftar dropdown pencarian.');
      return;
    }

    if (_selectedKategoriId == null) {
      _showError(context, 'Pilih Kategori Sampah terlebih dahulu.');
      return;
    }

    final berat = double.tryParse(_beratController.text.trim());
    if (berat == null || berat <= 0) {
      _showError(context, 'Masukkan berat yang valid (lebih dari 0).');
      return;
    }

    final success = await ref.read(setoranAdminProvider.notifier).simpanSetoran(
      userId: _selectedNasabahId!, 
      kategoriId: _selectedKategoriId!,
      beratKg: berat,
      catatan: _catatanController.text.isNotEmpty ? _catatanController.text : null,
    );

    if (success && mounted) {
      _showSuccess(context); 
      
      _nasabahSearchController?.clear();
      _selectedNasabahId = null;
      _beratController.text = '0.0';
      _catatanController.clear();
      setState(() => _selectedKategoriId = null);

      ref.read(dashboardAdminProvider.notifier).fetch();
    } else if (mounted) {
      final errorMessage = ref.read(setoranAdminProvider).error ?? 'Gagal menyimpan setoran.';
      _showError(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final setoranState = ref.watch(setoranAdminProvider);
    final dashboardState = ref.watch(dashboardAdminProvider);
    
    // MENARIK DATA ASLI DARI PROVIDER NASABAH
    final nasabahState = ref.watch(listNasabahProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Setor Sampah'), 
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Input Setoran Sampah',
                        style: AppTextStyles.headlineLg
                            .copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      'Catat data setoran nasabah ke dalam sistem untuk diproses.',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.outlineVariant.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          // ===================================================
                          // NAMA NASABAH ASLI DARI DATABASE
                          // ===================================================
                          const _FormLabel('Nama Nasabah'),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Autocomplete<Map<String, dynamic>>(
                                displayStringForOption: (option) => option['nama'] ?? '-',
                                
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable<Map<String, dynamic>>.empty();
                                  }
                                  // Pencarian filter data dari API
                                  return nasabahState.data.where((nasabah) {
                                    final nama = (nasabah['nama'] ?? '').toString().toLowerCase();
                                    final idNasabah = (nasabah['id_nasabah'] ?? '').toString().toLowerCase();
                                    final search = textEditingValue.text.toLowerCase();
                                    
                                    // Bisa dicari berdasarkan nama ATAU id_nasabah
                                    return nama.contains(search) || idNasabah.contains(search);
                                  });
                                },

                                onSelected: (Map<String, dynamic> selection) {
                                  setState(() {
                                    _selectedNasabahId = selection['id'];
                                  });
                                },

                                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                  _nasabahSearchController = controller;
                                  
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    style: AppTextStyles.bodyMd,
                                    onChanged: (value) {
                                      if (_selectedNasabahId != null) {
                                        setState(() => _selectedNasabahId = null);
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: nasabahState.isLoading 
                                          ? 'Memuat data nasabah...' 
                                          : 'Ketik nama atau ID nasabah...',
                                      prefixIcon: nasabahState.isLoading 
                                          ? const Padding(
                                              padding: EdgeInsets.all(14.0),
                                              child: SizedBox(
                                                  width: 16, height: 16, 
                                                  child: CircularProgressIndicator(strokeWidth: 2)),
                                            )
                                          : const Icon(Icons.search_rounded,
                                              color: AppColors.outline, size: 20),
                                      prefixIconConstraints: const BoxConstraints(minWidth: 50),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: AppColors.outlineVariant.withOpacity(0.4)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: AppColors.outlineVariant.withOpacity(0.4)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppColors.primary, width: 1.5),
                                      ),
                                    ),
                                  );
                                },

                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(12),
                                      clipBehavior: Clip.antiAlias,
                                      child: SizedBox(
                                        width: constraints.biggest.width,
                                        height: options.length > 3 ? 220 : options.length * 70.0,
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount: options.length,
                                          itemBuilder: (context, index) {
                                            final option = options.elementAt(index);
                                            return ListTile(
                                              tileColor: AppColors.surfaceWhite,
                                              title: Text(option['nama'] ?? '-', 
                                                  style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                                              subtitle: Text(option['id_nasabah'] ?? '-', 
                                                  style: AppTextStyles.bodySm.copyWith(color: AppColors.primary)),
                                              onTap: () {
                                                onSelected(option);
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          ),

                          const SizedBox(height: 16),

                          // Kategori Sampah
                          const _FormLabel('Kategori Sampah'),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.outlineVariant.withOpacity(0.4)),
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.surfaceWhite,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedKategoriId,
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: setoranState.isLoading 
                                    ? const Text('Memuat kategori...') 
                                    : Text('Pilih Kategori',
                                      style: AppTextStyles.bodyMd.copyWith(
                                          color: AppColors.onSurfaceVariant.withOpacity(0.5))),
                                ),
                                isExpanded: true,
                                icon: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMain),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                items: setoranState.kategoriList.map((k) {
                                  return DropdownMenuItem<int>(
                                    value: k.id,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(k.nama , style: AppTextStyles.bodyMd),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedKategoriId = v),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Berat Bersih
                          const _FormLabel('Berat Bersih'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _beratController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
                                  decoration: const InputDecoration(
                                    hintText: '0.0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                      borderSide: BorderSide(color: Color(0xFFBCCAC0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                      borderSide: BorderSide(color: Color(0xFFBCCAC0), width: 0.8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 54,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
                                ),
                                alignment: Alignment.center,
                                child: Text('kg',
                                    style: AppTextStyles.labelMd.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Catatan
                          const _FormLabel('Catatan (Opsional)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _catatanController,
                            maxLines: 3,
                            style: AppTextStyles.bodyMd,
                            decoration: const InputDecoration(
                              hintText: 'Tambahkan keterangan kondisi sampah jika perlu...',
                              alignLabelWithHint: true,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Buttons
                          AppButton(
                            label: 'Simpan Setoran',
                            isLoading: setoranState.isSubmitting,
                            prefixIcon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                            onPressed: setoranState.isSubmitting ? null : _submitSetoran,
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            label: 'Batal',
                            variant: ButtonVariant.secondary,
                            onPressed: () {
                              _nasabahSearchController?.clear();
                              _selectedNasabahId = null;
                              _beratController.text = '0.0';
                              _catatanController.clear();
                              setState(() => _selectedKategoriId = null);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Ringkasan Hari Ini
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
                            children: [
                              const Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text('Ringkasan Hari Ini',
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _RingkasanItem(
                                label: 'Total Terkumpul',
                                value: '${dashboardState.data?.setoranHariIniKg ?? 0} kg',
                              ),
                              _RingkasanItem(
                                label: 'Transaksi',
                                value: '${dashboardState.data?.setoranHariIniTransaksi ?? 0}',
                              ),
                              _RingkasanItem(
                                label: 'Poin Diberikan',
                                value: '${dashboardState.data?.poinDiberikanHariIni ?? 0}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Setoran berhasil disimpan!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700, fontSize: 14));
  }
}

class _RingkasanItem extends StatelessWidget {
  final String label;
  final String value;
  const _RingkasanItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySm.copyWith(color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.headlineMd.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              )),
        ],
      ),
    );
  }
}