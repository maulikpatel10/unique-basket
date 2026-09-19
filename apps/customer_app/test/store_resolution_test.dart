import 'package:customer_app/features/address/data/repositories/customer_address_repository.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/store/data/datasources/store_remote_data_source.dart';
import 'package:customer_app/features/store/data/models/store_model.dart';
import 'package:customer_app/features/store/data/repositories/store_repository.dart';
import 'package:customer_app/features/store/presentation/providers/store_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockStoreRemoteDataSource implements StoreRemoteDataSource {
  final List<StoreModel> stores;
  final bool shouldThrow;
  int callCount = 0;
  double? lastLat;
  double? lastLng;
  String? lastFulfillment;

  MockStoreRemoteDataSource({
    this.stores = const [],
    this.shouldThrow = false,
  });

  @override
  Future<List<StoreModel>> getNearbyStores({
    required double latitude,
    required double longitude,
    String fulfillment = 'DELIVERY',
  }) async {
    callCount++;
    lastLat = latitude;
    lastLng = longitude;
    lastFulfillment = fulfillment;

    if (shouldThrow) {
      throw Exception('Store API network failure');
    }
    return stores;
  }
}

class MockAddressRepository implements CustomerAddressRepository {
  final Map<String, dynamic> addressesResponse;
  MockAddressRepository(this.addressesResponse);

  @override
  Future<Map<String, dynamic>> getAddresses() async => addressesResponse;

