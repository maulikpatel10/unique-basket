import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_responsive.dart';
import '../../app/theme/app_text_styles.dart';

/// Reusable Promotional Banner Card for Unique Basket.
///
/// Visual Architecture:
/// - Full-bleed backend photography ([imageUrl]) covering entire card with [BoxFit.cover].
/// - Left-to-right cinematic UNIQUE BASKET brand green gradient overlay ([AppColors.primary]).
/// - High-contrast readable white promotional typography on the left.
/// - "Fresh Harvest" brand badge above the headline.
/// - "Shop Now →" white CTA pill button below the headline.
/// - Responsive scaling and tactile micro-press feedback.
class PromoBanner extends StatefulWidget {
  final String? id;
  final String? tag;
  final String title;
  final String? subtitle;
  final String ctaText;
  final String? imageUrl;
  final VoidCallback? onTap;

  const PromoBanner({
    super.key,
    this.id,
    this.tag = 'Fresh Harvest',
    required this.title,
    this.subtitle,
    this.ctaText = 'Shop Now',
    this.imageUrl,
    this.onTap,
  });

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasImageUrl =
        widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Full-bleed background: Network Image or elegant fallback
                if (hasImageUrl)
                  Image.network(
                    widget.imageUrl!.trim(),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.primary,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF1E3A34),
                              Color(0xFF2A5048),
                              Color(0xFF3B6B60),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1E3A34),
                          Color(0xFF2A5048),
                          Color(0xFF3B6B60),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),

                // 2. Left-to-right UNIQUE BASKET green gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.95),
                          AppColors.primary.withValues(alpha: 0.85),
                          AppColors.primary.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.35, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Foreground Content (Badge, Multiline Title, CTA Button)
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: context.r(10.0).clamp(8.0, 16.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Badge: "Fresh Harvest"
                              if (widget.tag != null && widget.tag!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 3.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9E4B00),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    widget.tag!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: context.sp(10.5),
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppTextStyles.fontFamily,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),

                              // Backend-driven Title (e.g. "20% Off Seasonal Greens")
                              Text(
                                widget.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.sp(16),
                                  fontWeight: FontWeight.w800,
                                  fontFamily: AppTextStyles.fontFamily,
                                  height: 1.15,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // "Shop Now →" CTA Button
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                  vertical: 5.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.ctaText,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: context.sp(11),
                                        fontWeight: FontWeight.w800,
                                        fontFamily: AppTextStyles.fontFamily,
                                      ),
                                    ),
                                    const SizedBox(width: 4.0),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: AppColors.primary,
                                      size: 13.0,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
