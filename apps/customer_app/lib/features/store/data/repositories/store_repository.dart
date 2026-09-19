import '../datasources/store_remote_data_source.dart';
import '../models/store_model.dart';

abstract class StoreRepository {
  Future<List<StoreModel>> getNearbyStores({
    required double latitude,
    required double longitude,
    String fulfillment = 'DELIVERY',
  });

  Future<StoreModel?> resolveServingStore({
    required double latitude,
    required double longitude,
  });
}

class StoreRepositoryImpl implements StoreRepository {
  final StoreRemoteDataSource _remoteDataSource;

  StoreRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<StoreModel>> getNearbyStores({
    required double latitude,
    required double longitude,
    String fulfillment = 'DELIVERY',
  }) {
    return _remoteDataSource.getNearbyStores(
      latitude: latitude,
      longitude: longitude,
      fulfillment: fulfillment,
    );
  }

  @override
  Future<StoreModel?> resolveServingStore({
    required double latitude,
    required double longitude,
  }) async {
    final stores = await getNearbyStores(
      latitude: latitude,
      longitude: longitude,
      fulfillment: 'DELIVERY',
    );

    // Filter rules:
    // 1. isActive == true
    // 2. isEligible == true
    // 3. nearest distanceKm
    final eligibleStores = stores
        .where((s) => s.isActive && s.isEligible && s.distanceKm != null)
        .toList();

    if (eligibleStores.isEmpty) {
      return null;
    }

    eligibleStores.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
    return eligibleStores.first;
  }
}
