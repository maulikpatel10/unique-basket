import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_responsive.dart';
import '../../app/theme/app_text_styles.dart';

/// Reusable circular Category Item for Unique Basket.
///
/// Features:
/// - Circular icon container with soft background tint.
/// - Themed typography for category name.
/// - Tactile micro-press feedback.
/// - Fallback color and icon resolvers based on category name.
class CategoryItem extends StatefulWidget {
  final String id;
  final String name;
  final IconData? icon;
  final String? imageUrl;
  final Color? color;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryItem({
    super.key,
    required this.id,
    required this.name,
    this.icon,
    this.imageUrl,
    this.color,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedColor = widget.color ?? _getCategoryColor(widget.name);
    final resolvedIcon = widget.icon ?? _getCategoryIcon(widget.name);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: SizedBox(
          width: context.r(72),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Container
              Container(
                width: context.r(68),
                height: context.r(68),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? resolvedColor.withValues(alpha: 0.18)
                      : resolvedColor.withValues(alpha: 0.10),
                  border: Border.all(
                    color: widget.isSelected
                        ? const Color(0xFF014D40)
                        : (isDark
                            ? resolvedColor.withValues(alpha: 0.35)
                            : resolvedColor.withValues(alpha: 0.25)),
                    width: widget.isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: resolvedColor.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.imageUrl != null &&
                          widget.imageUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            widget.imageUrl!,
                            width: context.r(52),
                            height: context.r(52),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              resolvedIcon,
                              size: context.r(30),
                              color: resolvedColor,
                            ),
                          ),
                        )
                      : Icon(
                          resolvedIcon,
                          size: context.r(30),
                          color: resolvedColor,
                        ),
                ),
              ),

              const SizedBox(height: 6.0),

              // Category Name
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: context.sp(12),
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: widget.isSelected
                      ? const Color(0xFF014D40)
                      : (isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B)),
                  fontFamily: AppTextStyles.fontFamily,

                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center

              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _getCategoryColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fruit')) return const Color(0xFFEA580C);
    if (lower.contains('veg')) return const Color(0xFF16A34A);
    if (lower.contains('exotic')) return const Color(0xFF9333EA);
    if (lower.contains('organic')) return const Color(0xFF0D9488);
    if (lower.contains('dairy')) return const Color(0xFF0284C7);
    if (lower.contains('bakery')) return const Color(0xFFD97706);
    return const Color(0xFF014D40);
  }

  static IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fruit')) return Icons.apple_rounded;
    if (lower.contains('veg')) return Icons.eco_rounded;
    if (lower.contains('exotic')) return Icons.auto_awesome_rounded;
    if (lower.contains('organic')) return Icons.spa_rounded;
    if (lower.contains('dairy')) return Icons.local_drink_rounded;
    if (lower.contains('bakery')) return Icons.bakery_dining_rounded;
    return Icons.category_rounded;
  }
}
