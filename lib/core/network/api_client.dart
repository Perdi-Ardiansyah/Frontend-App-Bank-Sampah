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

  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // 1. Kita langsung PAKSA tambahkan interceptor di sini menggunakan cascade (..)
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

  // 2. Tidak perlu lagi pakai logika if (isEmpty)
  static Dio get instance => _dio;
}

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
    if (err.response?.statusCode == 401) {
      print('🚨 ERROR 401: Token ditolak atau tidak valid!');
      await StorageHelper.clearAll();

      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/session-expired', // Pastikan route ini ada di main.dart
          (route) => false,
        );
      }
    }
    handler.next(err);
  }
}