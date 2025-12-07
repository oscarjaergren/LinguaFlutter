import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_flutter/shared/domain/models/icon_model.dart';

/// Widget to display Iconify icons with proper styling and error handling
class IconifyIcon extends StatelessWidget {
  final IconModel icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  const IconifyIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).iconTheme.color;
    
    return SizedBox(
      width: size,
      height: size,
      child: _buildIcon(context, iconColor),
    );
  }

  Widget _buildIcon(BuildContext context, Color? iconColor) {
    // Since IconModel only has svgUrl, we'll use that for all icons
    return _buildIconifyIcon(context, iconColor);
  }

  Widget _buildIconifyIcon(BuildContext context, Color? iconColor) {
    // Use the svgUrl from IconModel to load the SVG from network
    return SvgPicture.network(
      icon.svgUrl,
      width: size,
      height: size,
      colorFilter: iconColor != null 
          ? ColorFilter.mode(iconColor, BlendMode.srcIn)
          : null,
      semanticsLabel: semanticLabel ?? icon.name,
      placeholderBuilder: (context) => _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        size: size * 0.6,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

}
