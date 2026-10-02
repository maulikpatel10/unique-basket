import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Reusable Category Card for Screen 09 Explore / Category Listing.
///
/// Refined visual presentation matching the approved Categories specification:
/// - Tall rounded white card with subtle 1px border and soft elevation.
/// - Large circular composition (135–155dp) with pastel ring treatment.
/// - Centered category image loaded dynamically with graceful fallback.
/// - Prominent, centered Montserrat typography supporting 1–2 centered lines.
/// - Tactile micro-interaction with light haptic feedback.
class ExploreCategoryCard extends StatefulWidget {
  final String id;
  final String name;
  final String? imageUrl;
  final Color? color;
  final VoidCallback? onTap;

  const ExploreCategoryCard({
    super.key,
    required this.id,
    required this.name,
    this.imageUrl,
    this.color,
    this.onTap,
  });

  @override
  State<ExploreCategoryCard> createState() => _ExploreCategoryCardState();
}

class _ExploreCategoryCardState extends State<ExploreCategoryCard> {
  bool _isPressed = false;

  static Color _getCategoryPastelColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fruit')) return const Color(0xFFEA580C); // Soft peach / orange
    if (lower.contains('leafy') || lower.contains('herb')) return const Color(0xFF16A34A); // Soft mint / green
    if (lower.contains('veg')) return const Color(0xFF16A34A); // Soft mint / green
    if (lower.contains('dairy') || lower.contains('milk')) return const Color(0xFF0284C7); // Soft sky blue
    if (lower.contains('bakery') || lower.contains('bread')) return const Color(0xFFD97706); // Soft amber
    return const Color(0xFF014D40); // Brand green
  }

  static IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fruit')) return Icons.apple_rounded;
    if (lower.contains('leafy')) return Icons.eco_rounded;
    if (lower.contains('veg')) return Icons.grass_rounded;
    if (lower.contains('dairy')) return Icons.egg_alt_rounded;
    if (lower.contains('bakery')) return Icons.bakery_dining_rounded;
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pastelColor = widget.color ?? _getCategoryPastelColor(widget.name);
    final fallbackIcon = _getCategoryIcon(widget.name);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: AppRadius.rXl,
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Upper Large Circular Composition (135–155dp responsive)
              Expanded(
                child: Center(
                  child: Container(
                    width: context.r(138),
                    height: context.r(138),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? pastelColor.withValues(alpha: 0.18)
                          : pastelColor.withValues(alpha: 0.10),
                      border: Border.all(
                        color: isDark
                            ? pastelColor.withValues(alpha: 0.32)
                            : pastelColor.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: pastelColor.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.imageUrl != null &&
                              widget.imageUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                widget.imageUrl!,
                                width: context.r(112),
                                height: context.r(112),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  fallbackIcon,
                                  size: context.r(50),
                                  color: pastelColor,
                                ),
                              ),
                            )
                          : Icon(
                              fallbackIcon,
                              size: context.r(50),
                              color: pastelColor,
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10.0),

              // Category Name (Deterministic height, bold Montserrat, 1–2 centered lines)
              SizedBox(
                height: context.r(42),
                child: Center(
                  child: Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w800,
                      height: 1.16,
                      letterSpacing: -0.2,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
