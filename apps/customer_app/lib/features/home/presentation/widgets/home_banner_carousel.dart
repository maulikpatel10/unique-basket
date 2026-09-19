import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/promo_banner.dart';
import '../../data/models/banner_model.dart';

/// Screen 08 (Home) Promotional Banner Carousel.
///
/// Composes reusable [PromoBanner] cards inside a responsive carousel with indicator dots.
class HomeBannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;
  final ValueChanged<BannerModel>? onBannerTap;

  const HomeBannerCarousel({
    super.key,
    required this.banners,
    this.onBannerTap,
  });

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Carousel PageView
        SizedBox(
          height: context.r(160).clamp(136.0, 190.0),
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: PromoBanner(
                  id: banner.id,
                  tag: banner.tag,
                  title: banner.title,
                  ctaText: banner.ctaText,
                  imageUrl: banner.imageUrl,
                  onTap: () => widget.onBannerTap?.call(banner),
                ),
              );
            },
          ),
        ),

        // Indicator Dots below Carousel
        if (banners.length > 1) ...[
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
              final isActive = _currentPage == index;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: isActive ? 18.0 : 6.0,
                    height: 5.0,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF014D40)
                          : (isDark
                              ? AppColors.cardBorderDark
                              : const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
