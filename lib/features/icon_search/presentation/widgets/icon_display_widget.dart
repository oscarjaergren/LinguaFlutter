import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget for displaying card icons (SVG or regular icons)
class IconDisplayWidget extends StatelessWidget {
  final String? iconPath;
  final double size;
  final Color? color;

  const IconDisplayWidget({
    super.key,
    this.iconPath,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (iconPath == null || iconPath!.isEmpty) {
      return Icon(
        Icons.help_outline,
        size: size,
        color: color ?? Theme.of(context).iconTheme.color,
      );
    }

    // Check if it's an SVG file
    if (iconPath!.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        iconPath!,
        width: size,
        height: size,
        colorFilter: color != null 
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        placeholderBuilder: (context) => Icon(
          Icons.image,
          size: size,
          color: color ?? Theme.of(context).iconTheme.color,
        ),
      );
    }

    // For other image types, use regular Image widget
    return Image.network(
      iconPath!,
      width: size,
      height: size,
      color: color,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.broken_image,
        size: size,
        color: color ?? Theme.of(context).iconTheme.color,
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }
}
