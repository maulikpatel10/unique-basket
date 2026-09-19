import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../address/presentation/providers/customer_address_provider.dart';
import '../../data/datasources/store_remote_data_source.dart';
import '../../data/models/store_model.dart';
import '../../data/repositories/store_repository.dart';

final storeRemoteDataSourceProvider = Provider<StoreRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StoreRemoteDataSourceImpl(apiClient);
});

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final remoteDataSource = ref.watch(storeRemoteDataSourceProvider);
  return StoreRepositoryImpl(remoteDataSource);
});

double? _parseCoordinate(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

/// Provider for list of nearby stores resolved from customer default address coordinates.
final nearbyStoresProvider = FutureProvider<List<StoreModel>>((ref) async {
  final addresses = await ref.watch(customerAddressesProvider.future);
  if (addresses.isEmpty) {
    return [];
  }

  final defaultAddress = addresses.firstWhere(
    (a) => a['isDefault'] == true,
    orElse: () => addresses.first,
  );

  final lat = _parseCoordinate(defaultAddress['latitude']);
  final lng = _parseCoordinate(defaultAddress['longitude']);

  if (lat == null || lng == null) {
    return [];
  }

  if (lat == 0.0 && lng == 0.0) {
    return [];
  }

  final repository = ref.watch(storeRepositoryProvider);
  return repository.getNearbyStores(latitude: lat, longitude: lng);
});

/// Provider that resolves the primary serving store (nearest eligible active store).
final servingStoreProvider = FutureProvider<StoreModel?>((ref) async {
  final addresses = await ref.watch(customerAddressesProvider.future);
  if (addresses.isEmpty) {
    return null;
  }

  final defaultAddress = addresses.firstWhere(
    (a) => a['isDefault'] == true,
    orElse: () => addresses.first,
  );

  final lat = _parseCoordinate(defaultAddress['latitude']);
  final lng = _parseCoordinate(defaultAddress['longitude']);

  if (lat == null || lng == null) {
    return null;
  }

  if (lat == 0.0 && lng == 0.0) {
    return null;
  }

  final repository = ref.watch(storeRepositoryProvider);
  return repository.resolveServingStore(latitude: lat, longitude: lng);
});

/// Helper utility to format legitimate distance from real store resolution.
String? formatStoreDistance(double? distanceKm) {
  if (distanceKm == null) return null;
  if (distanceKm < 1.0) {
    final meters = (distanceKm * 1000).round();
    return '$meters m away';
  }
  return '${distanceKm.toStringAsFixed(1)} km away';
}
