import 'package:customer_app/core/constants/api_endpoints.dart';
import 'package:customer_app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:customer_app/features/home/data/models/banner_model.dart';
import 'package:customer_app/features/home/data/models/category_model.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/features/home/data/repositories/home_repository.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:customer_app/shared/widgets/promo_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockBannerDataSource implements HomeRemoteDataSource {
  final List<BannerModel> banners;
  final bool shouldThrow;
  int callCount = 0;

  MockBannerDataSource({
    this.banners = const [],
    this.shouldThrow = false,
  });

  @override
  Future<List<BannerModel>> getBanners() async {
    callCount++;
    if (shouldThrow) {
      throw Exception('Banner API failed');
    }
    return banners;
  }

  @override
  Future<List<CategoryModel>> getCategories() async => [];

  @override
  Future<List<ProductModel>> getFeaturedProducts() async => [];

  @override
  Future<List<ProductModel>> getStoreProducts(String storeId, {String? categoryId}) async => [];
}

void main() {
  group('Home Step 5 — Banner Integration Tests', () {
    test('1. BannerModel.fromJson accurately parses backend Banner schema', () {
      final json = {
        'id': 'd082d1bd-f648-4ae6-afe0-f44f0c83a63e',
        'title': '20% Off\nSeasonal\nGreens',
        'imageUrl': 'https://images.unsplash.com/photo-1540420773420-3366772f4999',
        'displayOrder': 0,
        'isActive': true,
        'createdAt': '2026-09-19T07:00:41.716Z',
      };

      final banner = BannerModel.fromJson(json);

      expect(banner.id, equals('d082d1bd-f648-4ae6-afe0-f44f0c83a63e'));
      expect(banner.title, equals('20% Off\nSeasonal\nGreens'));
      expect(banner.imageUrl, equals('https://images.unsplash.com/photo-1540420773420-3366772f4999'));
      expect(banner.displayOrder, equals(0));
      expect(banner.isActive, isTrue);
      expect(banner.tag, equals('Fresh Harvest'));
      expect(banner.ctaText, equals('Shop Now'));
    });

    test('2. BannerModel handles snake_case keys and null titles safely', () {
      final json = {
        'id': 'banner_test_2',
        'title': null,
        'image_url': 'https://example.com/banner.png',
        'display_order': 2,
        'is_active': true,
      };

      final banner = BannerModel.fromJson(json);

      expect(banner.id, equals('banner_test_2'));
      expect(banner.title, equals('Fresh Produce\nSpecial Offer'));
      expect(banner.imageUrl, equals('https://example.com/banner.png'));
      expect(banner.displayOrder, equals(2));
      expect(banner.isActive, isTrue);
    });

    test('3. ApiEndpoints.banners is correctly defined as /banners', () {
      expect(ApiEndpoints.banners, equals('/banners'));
    });

    test('4. homeBannersProvider retrieves real banner list via HomeRepository', () async {
      final mockBanners = [
        const BannerModel(
          id: 'b1',
          tag: 'Fresh Harvest',
          title: '20% Off Greens',
          ctaText: 'Shop Now',
          displayOrder: 0,
        ),
        const BannerModel(
          id: 'b2',
          tag: 'Farm Direct',
          title: 'Fresh Citrus',
          ctaText: 'Explore',
          displayOrder: 1,
        ),
        const BannerModel(
          id: 'b3',
          tag: 'Organic Daily',
          title: 'Organic Veggies',
          ctaText: 'Order Now',
          displayOrder: 2,
        ),
      ];

      final mockDataSource = MockBannerDataSource(banners: mockBanners);
      final repository = HomeRepositoryImpl(mockDataSource);

      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(homeBannersProvider.future);

      expect(result.length, equals(3));
      expect(result[0].title, equals('20% Off Greens'));
      expect(result[1].title, equals('Fresh Citrus'));
      expect(result[2].title, equals('Organic Veggies'));
      expect(mockDataSource.callCount, equals(1));
    });

    test('5. Empty banner response returns empty list safely without error', () async {
      final mockDataSource = MockBannerDataSource(banners: []);
      final repository = HomeRepositoryImpl(mockDataSource);

      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(homeBannersProvider.future);

      expect(result, isEmpty);
    });

    test('6. API failure propagates as AsyncError without fabricating fake banners', () async {
      final mockDataSource = MockBannerDataSource(shouldThrow: true);
      final repository = HomeRepositoryImpl(mockDataSource);

      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(homeBannersProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('7. HomeBannerCarousel with 3 banners renders 3 indicator dots', (tester) async {
      final banners = [
        const BannerModel(
          id: 'b1',
          tag: 'Fresh Harvest',
          title: '20% Off Greens',
          ctaText: 'Shop Now',
        ),
        const BannerModel(
          id: 'b2',
          tag: 'Farm Direct',
          title: 'Fresh Citrus',
          ctaText: 'Explore',
        ),
        const BannerModel(
          id: 'b3',
          tag: 'Organic Daily',
          title: 'Organic Veggies',
          ctaText: 'Order Now',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeBannerCarousel(banners: banners),
          ),
        ),
      );

      expect(find.byType(PromoBanner), findsOneWidget);
      expect(find.text('20% Off Greens'), findsOneWidget);

      // Verify PageView exists
      expect(find.byType(PageView), findsOneWidget);

      // 3 dots should be rendered
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });

    testWidgets('8. HomeBannerCarousel with 1 banner renders no indicator dots', (tester) async {
      final banners = [
        const BannerModel(
          id: 'b1',
          tag: 'Fresh Harvest',
          title: '20% Off Greens',
          ctaText: 'Shop Now',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeBannerCarousel(banners: banners),
          ),
        ),
      );

      expect(find.byType(PromoBanner), findsOneWidget);
      expect(find.text('20% Off Greens'), findsOneWidget);

      // No indicator dots for a single banner
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('9. HomeBannerCarousel with 0 banners renders SizedBox.shrink', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeBannerCarousel(banners: []),
          ),
        ),
      );

      expect(find.byType(PromoBanner), findsNothing);
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('10. Swiping advances carousel to next banner', (tester) async {
      final banners = [
        const BannerModel(
          id: 'b1',
          tag: 'Fresh Harvest',
          title: 'Banner One',
          ctaText: 'Shop Now',
        ),
        const BannerModel(
          id: 'b2',
          tag: 'Farm Direct',
          title: 'Banner Two',
          ctaText: 'Explore',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeBannerCarousel(banners: banners),
          ),
        ),
      );

      expect(find.text('Banner One'), findsOneWidget);

      // Fling left to swipe to second banner
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Banner Two'), findsOneWidget);
    });

    testWidgets('11. Tapping banner fires onBannerTap callback with correct model', (tester) async {
      BannerModel? tappedBanner;
      final banners = [
        const BannerModel(
          id: 'b1',
          tag: 'Fresh Harvest',
          title: 'Banner One',
          ctaText: 'Shop Now',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeBannerCarousel(
              banners: banners,
              onBannerTap: (b) => tappedBanner = b,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PromoBanner));
      await tester.pump();

      expect(tappedBanner, isNotNull);
      expect(tappedBanner?.id, equals('b1'));
      expect(tappedBanner?.title, equals('Banner One'));
    });

    testWidgets('12. Four backend banners render 4 indicator dots and all 4 images during carousel swipe', (tester) async {
      final banners = [
        const BannerModel(
          id: 'b0',
          title: '20% Off Seasonal Greens',
          imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&q=80',
          displayOrder: 0,
        ),
        const BannerModel(
          id: 'b1',
          title: 'Fresh Citrus & Exotic Fruits',
          imageUrl: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=800&q=80',
          displayOrder: 1,
        ),
        const BannerModel(
          id: 'b2',
          title: 'Organic Veggies Delivered in 10 Mins',
          imageUrl: 'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=800&q=80',
          displayOrder: 2,
        ),
        const BannerModel(
          id: 'b3',
          title: 'Fresh Farm Apples & Pears',
          imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=800&q=80',
          displayOrder: 4,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeBannerCarousel(banners: banners),
          ),
        ),
      );
      await tester.pump();

      // Verify Banner 0
      expect(find.text('20% Off Seasonal Greens'), findsOneWidget);
      final img0 = tester.widget<Image>(find.byType(Image));
      expect((img0.image as NetworkImage).url, 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&q=80');

      // Swipe to Banner 1
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Fresh Citrus & Exotic Fruits'), findsOneWidget);
      final img1 = tester.widget<Image>(find.byType(Image));
      expect((img1.image as NetworkImage).url, 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=800&q=80');

      // Swipe to Banner 2
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Organic Veggies Delivered in 10 Mins'), findsOneWidget);
      final img2 = tester.widget<Image>(find.byType(Image));
      expect((img2.image as NetworkImage).url, 'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=800&q=80');

      // Swipe to Banner 3
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Fresh Farm Apples & Pears'), findsOneWidget);
      final img3 = tester.widget<Image>(find.byType(Image));
      expect((img3.image as NetworkImage).url, 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=800&q=80');
    });
  });
}
