import 'package:flutter/material.dart';
import '../../../../shared/shared.dart';

/// Grid item widget for displaying an icon in the icon search results
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
    return Card(
      elevation: isSelected ? 4.0 : 1.0,
      color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: IconifyIcon(
                  icon: icon,
                  size: 32.0,
                  color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Theme.of(context).iconTheme.color,
                ),
              ),
              const SizedBox(height: 4.0),
              Expanded(
                flex: 1,
                child: Text(
                  icon.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
