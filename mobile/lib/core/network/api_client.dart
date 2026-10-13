import 'package:dio/dio.dart';

/// 简易 API 客户端
class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8080'; // Android 模拟器访问本机
  // iOS 模拟器可用 http://127.0.0.1:8080
  // 真机请改成电脑局域网 IP

  late final Dio dio;

  ApiClient({String? token}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    final res = await dio.post(path, data: data);
    return Map<String, dynamic>.from(res.data as Map);
  }
}
