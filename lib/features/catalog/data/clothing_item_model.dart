class ClothingItemModel {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final String? previewImageUrl;
  final String? modelFileUrl;
  final String? availabilityStatus;
  final DateTime? createdAt;

  /// Not present in current schema; nullable for forward compatibility.
  final double? basePrice;

  const ClothingItemModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    this.previewImageUrl,
    this.modelFileUrl,
    this.availabilityStatus,
    this.createdAt,
    this.basePrice,
  });

  bool get isAvailable => (availabilityStatus ?? 'available') == 'available';

  String get priceLabel {
    if (basePrice != null) {
      final value = basePrice!;
      final formatted = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
      return '₱$formatted';
    }
    return 'Price on request';
  }

  factory ClothingItemModel.fromMap(Map<String, dynamic> map) {
    double? price;
    final rawPrice = map['base_price'] ?? map['price'];
    if (rawPrice is num) price = rawPrice.toDouble();
    if (rawPrice is String) price = double.tryParse(rawPrice);

    return ClothingItemModel(
      id: map['id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      name: map['clothing_name']?.toString() ?? '',
      description: map['description']?.toString(),
      previewImageUrl: map['preview_image_url']?.toString(),
      modelFileUrl: map['model_file_url']?.toString(),
      availabilityStatus: map['availability_status']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      basePrice: price,
    );
  }
}

