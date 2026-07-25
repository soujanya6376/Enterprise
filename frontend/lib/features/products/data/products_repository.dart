import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import 'product.dart';

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(ref.watch(dioProvider)),
);

class ProductsRepository {
  ProductsRepository(this._dio);
  final Dio _dio;

  Future<List<Product>> list({String? search, bool? activeOnly}) async {
    final res = await _dio.get('/products', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (activeOnly == true) 'isActive': true,
      'limit': 100,
    });
    final data = (res.data['data'] as List).cast<Map>();
    return data.map(Product.fromJson).toList();
  }

  Future<Product> create(Map body) async {
    final res = await _dio.post('/products', data: body);
    return Product.fromJson(res.data as Map);
  }

  Future<Product> update(String id, Map body) async {
    final res = await _dio.patch('/products/$id', data: body);
    return Product.fromJson(res.data as Map);
  }

  Future<void> setStatus(String id, bool isActive) =>
      _dio.patch('/products/$id/status', data: {'isActive': isActive});

  Future<void> delete(String id) => _dio.delete('/products/$id');
}

/// Async products list for admin + billing screens.
final productsProvider = FutureProvider.family<List<Product>, String>((ref, search) {
  return ref.watch(productsRepositoryProvider).list(search: search);
});
