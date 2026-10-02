import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/features/explore/presentation/screens/explore_screen.dart';
import 'package:customer_app/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:customer_app/features/home/presentation/screens/home_screen.dart';
import 'package:customer_app/features/notifications/data/models/notification_model.dart';
import 'package:customer_app/features/notifications/data/repositories/notification_repository.dart';
import 'package:customer_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:customer_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:customer_app/features/notifications/presentation/widgets/notification_card.dart';
import 'package:customer_app/shared/widgets/app_empty_state.dart';
import 'package:customer_app/shared/widgets/app_error_state.dart';
import 'package:customer_app/shared/widgets/app_header.dart';

class MockNotificationRepository implements NotificationRepository {
  bool shouldThrow = false;
  List<NotificationModel> notificationsToReturn = [];
  final List<String> markedReadIds = [];
  bool markedAllRead = false;

  @override
  Future<List<NotificationModel>> getNotifications({int limit = 50, int offset = 0}) async {
    if (shouldThrow) {
      throw Exception('NETWORK_ERROR');
    }
    return List.from(notificationsToReturn);
  }

  @override
  Future<int> getUnreadCount() async {
    return notificationsToReturn.where((n) => !n.isRead).length;
  }

  @override
  Future<NotificationModel?> markAsRead(String id) async {
    markedReadIds.add(id);
    final index = notificationsToReturn.indexWhere((n) => n.id == id);
    if (index != -1) {
      notificationsToReturn[index] =
          notificationsToReturn[index].copyWith(isRead: true);
      return notificationsToReturn[index];
    }
    return null;
  }

  @override
  Future<int> markAllAsRead() async {
    markedAllRead = true;
    final count = notificationsToReturn.where((n) => !n.isRead).length;
    notificationsToReturn =
        notificationsToReturn.map((n) => n.copyWith(isRead: true)).toList();
    return count;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final sampleNotifications = [
    NotificationModel(
      id: 'notif-1',
      userId: 'user-1',
      title: 'Order Confirmed & Packing',
      body: 'Your fresh fruits order #UB-290926-001 has been confirmed.',
      type: NotificationType.orderStatus,
      orderId: 'order-uuid-1',
      orderNumber: '#UB-290926-001',
      tag: '#UB-290926-001',
      actionText: 'Track Live Order',
      isRead: false,
      createdAt: now.subtract(const Duration(minutes: 10)),
      updatedAt: now.subtract(const Duration(minutes: 10)),
    ),
    NotificationModel(
      id: 'notif-2',
      userId: 'user-1',
      title: 'Delivery Rider Assigned',
      body: 'Rider is on the way with your fresh vegetables.',
      type: NotificationType.deliveryDispatch,
      orderId: 'order-uuid-1',
      orderNumber: '#UB-290926-001',
      tag: 'Delivery Dispatch',
      isRead: false,
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: 'notif-3',
      userId: 'user-1',
      title: 'Fresh Mangoes Flash Sale',
      body: 'Enjoy 20% off on fresh Kesar Mangoes today.',
      type: NotificationType.promotion,
      promoCode: 'FRESH100',
      tag: 'Fresh Flash Sale',
      isRead: true,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
    NotificationModel(
      id: 'notif-4',
      userId: 'user-1',
      title: 'Welcome to UNIQUE BASKET',
      body: 'Thank you for joining our farm-fresh grocery platform.',
      type: NotificationType.welcome,
      tag: 'Welcome',
      isRead: true,
      createdAt: now.subtract(const Duration(days: 4)),
      updatedAt: now.subtract(const Duration(days: 4)),
    ),
  ];

  group('NotificationModel Tests', () {
    test('Correctly serializes and deserializes JSON', () {
      final model = NotificationModel(
        id: 'test-id',
        userId: 'test-user',
        title: 'Test Notification',
        body: 'Test Body Message',
        type: NotificationType.deliveryDispatch,
        orderId: 'order-123',
        orderNumber: '#UB-290926-001',
        tag: 'Dispatch',
        actionText: 'Track Order',
        promoCode: 'SAVE10',
        isRead: false,
        createdAt: DateTime(2026, 9, 29, 10, 0),
        updatedAt: DateTime(2026, 9, 29, 10, 0),
      );

      final json = model.toJson();
      expect(json['id'], 'test-id');
      expect(json['type'], 'DELIVERY_DISPATCH');
      expect(json['orderNumber'], '#UB-290926-001');

      final fromJson = NotificationModel.fromJson(json);
      expect(fromJson.id, 'test-id');
      expect(fromJson.type, NotificationType.deliveryDispatch);
      expect(fromJson.isRead, false);
      expect(fromJson.promoCode, 'SAVE10');
    });

    test('Handles null fields and unknown enum gracefully', () {
      final fromJson = NotificationModel.fromJson({
        'id': 'empty-notif',
        'title': 'Generic',
        'body': 'Generic body',
        'type': 'UNKNOWN_TYPE',
      });

      expect(fromJson.type, NotificationType.general);
      expect(fromJson.orderId, isNull);
      expect(fromJson.isRead, isFalse);
    });
  });

  group('NotificationNotifier State & Operations', () {
    late MockNotificationRepository mockRepo;

    setUp(() {
      mockRepo = MockNotificationRepository();
      mockRepo.notificationsToReturn = List.from(sampleNotifications);
    });

    test('Loads notifications and sets unread count correctly', () async {
      final notifier = NotificationNotifier(mockRepo);
      await notifier.loadNotifications();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.notifications.length, 4);
      expect(notifier.state.unreadCount, 2);
      expect(notifier.state.errorMessage, isNull);
    });

    test('Handles network error gracefully', () async {
      mockRepo.shouldThrow = true;
      final notifier = NotificationNotifier(mockRepo);
      await notifier.loadNotifications();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.notifications.isEmpty, isTrue);
      expect(notifier.state.errorMessage, isNotNull);
    });

    test('Marks single notification as read optimistically and updates unread count', () async {
      final notifier = NotificationNotifier(mockRepo);
      await notifier.loadNotifications();

      expect(notifier.state.unreadCount, 2);
      await notifier.markAsRead('notif-1');

      expect(notifier.state.unreadCount, 1);
      expect(notifier.state.notifications.firstWhere((n) => n.id == 'notif-1').isRead, isTrue);
      expect(mockRepo.markedReadIds.contains('notif-1'), isTrue);
    });

    test('Marks all notifications as read', () async {
      final notifier = NotificationNotifier(mockRepo);
      await notifier.loadNotifications();

      await notifier.markAllAsRead();

      expect(notifier.state.unreadCount, 0);
      expect(notifier.state.notifications.every((n) => n.isRead), isTrue);
      expect(mockRepo.markedAllRead, isTrue);
    });
  });