  @override
  Future<Map<String, dynamic>> addAddress({
    required String title,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async =>
      {};
}

void main() {
  group('Store Resolution Layer Tests', () {
    test('1. StoreModel.fromJson parses JSON accurately from backend schema', () {
      final json = {
        'id': 'b15093f4-1234-4567-89ab-cdef01234567',
        'storeId': 'STORE_RAJKOT_01',
        'name': 'Unique Basket - Ring Road Hub',
        'address': 'Plot 12, Ring Road',
        'city': 'Rajkot',
        'state': 'Gujarat',
        'pincode': '360005',
        'latitude': 22.3039,
        'longitude': 70.8022,
        'deliveryRadiusKm': 8.5,
        'phone': '+919876543210',
        'email': 'ringroad@uniquebasket.com',
        'openingTime': '07:00',
        'closingTime': '22:30',
        'isActive': true,
        'distanceKm': 2.34,
        'isEligible': true,
      };

      final store = StoreModel.fromJson(json);

      expect(store.id, equals('b15093f4-1234-4567-89ab-cdef01234567'));
      expect(store.storeId, equals('STORE_RAJKOT_01'));
      expect(store.name, equals('Unique Basket - Ring Road Hub'));
      expect(store.latitude, equals(22.3039));
      expect(store.longitude, equals(70.8022));
      expect(store.deliveryRadiusKm, equals(8.5));
      expect(store.isActive, isTrue);
      expect(store.distanceKm, equals(2.34));
      expect(store.isEligible, isTrue);
    });

    test('1b. StoreModel.fromJson handles String-encoded Decimal fields from PostgreSQL Prisma backend', () {
      final json = {
        'id': 'd6fe433e-2f2c-456d-85d5-30e079cbe10f',
        'storeId': 'STORE-005',
        'name': 'Unique Basket - Ayodhya Chowk',
        'address': 'ayodhya chowk, 150 feet ring road',
        'city': 'Rajkot',
        'state': 'Gujarat',
        'pincode': '360002',
        'latitude': '22.3129',
        'longitude': '70.767272',
        'deliveryRadiusKm': '10',
        'phone': '+919327835715',
        'openingTime': '08:00',
        'closingTime': '22:00',
        'isActive': true,
        'distanceKm': 3.73,
        'isEligible': true,
      };

      final store = StoreModel.fromJson(json);

      expect(store.storeId, equals('STORE-005'));
      expect(store.latitude, equals(22.3129));
      expect(store.longitude, equals(70.767272));
      expect(store.deliveryRadiusKm, equals(10.0));
      expect(store.distanceKm, equals(3.73));
      expect(store.isEligible, isTrue);
    });

    test('2. StoreRepository resolves nearest active & eligible store', () async {
      final mockDataSource = MockStoreRemoteDataSource(stores: [
        const StoreModel(
          id: 'store_far',
          storeId: 'FAR_01',
          name: 'Far Store',
          address: 'Highway',
          city: 'Rajkot',
          state: 'Gujarat',
          pincode: '360001',
          latitude: 22.35,
          longitude: 70.85,
          phone: '123',
          openingTime: '08:00',
          closingTime: '22:00',
          isActive: true,
          distanceKm: 5.2,
          isEligible: true,
        ),
        const StoreModel(
          id: 'store_near',
          storeId: 'NEAR_01',
          name: 'Near Store',
          address: 'Main St',
          city: 'Rajkot',
          state: 'Gujarat',
          pincode: '360002',
          latitude: 22.31,
          longitude: 70.81,
          phone: '123',
          openingTime: '08:00',
          closingTime: '22:00',
          isActive: true,
          distanceKm: 1.1,
          isEligible: true,
        ),
        const StoreModel(
          id: 'store_ineligible',
          storeId: 'INELIGIBLE_01',
          name: 'Out of Radius Store',
          address: 'Far Out',
          city: 'Rajkot',
          state: 'Gujarat',
          pincode: '360003',
          latitude: 22.40,
          longitude: 70.90,
          phone: '123',
          openingTime: '08:00',
          closingTime: '22:00',
          isActive: true,
          distanceKm: 0.5,
          isEligible: false, // Ineligible despite shorter distance
        ),
      ]);

      final repository = StoreRepositoryImpl(mockDataSource);
      final servingStore = await repository.resolveServingStore(
        latitude: 22.3039,
        longitude: 70.8022,
      );

      expect(servingStore, isNotNull);
      expect(servingStore!.storeId, equals('NEAR_01'));
      expect(servingStore.distanceKm, equals(1.1));
    });

    test('3. StoreRepository ignores inactive stores', () async {
      final mockDataSource = MockStoreRemoteDataSource(stores: [
        const StoreModel(
          id: 'store_inactive',
          storeId: 'INACTIVE_01',
          name: 'Inactive Hub',
          address: 'Main St',
          city: 'Rajkot',
          state: 'Gujarat',
          pincode: '360001',
          latitude: 22.30,
          longitude: 70.80,
          phone: '123',
          openingTime: '08:00',
          closingTime: '22:00',
          isActive: false, // Inactive!
          distanceKm: 0.4,
          isEligible: true,
        ),
      ]);

      final repository = StoreRepositoryImpl(mockDataSource);
      final servingStore = await repository.resolveServingStore(
        latitude: 22.3039,
        longitude: 70.8022,
      );

      expect(servingStore, isNull);
    });

    test('4. StoreRepository returns null when no stores are eligible', () async {
      final mockDataSource = MockStoreRemoteDataSource(stores: [
        const StoreModel(
          id: 'store_outside',
          storeId: 'OUT_01',
          name: 'Outside Radius Store',
          address: 'Outside',
          city: 'Rajkot',
          state: 'Gujarat',
          pincode: '360001',
          latitude: 22.50,
          longitude: 70.99,
          phone: '123',
          openingTime: '08:00',
          closingTime: '22:00',
          isActive: true,
          distanceKm: 18.0,
          isEligible: false,
        ),
      ]);

      final repository = StoreRepositoryImpl(mockDataSource);
      final servingStore = await repository.resolveServingStore(
        latitude: 22.3039,
        longitude: 70.8022,
      );

      expect(servingStore, isNull);
    });

    test('5. formatStoreDistance handles meters and kilometers accurately', () {
      expect(formatStoreDistance(null), isNull);
      expect(formatStoreDistance(0.45), equals('450 m away'));
      expect(formatStoreDistance(0.93), equals('930 m away'));
      expect(formatStoreDistance(1.0), equals('1.0 km away'));
      expect(formatStoreDistance(2.45), equals('2.5 km away'));
      expect(formatStoreDistance(10.0), equals('10.0 km away'));
    });

    test('6. servingStoreProvider integrates with defaultCustomerAddressProvider',
        () async {
      final mockDataSource = MockStoreRemoteDataSource(stores: [
        const StoreModel(
          id: 'store_1',
          storeId: 'STORE_LIVE_01',
          name: 'Live Store Hub',
          address: 'Hub St',
          city: 'Rajkot',
          state: 'Gujarat',
          pincode: '360001',
          latitude: 22.30,
          longitude: 70.80,
          phone: '123',
          openingTime: '08:00',
          closingTime: '22:00',
          isActive: true,
          distanceKm: 0.85,
          isEligible: true,
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          storeRemoteDataSourceProvider.overrideWithValue(mockDataSource),
          customerAddressRepositoryProvider.overrideWithValue(
            MockAddressRepository({
              'addresses': [
                {
                  'id': 'addr_1',
                  'title': 'Home',
                  'addressLine': '104 Green Heights',
                  'city': 'Rajkot',
                  'latitude': 22.3039,
                  'longitude': 70.8022,
                  'isDefault': true,
                }
              ]
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      final servingStore = await container.read(servingStoreProvider.future);

      expect(servingStore, isNotNull);
      expect(servingStore!.storeId, equals('STORE_LIVE_01'));
      expect(servingStore.distanceKm, equals(0.85));
      expect(mockDataSource.callCount, equals(1));
      expect(mockDataSource.lastLat, equals(22.3039));
      expect(mockDataSource.lastLng, equals(70.8022));
      expect(mockDataSource.lastFulfillment, equals('DELIVERY'));
    });

    test('7. Missing coordinates in default address skips Store API call',
        () async {
      final mockDataSource = MockStoreRemoteDataSource(stores: []);

      final container = ProviderContainer(
        overrides: [
          storeRemoteDataSourceProvider.overrideWithValue(mockDataSource),
          customerAddressRepositoryProvider.overrideWithValue(
            MockAddressRepository({
              'addresses': [
                {
                  'id': 'addr_no_coords',
                  'title': 'Home',
                  'addressLine': 'Missing LatLng',
                  'city': 'Rajkot',
                  'latitude': null,
                  'longitude': null,
                  'isDefault': true,
                }
              ]
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      final servingStore = await container.read(servingStoreProvider.future);

      expect(servingStore, isNull);
      expect(mockDataSource.callCount, equals(0)); // API was NOT called
    });
  });
}
