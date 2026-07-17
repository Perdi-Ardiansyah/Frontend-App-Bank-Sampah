import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../utils/storage_helper.dart';

/// GlobalKey untuk Navigator — diperlukan agar interceptor bisa redirect
/// tanpa BuildContext. Daftarkan di MaterialApp: navigatorKey: navigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Ganti sesuai environment:
// Emulator Android : 'http://10.0.2.2:8000/api'
// Device fisik     : 'http://192.168.x.x:8000/api'
// Production       : 'https://yourdomain.com/api'
// web              : 'http://127.0.0.1:8000/api'

/// ApiClient — Dio instance tunggal (singleton) untuk semua request ke Laravel.
class ApiClient {
  ApiClient._();

  // 1. Variabel utama host (Domain Hosting Anda)
  // static const String serverUrl = 'https://banksampahkita.kotapintar.my.id';
  static const String serverUrl = 'http://10.0.2.2:8000';
  // URL untuk Dio (API Laravel biasanya wajib ada akhiran /api)
  static const String baseUrl = '$serverUrl/api';

  // 2. FUNGSI PINTAR PEMBERSIH GAMBAR TERPUSAT
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    // 1. SAPU BERSIH: Paksa ubah semua localhost menjadi domain asli cPanel Anda

    path = path.replaceAll('http://10.0.2.2:8000', 'http://10.0.2.2:8000');
    path = path.replaceAll('http://localhost:8000', 'http://10.0.2.2:8000');
    path = path.replaceAll('http://127.0.0.1:8000', 'http://10.0.2.2:8000');
    // path = path.replaceAll('http://10.0.2.2:8000', 'https://banksampahkita.kotapintar.my.id');
    // path = path.replaceAll('http://localhost:8000', 'https://banksampahkita.kotapintar.my.id');
    // path = path.replaceAll('http://127.0.0.1:8000', 'https://banksampahkita.kotapintar.my.id');

    // 2. Jika setelah diganti jalurnya sudah berawalan http yang benar, langsung tampilkan
    if (path.startsWith('http')) {
      return path;
    }

    // 3. Jika data dari database hanya berupa jalur pendek (contoh: kategori/kaca.jpg)
    // KITA PAKSA PAKAI DOMAIN CPANEL, bukan variabel lagi.
    // String domain = 'https://banksampahkita.kotapintar.my.id';
    String domain = 'http://10.0.2.2:8000';

    
    if (path.startsWith('/')) {
      path = path.substring(1); 
    }

    return '$domain/storage/$path';
  }

  // 3. Kita langsung PAKSA tambahkan interceptor di sini menggunakan cascade (..)
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(_AuthInterceptor());

  // 4. Tidak perlu lagi pakai logika if (isEmpty)
  static Dio get instance => _dio;
}

// ── JWT Interceptor ──────────────────────────────────────────────────────────

// ── JWT Interceptor ──────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageHelper.getToken();
    
    // CCTV kita pasang lagi di sini
    print('\n=======================================');
    print('🚀 REQUEST KE: ${options.baseUrl}${options.path}');
    print('🔑 TOKEN: $token');
    print('=======================================\n');

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 1. KITA TANGKAP JALUR (PATH) APA YANG SEDANG DIAKSES
    final String path = err.requestOptions.path;

    // 2. KITA TAMBAHKAN SYARAT: && !path.contains('login')
    // Artinya: Jika eror 401 DAN jalurnya BUKAN dari proses login
    if (err.response?.statusCode == 401 && !path.contains('login')) {
      print('🚨 ERROR 401: Token ditolak atau tidak valid di path $path!');
      await StorageHelper.clearAll();

      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/session-expired', // Pastikan route ini ada di main.dart
          (route) => false,
        );
      }
    }
    
    // Biarkan eror dari /login diteruskan ke UI (misal untuk notif "Password Salah")
    handler.next(err);
  }
}