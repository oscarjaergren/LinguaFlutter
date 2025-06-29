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
    final iconColor = color ?? theme.iconTheme.color ?? Colors.black;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 16,
        height: size + 16,
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primaryContainer 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(
                  color: theme.colorScheme.primary, 
                  width: 2,
                ) 
              : null,
        ),
        child: Center(
          child: SvgPicture.network(
            icon.svgUrl,
            width: size,
            height: size,
            colorFilter: ColorFilter.mode(
              iconColor,
              BlendMode.srcIn,
            ),
            placeholderBuilder: (context) => SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor.withValues(alpha: 0.5),
              ),
            ),
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
    
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected 
          ? theme.colorScheme.primaryContainer 
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: IconifyIcon(
                  icon: icon,
                  size: 32,
                  isSelected: isSelected,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Text(
                      icon.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isSelected 
                            ? theme.colorScheme.onPrimaryContainer 
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      icon.set,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: (isSelected 
                            ? theme.colorScheme.onPrimaryContainer 
                            : theme.textTheme.bodySmall?.color)?.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
