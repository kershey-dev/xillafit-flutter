import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:xillafit_flutter/core/network/backend_api_client.dart';
import 'package:xillafit_flutter/features/cart/data/cart_repository.dart';

class DeliveryZone {
  const DeliveryZone({
    required this.id,
    required this.zoneName,
    required this.province,
    required this.baseFee,
  });

  final String id;
  final String zoneName;
  final String province;
  final double baseFee;

  factory DeliveryZone.fromMap(Map<String, dynamic> map) {
    final rawFee = map['base_fee'];
    return DeliveryZone(
      id: map['id']?.toString() ?? '',
      zoneName: map['zone_name']?.toString() ?? '',
      province: map['province']?.toString() ?? '',
      baseFee: rawFee is num ? rawFee.toDouble() : double.tryParse('$rawFee') ?? 0,
    );
  }
}

class CheckoutLineItem {
  const CheckoutLineItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
    this.category,
    this.size,
  });

  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? image;
  final String? category;
  final String? size;

  double get subtotal => price * quantity;

  Map<String, dynamic> toApiMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'quantity': quantity,
      'category': category,
      if ((size ?? '').trim().isNotEmpty) 'size': size,
    };
  }

  factory CheckoutLineItem.fromCartLine(CartLineItem line) {
    return CheckoutLineItem(
      id: line.item.id,
      name: line.item.name,
      price: line.item.basePrice ?? 0,
      quantity: line.quantity,
      image: line.item.previewImageUrl,
      category: line.item.description,
    );
  }
}

class CheckoutSessionResult {
  const CheckoutSessionResult({
    required this.checkoutUrl,
    this.sessionId,
  });

  final String checkoutUrl;
  final String? sessionId;

  factory CheckoutSessionResult.fromMap(Map<String, dynamic> map) {
    return CheckoutSessionResult(
      checkoutUrl: map['checkout_url']?.toString() ?? '',
      sessionId: map['session_id']?.toString(),
    );
  }
}

class CheckoutRepository {
  CheckoutRepository({required BackendApiClient api}) : _api = api;

  final BackendApiClient _api;

  Future<List<DeliveryZone>> fetchDeliveryZones() async {
    final data = await _api.get('/delivery/zones');
    final rows = (data as List? ?? const <dynamic>[]);
    return rows
        .map((row) => DeliveryZone.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<String?> fetchEstimatedCompletionDate() async {
    final data = await _api.get('/orders/estimate-completion');
    if (data is! Map<String, dynamic>) return null;
    final raw = data['estimate']?.toString();
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMMM d, y').format(parsed);
  }

  Future<CheckoutSessionResult> createCheckoutSession({
    required double amountDueNow,
    required bool isDeposit,
    required String referenceId,
    required List<CheckoutLineItem> items,
    required String profileId,
    required String successUrl,
    required String cancelUrl,
    required String deliveryOption,
    required String deliveryAddress,
    required double deliveryFee,
    required String billingName,
    required String billingEmail,
    String? billingPhone,
    required String city,
    required String postalCode,
    required String streetAddress,
  }) async {
    final data = await _api.post(
      '/payments/checkout',
      body: {
        'amount': amountDueNow,
        'description': isDeposit
            ? '50% Deposit for Order #$referenceId'
            : 'Full Payment for Order #$referenceId',
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
        'referenceId': referenceId,
        'checkoutItems': items.map((item) => item.toApiMap()).toList(),
        'profileId': profileId,
        'billing': {
          'name': billingName,
          'email': billingEmail,
          if ((billingPhone ?? '').trim().isNotEmpty) 'phone': billingPhone,
          'address': {
            'line1': streetAddress,
            'city': city,
            'state': 'Bulacan',
            'postal_code': postalCode,
            'country': 'PH',
          },
        },
        'deliveryInfo': {
          'address': deliveryAddress,
          'deliveryFee': deliveryFee,
          'method': deliveryOption,
        },
        'isDeposit': isDeposit,
      },
    );

    return CheckoutSessionResult.fromMap(Map<String, dynamic>.from(data as Map));
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(api: ref.watch(backendApiClientProvider));
});
