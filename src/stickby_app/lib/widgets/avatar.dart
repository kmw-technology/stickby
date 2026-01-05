import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

enum AvatarSize { small, medium, large }

class Avatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final AvatarSize size;

  const Avatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = AvatarSize.medium,
  });

  double get _size {
    switch (size) {
      case AvatarSize.small:
        return 32;
      case AvatarSize.medium:
        return 48;
      case AvatarSize.large:
        return 80;
    }
  }

  double get _fontSize {
    switch (size) {
      case AvatarSize.small:
        return 12;
      case AvatarSize.medium:
        return 18;
      case AvatarSize.large:
        return 28;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // Check if it is a local asset path
    if (imageUrl!.startsWith('assets/')) {
      return Image.asset(
        imageUrl!,
        fit: BoxFit.cover,
        width: _size,
        height: _size,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    // Otherwise use network image
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => _buildPlaceholder(),
      errorWidget: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        initials ?? '?',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
