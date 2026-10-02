import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRemoteDataSourceImpl(apiClient);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final remoteDataSource = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(remoteDataSource);
});

class NotificationState {
  final bool isLoading;
  final bool isRefreshing;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? errorMessage;

  const NotificationState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  bool get isEmpty => !isLoading && errorMessage == null && notifications.isEmpty;

  NotificationState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;

  NotificationNotifier(this._repository) : super(const NotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await _repository.getNotifications();
      if (!mounted) return;
      final unread = results.where((n) => !n.isRead).length;
      state = state.copyWith(
        isLoading: false,
        notifications: results,
        unreadCount: unread,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load notifications. Please try again.',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final results = await _repository.getNotifications();
      if (!mounted) return;
      final unread = results.where((n) => !n.isRead).length;
      state = state.copyWith(
        isRefreshing: false,
        notifications: results,
        unreadCount: unread,
        clearError: true,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isRefreshing: false);
    }
  }

  Future<void> markAsRead(String id) async {
    final itemIndex = state.notifications.indexWhere((n) => n.id == id);
    if (itemIndex == -1 || state.notifications[itemIndex].isRead) {
      return;
    }

    // Optimistic local update
    final updatedList = List<NotificationModel>.from(state.notifications);
    updatedList[itemIndex] = updatedList[itemIndex].copyWith(isRead: true);
    final newUnread = (state.unreadCount - 1).clamp(0, 99999);

    state = state.copyWith(
      notifications: updatedList,
      unreadCount: newUnread,
    );

    try {
      await _repository.markAsRead(id);
    } catch (_) {
      // Background sync failure ignored; state remains resilient
    }
  }

  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0) return;

    // Optimistic local update
    final updatedList = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(
      notifications: updatedList,
      unreadCount: 0,
    );

    try {
      await _repository.markAllAsRead();
    } catch (_) {
      // Background sync failure ignored
    }
  }

  /// Resets notification state on logout or account switch.
  void reset() {
    state = const NotificationState();
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationNotifierProvider);
  return state.unreadCount;
});
