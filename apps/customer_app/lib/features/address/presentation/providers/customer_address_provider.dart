import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/customer_address_remote_data_source.dart';
import '../../data/repositories/customer_address_repository.dart';

final customerAddressRemoteDataSourceProvider =
    Provider<CustomerAddressRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CustomerAddressRemoteDataSourceImpl(apiClient);
});

final customerAddressRepositoryProvider =
    Provider<CustomerAddressRepository>((ref) {
  final remoteDataSource = ref.watch(customerAddressRemoteDataSourceProvider);
  return CustomerAddressRepositoryImpl(remoteDataSource);
});

/// Provider to fetch all saved addresses for the authenticated customer.
final customerAddressesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(customerAddressRepositoryProvider);
  try {
    final response = await repository.getAddresses();
    final addresses = response['addresses'];
    if (addresses is List) {
      return addresses.cast<Map<String, dynamic>>();
    }
    return [];
  } catch (e) {
    // Fallback to local storage if offline or during initial setup
    final localStorage = ref.watch(localStorageProvider);
    final localAddr = localStorage.getJson(AppConstants.keyUserAddress);
    if (localAddr != null) {
      return [
        {
          'title': localAddr['type'] ?? 'Home',
          'addressLine':
              localAddr['fullAddress'] ?? localAddr['areaLocality'] ?? '',
          'city': localAddr['city'] ?? '',
          'state': localAddr['state'] ?? '',
          'pincode': localAddr['pinCode'] ?? '',
          'isDefault': true,
        }
      ];
    }
    // Rethrow if neither remote API nor local cache is available
    rethrow;
  }
});

/// Provider that resolves the active / default address.
final defaultCustomerAddressProvider =
    Provider<AsyncValue<Map<String, dynamic>?>>((ref) {
  final addressesAsync = ref.watch(customerAddressesProvider);
  return addressesAsync.whenData((addresses) {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a['isDefault'] == true,
      orElse: () => addresses.first,
    );
  });
});
