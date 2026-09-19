import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/customer_profile_remote_data_source.dart';
import '../../data/repositories/customer_profile_repository.dart';

/// Provider for CustomerProfileRemoteDataSource.
final customerProfileRemoteDataSourceProvider =
    Provider<CustomerProfileRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CustomerProfileRemoteDataSourceImpl(apiClient);
});

/// Provider for CustomerProfileRepository.
final customerProfileRepositoryProvider =
    Provider<CustomerProfileRepository>((ref) {
  final remoteDataSource = ref.watch(customerProfileRemoteDataSourceProvider);
  return CustomerProfileRepositoryImpl(remoteDataSource);
});

/// Provider to fetch and hold the authenticated customer's profile.
final customerProfileProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final repository = ref.watch(customerProfileRepositoryProvider);
  try {
    final response = await repository.getProfile();
    final user = response['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }
  } catch (_) {}

  // Graceful offline/cache fallback
  final localStorage = ref.watch(localStorageProvider);
  return localStorage.getJson(AppConstants.keyUserData);
});
