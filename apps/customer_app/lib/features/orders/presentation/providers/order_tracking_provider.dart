import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../checkout/presentation/providers/order_provider.dart';

/// Provider that fetches live order tracking details for a specific order ID.
final orderTrackingProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, orderId) async {
  if (orderId.trim().isEmpty) {
    throw Exception('INVALID_ORDER_ID');
  }
  final repository = ref.watch(orderRepositoryProvider);
  final response = await repository.getOrderById(orderId);
  final dynamic rawData =
      response['order'] ?? (response.containsKey('data') ? response['data'] : response);
  final data = rawData is Map<String, dynamic> ? rawData : null;
  if (data == null || response['success'] == false) {
    throw Exception('ORDER_NOT_FOUND');
  }
  return data;
});

/// Stage progression state for timeline node rendering.
enum TimelineNodeState {
  completed,
  current,
  pending,
}

/// Centralized helper for mapping backend OrderStatus into UI presentation.
class OrderTrackingStatusHelper {
  final String status;
  final List<dynamic> items;

  OrderTrackingStatusHelper({
    required String? rawStatus,
    List<dynamic>? itemsList,
  })  : status = (rawStatus ?? 'PLACED').toUpperCase(),
        items = itemsList ?? const [];

  bool get isCancelled => status == 'CANCELLED';
  bool get isDelivered => status == 'DELIVERED';
  bool get isLiveOrder => !isCancelled && !isDelivered;

  /// Returns the step index (1 to 5) that is currently active.
  int get activeStepIndex {
    switch (status) {
      case 'PLACED':
        return 1;
      case 'CONFIRMED':
        return 2;
      case 'PREPARING':
        return 2;
      case 'READY_FOR_PICKUP':
        return 3;
      case 'PICKED_UP':
      case 'OUT_FOR_DELIVERY':
        return 4;
      case 'DELIVERED':
        return 5;
      case 'CANCELLED':
        return 0;
      default:
        return 1;
    }
  }

  /// Evaluates the state of a given stage (1 to 5).
  TimelineNodeState getNodeState(int stageNumber) {
    if (isCancelled) return TimelineNodeState.pending;
    if (isDelivered) return TimelineNodeState.completed;

    if (stageNumber < activeStepIndex) {
      return TimelineNodeState.completed;
    } else if (stageNumber == activeStepIndex) {
      return TimelineNodeState.current;
    } else {
      return TimelineNodeState.pending;
    }
  }

  /// Header pill / badge label in hero banner
  String get currentStepLabel {
    switch (status) {
      case 'PLACED':
        return 'CURRENT STEP: VERIFYING';
      case 'CONFIRMED':
        return 'CURRENT STEP: CONFIRMED';
      case 'PREPARING':
        return 'CURRENT STEP: PACKING';
      case 'READY_FOR_PICKUP':
        return 'CURRENT STEP: PICKUP';
      case 'PICKED_UP':
      case 'OUT_FOR_DELIVERY':
        return 'CURRENT STEP: ON THE WAY';
      case 'DELIVERED':
        return 'DELIVERY COMPLETE';
      case 'CANCELLED':
        return 'ORDER CANCELLED';
      default:
        return 'CURRENT STEP: PROCESSING';
    }
  }

  /// Primary headline in hero banner
  String get heroTitle {
    switch (status) {
      case 'PLACED':
        return 'Order Placed Successfully';
      case 'CONFIRMED':
        return 'Order Confirmed & Verified';
      case 'PREPARING':
        return 'Your Order is Being Prepared';
      case 'READY_FOR_PICKUP':
        return 'Order is Ready for Pickup';
      case 'PICKED_UP':
      case 'OUT_FOR_DELIVERY':
        return 'Your Order is Out for Delivery';
      case 'DELIVERED':
        return 'Order Delivered Successfully';
      case 'CANCELLED':
        return 'This Order Has Been Cancelled';
      default:
        return 'Processing Your Order';
    }
  }

  /// Subtitle description in hero banner
  String get heroSubtitle {
    switch (status) {
      case 'PLACED':
        return 'We have received your order and are forwarding it to the store.';
      case 'CONFIRMED':
        return 'Your order is confirmed. Store team is preparing to pick your items.';
      case 'PREPARING':
        return 'Fresh groceries are being carefully picked and packed at the store.';
      case 'READY_FOR_PICKUP':
        return 'Your groceries are packed in eco-friendly bags and ready for the rider.';
      case 'PICKED_UP':
      case 'OUT_FOR_DELIVERY':
        return 'Our delivery partner is on the way to your delivery address.';
      case 'DELIVERED':
        return 'Your fresh groceries have been delivered to your doorstep.';
      case 'CANCELLED':
        return 'This order was cancelled. Any processed payment will be refunded.';
      default:
        return 'Your order is being processed by Unique Basket.';
    }
  }

  /// Dynamic description of packing items for Stage 2
  String get dynamicPackingDescription {
    if (items.isEmpty) {
      return 'Store is packing your fresh items';
    }
    final itemNames = items
        .map((i) => i is Map<String, dynamic>
            ? (i['productName'] ?? i['name'] ?? i['product']?['name'] ?? '')
            : '')
        .where((n) => n.toString().isNotEmpty)
        .take(3)
        .toList();

    if (itemNames.isEmpty) {
      return 'Store is packing your fresh items';
    }
    if (itemNames.length == 1) {
      return 'Store is packing your fresh ${itemNames.first}';
    }
    final leading = itemNames.sublist(0, itemNames.length - 1).join(', ');
    return 'Store is packing your fresh $leading & ${itemNames.last}';
  }

  /// Estimated arrival tag
  String get estimatedArrivalText {
    if (isDelivered) return 'DELIVERED';
    if (isCancelled) return 'CANCELLED';
    return 'ESTIMATED ARRIVAL TODAY • 8–15 MIN';
  }
}
