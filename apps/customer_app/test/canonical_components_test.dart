import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/shared/widgets/widgets.dart';

void main() {
  group('Canonical AppButton Tests', () {
    testWidgets('Renders primary button and handles tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Click Me',
              variant: ButtonVariant.primary,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
      await tester.tap(find.text('Click Me'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('Renders secondary, outline, ghost, and danger variants', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppButton(
                  label: 'Secondary',
                  variant: ButtonVariant.secondary,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Outline',
                  variant: ButtonVariant.outline,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Ghost',
                  variant: ButtonVariant.ghost,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Danger',
                  variant: ButtonVariant.danger,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Secondary'), findsOneWidget);
      expect(find.text('Outline'), findsOneWidget);
      expect(find.text('Ghost'), findsOneWidget);
      expect(find.text('Danger'), findsOneWidget);
    });

    testWidgets('Renders loading state with progress indicator and suppresses callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Submit',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('Disabled button suppresses callback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Renders leading and trailing icons correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppButton(
                  label: 'Next',
                  icon: Icons.arrow_forward_rounded,
                  iconPosition: IconPosition.trailing,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Search',
                  icon: Icons.search_rounded,
                  iconPosition: IconPosition.leading,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });
  });

  group('Canonical AppIconButton Tests', () {
    testWidgets('Renders surface, ghost, and filled variants and triggers tap', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                AppIconButton(
                  icon: Icons.favorite_rounded,
                  variant: IconButtonVariant.surface,
                  onPressed: () => tapCount++,
                ),
                AppIconButton(
                  icon: Icons.close_rounded,
                  variant: IconButtonVariant.ghost,
                  onPressed: () => tapCount++,
                ),
                AppIconButton(
                  icon: Icons.check_rounded,
                  variant: IconButtonVariant.filled,
                  onPressed: () => tapCount++,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await tester.pump();
      expect(tapCount, 1);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(tapCount, 2);

      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump();
      expect(tapCount, 3);
    });

    testWidgets('Disabled AppIconButton does not trigger callback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIconButton(
              icon: Icons.lock_rounded,
              onPressed: null,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.lock_rounded));
      await tester.pump();
    });
  });

  group('Canonical AppChip Tests', () {
    testWidgets('Renders action chip and triggers onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppChip(
              label: 'Fresh Apples',
              variant: ChipVariant.action,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Fresh Apples'), findsOneWidget);
      await tester.tap(find.text('Fresh Apples'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('Renders input chip with icon and triggers onDeleted', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppChip(
              label: 'Bananas',
              variant: ChipVariant.input,
              icon: Icons.history_rounded,
              onDeleted: () => deleted = true,
            ),
          ),
        ),
      );

      expect(find.text('Bananas'), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('Renders filter chip with selected/unselected state', (tester) async {
      bool selected = false;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: AppChip(
                  label: 'Vegetables',
                  variant: ChipVariant.filter,
                  isSelected: selected,
                  onTap: () => setState(() => selected = !selected),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Vegetables'), findsOneWidget);
      await tester.tap(find.text('Vegetables'));
      await tester.pumpAndSettle();
      expect(selected, isTrue);
    });
  });

  group('Canonical AppBadge Tests', () {
    testWidgets('Renders discount, stock, status, and tag badge variants', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppBadge(
                  text: '16% OFF',
                  variant: BadgeVariant.discount,
                ),
                AppBadge(
                  text: 'OUT OF STOCK',
                  variant: BadgeVariant.stock,
                ),
                AppBadge(
                  text: 'DELIVERED',
                  variant: BadgeVariant.status,
                ),
                AppBadge(
                  text: 'Local',
                  variant: BadgeVariant.tag,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('16% OFF'), findsOneWidget);
      expect(find.text('OUT OF STOCK'), findsOneWidget);
      expect(find.text('DELIVERED'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
    });
  });
}
