import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:xillafit_flutter/core/config/app_links.dart';
import 'package:xillafit_flutter/core/network/backend_api_client.dart';
import 'package:xillafit_flutter/features/cart/data/cart_repository.dart';
import 'package:xillafit_flutter/features/checkout/data/checkout_repository.dart';

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.referenceNo,
    required this.orderStatus,
    required this.paymentStatus,
    required this.grandTotal,
    this.deliveryOption,
    this.deliveryFee,
    this.expectedCompletionDate,
    this.orderDate,
    this.createdAt,
  });

  final String id;
  final String referenceNo;
  final String orderStatus;
  final String paymentStatus;
  final double grandTotal;
  final String? deliveryOption;
  final double? deliveryFee;
  final DateTime? expectedCompletionDate;
  final DateTime? orderDate;
  final DateTime? createdAt;

  factory OrderSummary.fromMap(Map<String, dynamic> map) {
    return OrderSummary(
      id: map['id']?.toString() ?? '',
      referenceNo: map['order_reference_no']?.toString() ?? '',
      orderStatus: map['order_status']?.toString() ?? 'pending',
      paymentStatus: map['payment_type']?.toString() ??
          map['payment_status']?.toString() ??
          'pending',
      grandTotal: _asDouble(map['grand_total']),
      deliveryOption: map['delivery_option']?.toString(),
      deliveryFee: _asNullableDouble(map['delivery_fee']),
      expectedCompletionDate: _asDateTime(map['expected_completion_date']),
      orderDate: _asDateTime(map['order_date']),
      createdAt: _asDateTime(map['created_at']),
    );
  }
}

class OrderItemDetail {
  const OrderItemDetail({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.size,
    this.productName,
    this.previewImageUrl,
    this.categoryName,
  });

  final String id;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? size;
  final String? productName;
  final String? previewImageUrl;
  final String? categoryName;

  factory OrderItemDetail.fromMap(Map<String, dynamic> map) {
    final clothing = _asMap(map['clothing_items']);
    final category = _asMap(clothing?['clothing_categories']);
    return OrderItemDetail(
      id: map['id']?.toString() ?? '',
      quantity: _asInt(map['quantity']),
      unitPrice: _asDouble(map['unit_price']),
      subtotal: _asDouble(map['subtotal']),
      size: map['size']?.toString(),
      productName: clothing?['clothing_name']?.toString(),
      previewImageUrl: clothing?['preview_image_url']?.toString(),
      categoryName: category?['category_name']?.toString(),
    );
  }
}

class OrderTrackingEvent {
  const OrderTrackingEvent({
    required this.id,
    required this.status,
    this.remarks,
    this.createdAt,
    this.staffName,
  });

  final String id;
  final String status;
  final String? remarks;
  final DateTime? createdAt;
  final String? staffName;

  factory OrderTrackingEvent.fromMap(Map<String, dynamic> map) {
    final staffProfiles = _asMap(map['staff_profiles']);
    final profiles = _asMap(staffProfiles?['profiles']);
    return OrderTrackingEvent(
      id: map['id']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      remarks: map['remarks']?.toString(),
      createdAt: _asDateTime(map['created_at']),
      staffName: profiles?['full_name']?.toString(),
    );
  }
}

class OrderDetail {
  const OrderDetail({
    required this.summary,
    required this.items,
    required this.tracking,
  });

  final OrderSummary summary;
  final List<OrderItemDetail> items;
  final List<OrderTrackingEvent> tracking;

  factory OrderDetail.fromMap(Map<String, dynamic> map) {
    final items = (map['items'] as List? ?? const <dynamic>[])
        .map((row) => OrderItemDetail.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
    final tracking = (map['tracking'] as List? ?? const <dynamic>[])
        .map((row) => OrderTrackingEvent.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();

    return OrderDetail(
      summary: OrderSummary.fromMap(map),
      items: items,
      tracking: tracking,
    );
  }
}

class OrderRepository {
  OrderRepository({
    required BackendApiClient api,
  }) : _api = api;

  final BackendApiClient _api;

  Future<List<OrderSummary>> fetchMyOrders() async {
    final data = await _api.get('/orders/me/history');
    final rows = (data as List? ?? const <dynamic>[]);
    return rows
        .map((row) => OrderSummary.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<OrderDetail> fetchOrderDetail(String orderId) async {
    final data = await _api.get('/orders/me/$orderId');
    return OrderDetail.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<CheckoutSessionResult> createBalanceCheckoutSession(String orderId) async {
    final data = await _api.post(
      '/payments/balance/$orderId',
      body: {
        'successUrl': AppLinks.paymentBridgeUrl(
          success: true,
          flow: 'balance',
          orderId: orderId,
        ),
        'cancelUrl': AppLinks.paymentBridgeUrl(
          success: false,
          flow: 'balance',
          orderId: orderId,
        ),
      },
    );
    return CheckoutSessionResult.fromMap(Map<String, dynamic>.from(data as Map));
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(
    api: ref.watch(backendApiClientProvider),
  );
});

final orderHistoryProvider = FutureProvider<List<OrderSummary>>((ref) async {
  return ref.watch(orderRepositoryProvider).fetchMyOrders();
});

final orderDetailProvider = FutureProvider.family<OrderDetail, String>((ref, orderId) async {
  return ref.watch(orderRepositoryProvider).fetchOrderDetail(orderId);
});

String formatOrderMoney(double value) {
  return NumberFormat.currency(
    locale: 'en_PH',
    symbol: 'PHP ',
    decimalDigits: 0,
  ).format(value);
}

String formatOrderDate(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('MMM d, y').format(value);
}

String formatOrderDateTime(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('MMM d, y • h:mm a').format(value);
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
