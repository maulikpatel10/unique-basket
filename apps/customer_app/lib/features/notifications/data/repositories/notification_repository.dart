import '../datasources/notification_remote_data_source.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications({int limit = 50, int offset = 0});
  Future<int> getUnreadCount();
  Future<NotificationModel?> markAsRead(String id);
  Future<int> markAllAsRead();
}

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<NotificationModel>> getNotifications({int limit = 50, int offset = 0}) {
    return _remoteDataSource.getNotifications(limit: limit, offset: offset);
  }

  @override
  Future<int> getUnreadCount() {
    return _remoteDataSource.getUnreadCount();
  }

  @override
  Future<NotificationModel?> markAsRead(String id) {
    return _remoteDataSource.markAsRead(id);
  }

  @override
  Future<int> markAllAsRead() {
    return _remoteDataSource.markAllAsRead();
  }
}
