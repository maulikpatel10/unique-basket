import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/shared/widgets/widgets.dart';

Widget _wrapWidget(Widget child, {ThemeMode themeMode = ThemeMode.light}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: themeMode,
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared UI Components Tests', () {
    // 1. AppProductCard Tests
    group('AppProductCard', () {
      testWidgets('renders name, unit, price, and Add button correctly', (tester) async {
        await tester.pumpWidget(_wrapWidget(
          const AppProductCard(
            id: 'p1',
            name: 'Organic Hass Avocado',
            price: 4.99,
            unit: 'Pack of 2',
            badge: '16% OFF',
            quantity: 0,
            isFavorite: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Organic Hass Avocado'), findsOneWidget);
        expect(find.text('Pack of 2'), findsOneWidget);
        expect(find.text('\$4.99'), findsOneWidget);
        expect(find.text('16% OFF'), findsOneWidget);
        expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      });

      testWidgets('renders quantity and decrement button when quantity > 0', (tester) async {
        await tester.pumpWidget(_wrapWidget(
          const AppProductCard(
            id: 'p1',
            name: 'Organic Hass Avocado',
            price: 4.99,
            unit: 'Pack of 2',
            quantity: 3,
            isFavorite: true,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('3'), findsOneWidget);
        expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      });

      testWidgets('tapping Add button fires onAddToCart callback', (tester) async {
        bool addCalled = false;
        await tester.pumpWidget(_wrapWidget(
          AppProductCard(
            id: 'p1',
            name: 'Fresh Tomatoes',
            price: 2.99,
            unit: '500g',
            quantity: 0,
            onAddToCart: () => addCalled = true,
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();
        expect(addCalled, isTrue);
      });

      testWidgets('handles extremely long product name with ellipsis without overflow', (tester) async {
        await tester.pumpWidget(_wrapWidget(
          const SizedBox(
            width: 160,
            child: AppProductCard(
              id: 'p1',
              name: 'Super Extra Organic Hass Premium Selected Farm Avocado Fresh Pack of 10 Extra Long Name',
              price: 12.99,
              unit: '1kg Box Pack',
              quantity: 1,
            ),
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(AppProductCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('favorite heart button triggers onToggleFavorite without clicking card', (tester) async {
        bool favToggled = false;
        bool cardTapped = false;
        await tester.pumpWidget(_wrapWidget(
          AppProductCard(
            id: 'p1',
            name: 'Avocado',
            price: 4.99,
            unit: 'Pack of 2',
            isFavorite: false,
            onToggleFavorite: () => favToggled = true,
            onTap: () => cardTapped = true,
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.favorite_border_rounded));
        await tester.pumpAndSettle();

        expect(favToggled, isTrue);
        expect(cardTapped, isFalse);
      });
    });

    // 2. ProductQuantityControl Tests
    group('ProductQuantityControl', () {
      testWidgets('renders 32x32 circular add button when quantity == 0', (tester) async {
        await tester.pumpWidget(_wrapWidget(
          const ProductQuantityControl(quantity: 0),
        ));
        await tester.pumpAndSettle();

        final size = tester.getSize(find.byType(ProductQuantityControl));
        expect(size.width, 32.0);
        expect(size.height, 32.0);
        expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      });

      testWidgets('renders expanded 80x32 pill with decrement, quantity, and increment when quantity > 0', (tester) async {
        bool incrementCalled = false;
        bool decrementCalled = false;

        await tester.pumpWidget(_wrapWidget(
          ProductQuantityControl(
            quantity: 2,
            onIncrement: () => incrementCalled = true,
            onDecrement: () => decrementCalled = true,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('2'), findsOneWidget);
        expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
        expect(find.byIcon(Icons.add_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();
        expect(incrementCalled, isTrue);

        await tester.tap(find.byIcon(Icons.remove_rounded));
        await tester.pumpAndSettle();
        expect(decrementCalled, isTrue);
      });
    });

    // 3. CategoryItem Tests
    group('CategoryItem', () {
      testWidgets('renders category name and icon and responds to tap', (tester) async {
        bool categoryTapped = false;
        await tester.pumpWidget(_wrapWidget(
          CategoryItem(
            id: 'c1',
            name: 'Fruits',
            onTap: () => categoryTapped = true,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Fruits'), findsOneWidget);
        await tester.tap(find.text('Fruits'));
        await tester.pumpAndSettle();
        expect(categoryTapped, isTrue);
      });
    });

    // 4. AppSearchBar Tests
    group('AppSearchBar', () {
      testWidgets('renders placeholder and fires onTap when readOnly', (tester) async {
        bool searchTapped = false;
        bool micTapped = false;

        await tester.pumpWidget(_wrapWidget(
          AppSearchBar(
            hintText: 'Search for fresh fruits...',
            onTap: () => searchTapped = true,
            onTrailingTap: () => micTapped = true,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Search for fresh fruits...'), findsOneWidget);
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);
        expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

        await tester.tap(find.text('Search for fresh fruits...'));
        await tester.pumpAndSettle();
        expect(searchTapped, isTrue);

        await tester.tap(find.byKey(const Key('home_search_mic_button')));
        await tester.pumpAndSettle();
        expect(micTapped, isTrue);
      });

      testWidgets('accepts user input when readOnly is false', (tester) async {
        final controller = TextEditingController();
        String submittedText = '';

        await tester.pumpWidget(_wrapWidget(
          AppSearchBar(
            controller: controller,
            readOnly: false,
            onSubmitted: (val) => submittedText = val,
          ),
        ));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Fresh Apples');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(controller.text, 'Fresh Apples');
        expect(submittedText, 'Fresh Apples');
      });
    });

    // 5. CheckoutBar Tests
    group('CheckoutBar', () {
      testWidgets('returns SizedBox.shrink when itemCount is 0', (tester) async {
        await tester.pumpWidget(_wrapWidget(
          const CheckoutBar(
            itemCount: 0,
            totalPrice: 0.0,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Checkout'), findsNothing);
      });

      testWidgets('renders product count, total price, and fires onCheckoutTap when count > 0', (tester) async {
        bool checkoutTapped = false;
        await tester.pumpWidget(_wrapWidget(
          CheckoutBar(
            itemCount: 3,
            totalPrice: 14.97,
            onCheckoutTap: () => checkoutTapped = true,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('3 Products'), findsOneWidget);
        expect(find.text('\$14.97'), findsOneWidget);
        expect(find.text('Checkout'), findsOneWidget);

        await tester.tap(find.text('Checkout'));
        await tester.pumpAndSettle();
        expect(checkoutTapped, isTrue);
      });
    });

    // 6. AppBottomNavBar Tests
    group('AppBottomNavBar', () {
      testWidgets('renders 5 navigation tabs and triggers onTabSelected', (tester) async {
        int selectedTab = 0;
        await tester.pumpWidget(_wrapWidget(
          AppBottomNavBar(
            selectedIndex: selectedTab,
            onTabSelected: (index) => selectedTab = index,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Shop'), findsOneWidget);
        expect(find.text('Explore'), findsOneWidget);
        expect(find.text('Cart'), findsOneWidget);
        expect(find.text('Favorite'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);

        await tester.tap(find.text('Cart'));
        await tester.pumpAndSettle();
        expect(selectedTab, 2);
      });
    });

    // 7. SectionHeader Tests
    group('SectionHeader', () {
      testWidgets('renders section title and optional action text with callback', (tester) async {
        bool actionTapped = false;
        await tester.pumpWidget(_wrapWidget(
          SectionHeader(
            title: 'Explore Categories',
            actionText: 'View all',
            onActionTap: () => actionTapped = true,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Explore Categories'), findsOneWidget);
        expect(find.text('View all'), findsOneWidget);

        await tester.tap(find.text('View all'));
        await tester.pumpAndSettle();
        expect(actionTapped, isTrue);
      });
    });

    // 8. AppHeader Tests
    group('AppHeader', () {
      testWidgets('renders title, subtitle, and back button', (tester) async {
        bool backTapped = false;
        await tester.pumpWidget(_wrapWidget(
          AppHeader(
            title: 'Categories',
            subtitle: 'Select a category',
            showBackButton: true,
            onBackTap: () => backTapped = true,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Categories'), findsOneWidget);
        expect(find.text('Select a category'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(backTapped, isTrue);
      });
    });

    // 9. PromoBanner Tests
    group('PromoBanner', () {
      testWidgets('renders banner tag, title, ctaText, and fires onTap', (tester) async {
        bool bannerTapped = false;
        await tester.pumpWidget(_wrapWidget(
          PromoBanner(
            tag: 'Fresh Harvest',
            title: '20% Off\nSeasonal\nGreens',
            ctaText: 'Shop Now',
            onTap: () => bannerTapped = true,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Fresh Harvest'), findsOneWidget);
        expect(find.text('20% Off\nSeasonal\nGreens'), findsOneWidget);
        expect(find.text('Shop Now'), findsOneWidget);

        await tester.tap(find.text('Shop Now'));
        await tester.pumpAndSettle();
        expect(bannerTapped, isTrue);
      });

      testWidgets('renders Image.network when valid imageUrl is provided', (tester) async {
        await tester.pumpWidget(_wrapWidget(
          const PromoBanner(
            tag: 'Fresh Harvest',
            title: 'Fresh Citrus & Exotic Fruits',
            ctaText: 'Shop Now',
            imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999',
          ),
        ));
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        final imageWidget = tester.widget<Image>(find.byType(Image));
        expect((imageWidget.image as NetworkImage).url,
            'https://images.unsplash.com/photo-1540420773420-3366772f4999');
      });

      testWidgets('renders neutral fallback container when imageUrl is null or empty', (tester) async {
        await tester.pumpWidget(_wrapWidget(
          const PromoBanner(
            tag: 'Fresh Harvest',
            title: '20% Off Seasonal Greens',
            ctaText: 'Shop Now',
            imageUrl: null,
          ),
        ));
        await tester.pump();

        expect(find.byType(Image), findsNothing);
        expect(find.text('20% Off Seasonal Greens'), findsOneWidget);
        expect(find.text('Shop Now'), findsOneWidget);
      });
    });
  });
}