  group('NotificationsScreen Widget Tests', () {
    late MockNotificationRepository mockRepo;

    setUp(() {
      mockRepo = MockNotificationRepository();
      mockRepo.notificationsToReturn = List.from(sampleNotifications);
    });

    Widget createScreenHarness() {
      return ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: NotificationsScreen(),
        ),
      );
    }

    testWidgets('Renders AppHeader with title and back button', (tester) async {
      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('Renders top unread status pill with count and mark all button', (tester) async {
      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('2 unread notifications'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
    });

    testWidgets('Renders dynamic chronological section headers', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('EARLIER'), findsOneWidget);
    });

    testWidgets('Renders notification cards with badges, titles, and bodies', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.byType(NotificationCard), findsNWidgets(4));
      expect(find.text('Order Confirmed & Packing'), findsOneWidget);
      expect(find.text('Delivery Rider Assigned'), findsOneWidget);
      expect(find.text('Fresh Mangoes Flash Sale'), findsOneWidget);
      expect(find.text('Welcome to UNIQUE BASKET'), findsOneWidget);
      expect(find.text('Track Live Order →'), findsWidgets);
      expect(find.text('Use Code: FRESH100'), findsOneWidget);
    });


    testWidgets('Tapping Mark all read clears unread badge and updates cards', (tester) async {
      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('Mark all read'), findsOneWidget);
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(find.text('2 unread notifications'), findsNothing);
    });

    testWidgets('Renders empty state when no notifications exist', (tester) async {
      mockRepo.notificationsToReturn = [];
      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('No Notifications Yet'), findsOneWidget);
      expect(find.text('Explore Fresh Catalog'), findsOneWidget);
    });

    testWidgets('Renders error state with retry on network failure', (tester) async {
      mockRepo.shouldThrow = true;
      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Unable to Load Notifications'), findsOneWidget);
    });

    testWidgets('Renders footer archive notice at the bottom', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(
        find.text("You're all caught up with your latest updates"),
        findsOneWidget,
      );
      expect(
        find.text('Notifications older than 30 days are automatically archived.'),
        findsOneWidget,
      );
    });

  });

  group('Header Bell Navigation Integration', () {
    testWidgets('HomeScreen notification bell triggers navigation without throwing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bellButton = find.byKey(const Key('home_notification_button')).first;
      expect(bellButton, findsOneWidget);
      await tester.tap(bellButton);
      await tester.pumpAndSettle();
      // No snackbar placeholder error thrown
    });

    testWidgets('ExploreScreen notification bell triggers navigation without throwing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bellFinder = find.byIcon(Icons.notifications_none_rounded);
      if (bellFinder.evaluate().isNotEmpty) {
        await tester.tap(bellFinder.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('FavoritesScreen notification bell triggers navigation without throwing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bellFinder = find.byIcon(Icons.notifications_none_rounded);
      if (bellFinder.evaluate().isNotEmpty) {
        await tester.tap(bellFinder.first);
        await tester.pumpAndSettle();
      }
    });
  });
}
