enum NotificationType {
  orderStatus,
  deliveryDispatch,
  promotion,
  accountActivity,
  welcome,
  general;

  static NotificationType fromString(String? type) {
    switch (type?.toUpperCase()) {
      case 'ORDER_STATUS':
        return NotificationType.orderStatus;
      case 'DELIVERY_DISPATCH':
        return NotificationType.deliveryDispatch;
      case 'PROMOTION':
        return NotificationType.promotion;
      case 'ACCOUNT_ACTIVITY':
        return NotificationType.accountActivity;
      case 'WELCOME':
        return NotificationType.welcome;
      default:
        return NotificationType.general;
    }
  }

  String toDbString() {
    switch (this) {
      case NotificationType.orderStatus:
        return 'ORDER_STATUS';
      case NotificationType.deliveryDispatch:
        return 'DELIVERY_DISPATCH';
      case NotificationType.promotion:
        return 'PROMOTION';
      case NotificationType.accountActivity:
        return 'ACCOUNT_ACTIVITY';
      case NotificationType.welcome:
        return 'WELCOME';
      case NotificationType.general:
        return 'GENERAL';
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? orderId;
  final String? orderNumber;
  final String? tag;
  final String? actionText;
  final String? promoCode;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    this.orderNumber,
    this.tag,
    this.actionText,
    this.promoCode,
    this.isRead = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String?),
      orderId: json['orderId'] as String?,
      orderNumber: json['orderNumber'] as String?,
      tag: json['tag'] as String?,
      actionText: json['actionText'] as String?,
      promoCode: json['promoCode'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.toDbString(),
      'orderId': orderId,
      'orderNumber': orderNumber,
      'tag': tag,
      'actionText': actionText,
      'promoCode': promoCode,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? orderId,
    String? orderNumber,
    String? tag,
    String? actionText,
    String? promoCode,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      tag: tag ?? this.tag,
      actionText: actionText ?? this.actionText,
      promoCode: promoCode ?? this.promoCode,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
