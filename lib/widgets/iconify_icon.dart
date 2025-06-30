import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/icon_model.dart';

/// A widget that displays an icon from the Iconify API
class IconifyIcon extends StatelessWidget {
  final IconModel icon;
  final double size;
  final Color? color;
  final VoidCallback? onTap;
  final bool isSelected;
  
  const IconifyIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.color,
    this.onTap,
    this.isSelected = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.onSurface;
    
    return GestureDetector(
      onTap: onTap,
      child: SvgPicture.network(
        icon.svgUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: color != null 
            ? ColorFilter.mode(
                iconColor,
                BlendMode.srcIn,
              ) 
            : null, // Let icons keep their original colors
        placeholderBuilder: (context) => SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: iconColor.withValues(alpha: 0.5),
          ),
        ),
        // Add error handling for failed SVG loads
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.broken_image_outlined,
            size: size * 0.6,
            color: iconColor.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// A grid item widget for displaying an icon with its metadata
class IconGridItem extends StatelessWidget {
  final IconModel icon;
  final VoidCallback? onTap;
  final bool isSelected;
  
  const IconGridItem({
    super.key,
    required this.icon,
    this.onTap,
    this.isSelected = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Tooltip(
      message: '${icon.name} (${icon.set})',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Semantics(
          label: 'Icon: ${icon.name} from ${icon.set} collection',
          button: true,
          enabled: onTap != null,
          selected: isSelected,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: isSelected 
                  ? Border.all(
                      color: theme.colorScheme.primary, 
                      width: 2,
                    ) 
                  : null,
            ),
            child: Center(
              child: IconifyIcon(
                icon: icon,
                size: 48, // Even larger to fill most of the grid cell
                // Don't pass color to preserve original icon colors
                isSelected: false, // Don't double-highlight
              ),
            ),
          ),
        ),
      ),
    );
  }
}
