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
    this.fabric,
    this.customDesignId,
    this.customName,
    this.customNumber,
  });

  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? image;
  final String? category;
  final String? size;
  final String? fabric;
  final String? customDesignId;
  final String? customName;
  final String? customNumber;

  double get subtotal => price * quantity;

  Map<String, dynamic> toApiMap() {
    return {
      if (id.trim().isNotEmpty) 'id': id,
      'name': name,
      'price': price,
      'image': image,
      'quantity': quantity,
      'category': category,
      if ((size ?? '').trim().isNotEmpty) 'size': size,
      if ((fabric ?? '').trim().isNotEmpty) 'fabric': fabric,
      if ((customDesignId ?? '').trim().isNotEmpty) 'customDesignId': customDesignId,
      if ((customName ?? '').trim().isNotEmpty) 'customName': customName,
      if ((customNumber ?? '').trim().isNotEmpty) 'customNumber': customNumber,
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
      size: line.size,
      fabric: line.fabric,
      customName: line.customName,
      customNumber: line.customNumber,
    );
  }
}

class CustomDesignDraft {
  const CustomDesignDraft({
    required this.designId,
    required this.name,
    required this.garmentType,
    this.color,
    this.logoUrl,
    this.textureUrl,
    this.previewImage,
    this.backPreviewImage,
    this.sizeLabel,
    this.productId,
    this.isLogoTexture = false,
    this.isFullTexture = false,
    this.layers = const <Map<String, dynamic>>[],
    this.shirtDetails = const <String, dynamic>{},
  });

  final String designId;
  final String name;
  final String garmentType;
  final String? color;
  final String? logoUrl;
  final String? textureUrl;
  final String? previewImage;
  final String? backPreviewImage;
  final String? sizeLabel;
  final String? productId;
  final bool isLogoTexture;
  final bool isFullTexture;
  final List<Map<String, dynamic>> layers;
  final Map<String, dynamic> shirtDetails;

  factory CustomDesignDraft.fromCustomizerResult(Map<String, dynamic> map) {
    final rawLayers = map['layers'];
    return CustomDesignDraft(
      designId: map['designId']?.toString() ?? map['design']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Custom Design',
      garmentType: map['garmentType']?.toString() ?? 'shirt',
      color: map['color']?.toString(),
      logoUrl: map['logoUrl']?.toString(),
      textureUrl: map['textureUrl']?.toString(),
      previewImage: map['previewImage']?.toString(),
      backPreviewImage: map['backPreviewImage']?.toString(),
      sizeLabel: map['sizeLabel']?.toString(),
      productId: map['productId']?.toString(),
      isLogoTexture: map['isLogoTexture'] == true || map['isLogoTexture']?.toString() == 'true',
      isFullTexture: map['isFullTexture'] == true || map['isFullTexture']?.toString() == 'true',
      layers: rawLayers is List
          ? rawLayers
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList()
          : const <Map<String, dynamic>>[],
      shirtDetails: map['shirtDetails'] is Map
          ? Map<String, dynamic>.from(map['shirtDetails'] as Map)
          : const <String, dynamic>{},
    );
  }

  Map<String, dynamic> toApiDesignData() {
    return {
      'id': designId,
      'name': name,
      'description': 'Saved from mobile customizer',
      if ((productId ?? '').trim().isNotEmpty) 'productId': productId,
      if ((color ?? '').trim().isNotEmpty) 'color': color,
      if ((previewImage ?? '').trim().isNotEmpty) 'previewImage': previewImage,
      if ((backPreviewImage ?? '').trim().isNotEmpty)
        'backPreviewImage': backPreviewImage,
      if ((textureUrl ?? '').trim().isNotEmpty) 'textureUrl': textureUrl,
      'isLogoTexture': isLogoTexture,
      'isFullTexture': isFullTexture,
      'shirtDetails': shirtDetails,
      'layers': layers,
      if ((logoUrl ?? '').trim().isNotEmpty) 'logoUrl': logoUrl,
      'garmentType': garmentType,
    };
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

  Future<CheckoutSessionResult> createCustomCheckoutSession({
    required CustomDesignDraft design,
    required String profileId,
    required Map<String, int> quantities,
    required String fabric,
    required String referenceId,
    required double grandTotal,
    required double amountDueNow,
    required String successUrl,
    required String cancelUrl,
    required String orderType,
    required String address,
    required String billingName,
    required String billingEmail,
    String? billingPhone,
    required String city,
    required String postalCode,
    required String streetAddress,
    String? zoneId,
    String? instructions,
  }) async {
    final data = await _api.post(
      '/payments/checkout-custom',
      body: {
        'amount': amountDueNow,
        'description': '50% Deposit for Custom Design #$referenceId',
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
        'referenceId': referenceId,
        'profileId': profileId,
        'designData': design.toApiDesignData(),
        'quantities': quantities,
        'orderForm': {
          'address': address,
          'orderType': orderType,
          if ((zoneId ?? '').trim().isNotEmpty) 'zoneId': zoneId,
          if ((instructions ?? '').trim().isNotEmpty)
            'instructions': instructions!.trim(),
        },
        'grandTotal': grandTotal,
        'fabric': fabric,
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
      },
    );

    return CheckoutSessionResult.fromMap(Map<String, dynamic>.from(data as Map));
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(api: ref.watch(backendApiClientProvider));
});
