import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({int limit = 50, int offset = 0});
  Future<int> getUnreadCount();
  Future<NotificationModel?> markAsRead(String id);
  Future<int> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<NotificationModel>> getNotifications({int limit = 50, int offset = 0}) async {
    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        return data
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
    return <NotificationModel>[];
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(ApiEndpoints.notificationUnreadCount);
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic> && data['unreadCount'] is num) {
        return (data['unreadCount'] as num).toInt();
      }
    }
    return 0;
  }

  @override
  Future<NotificationModel?> markAsRead(String id) async {
    final response = await _apiClient.patch(ApiEndpoints.notificationMarkRead(id));
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return NotificationModel.fromJson(data);
      }
    }
    return null;
  }

  @override
  Future<int> markAllAsRead() async {
    final response = await _apiClient.patch(ApiEndpoints.notificationReadAll);
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic> && data['count'] is num) {
        return (data['count'] as num).toInt();
      }
    }
    return 0;
  }
}
