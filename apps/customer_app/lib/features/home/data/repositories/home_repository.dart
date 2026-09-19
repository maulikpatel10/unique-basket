import '../datasources/home_remote_data_source.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

abstract class HomeRepository {
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> getFeaturedProducts();
  Future<List<ProductModel>> getStoreProducts(String storeId, {String? categoryId});
  Future<List<BannerModel>> getBanners();
}

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;

  HomeRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<CategoryModel>> getCategories() {
    return _remoteDataSource.getCategories();
  }

  @override
  Future<List<ProductModel>> getFeaturedProducts() {
    return _remoteDataSource.getFeaturedProducts();
  }

  @override
  Future<List<ProductModel>> getStoreProducts(String storeId, {String? categoryId}) {
    return _remoteDataSource.getStoreProducts(storeId, categoryId: categoryId);
  }

  @override
  Future<List<BannerModel>> getBanners() {
    return _remoteDataSource.getBanners();
  }
}
