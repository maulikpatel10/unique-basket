import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> getFeaturedProducts();
  Future<List<ProductModel>> getStoreProducts(String storeId, {String? categoryId});
  Future<List<BannerModel>> getBanners();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient _apiClient;

  HomeRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.get(ApiEndpoints.categories);
    if (response is List) {
      return response
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List;
      return list
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<ProductModel>> getStoreProducts(String storeId, {String? categoryId}) async {
    final response = await _apiClient.get(
      ApiEndpoints.storeProducts(storeId),
      queryParameters: categoryId != null ? {'categoryId': categoryId} : null,
    );
    if (response is List) {
      return response
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .where((p) => p.isPurchasable)
          .toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List;
      return list
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .where((p) => p.isPurchasable)
          .toList();
    }
    return [];
  }

  @override
  Future<List<ProductModel>> getFeaturedProducts() async {
    final response = await _apiClient.get(ApiEndpoints.products);
    if (response is List) {
      return response
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .where((p) => p.isPurchasable)
          .toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List;
      return list
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .where((p) => p.isPurchasable)
          .toList();
    }
    return [];
  }

  @override
  Future<List<BannerModel>> getBanners() async {
    final response = await _apiClient.get(ApiEndpoints.banners);
    if (response is List) {
      return response
          .map((item) => BannerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List;
      return list
          .map((item) => BannerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
