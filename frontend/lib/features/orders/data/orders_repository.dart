import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(ref.watch(dioProvider)),
);

class OrdersRepository {
  OrdersRepository(this._dio);
  final Dio _dio;

  Future<Map> create(List<Map> items) async {
    final res = await _dio.post('/orders', data: {'items': items});
    return res.data as Map;
  }

  Future<Map> pay({required String orderId, required double amount, required String method}) async {
    final res = await _dio.post('/payments', data: {
      'orderId': orderId,
      'amount': amount,
      'paymentMethod': method,
    });
    return res.data as Map;
  }

  Future<List<Map>> history({String? search}) async {
    final res = await _dio.get('/orders', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'limit': 50,
    });
    return (res.data['data'] as List).cast<Map>();
  }

  Future<Map> detail(String id) async {
    final res = await _dio.get('/orders/$id');
    return res.data as Map;
  }

  /// URLs for printing (open in browser / external viewer).
  String thermalUrl(String orderId) => '${AppConfig.apiBaseUrl}/invoice/$orderId/thermal';
  String pdfUrl(String orderId) => '${AppConfig.apiBaseUrl}/invoice/$orderId/pdf';
}
