import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedProductImage extends StatelessWidget {
  const CachedProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallback,
  });

  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final source = (imageUrl ?? '').trim();
    final placeholder = fallback ?? const Icon(Icons.checkroom_rounded);

    if (source.isEmpty) {
      return placeholder;
    }

    if (source.startsWith('data:image/')) {
      try {
        final encoded = source.split(',').last;
        return Image.memory(
          base64Decode(encoded),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => placeholder,
        );
      } catch (_) {
        return placeholder;
      }
    }

    return CachedNetworkImage(
      imageUrl: source,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (_, _) => Center(child: placeholder),
      errorWidget: (_, _, _) => placeholder,
    );
  }
}
