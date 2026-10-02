import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String? name;
  final String? phone;
  final String? photoPath;
  final VoidCallback? onEditTap;

  const ProfileHeaderCard({
    super.key,
    this.name,
    this.phone,
    this.photoPath,
    this.onEditTap,
  });

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'UB';
    }
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatPhone(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      return '';
    }
    final clean = rawPhone.trim();
    if (clean.startsWith('+91') && clean.length == 13) {
      return '+91 ${clean.substring(3, 8)} ${clean.substring(8)}';
    }
    return clean;
  }

  Widget _buildAvatar(BuildContext context, bool isDark) {
    final hasValidLocalPhoto = photoPath != null &&
        photoPath!.isNotEmpty &&
        File(photoPath!).existsSync();

    if (hasValidLocalPhoto) {
      return Container(
        width: context.w(60),
        height: context.w(60),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          File(photoPath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsAvatar(context, isDark),
        ),
      );
    }

    return _buildInitialsAvatar(context, isDark);
  }

  Widget _buildInitialsAvatar(BuildContext context, bool isDark) {
    final initials = _getInitials(name);
    return Container(
      width: context.w(60),
      height: context.w(60),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF00382E) : const Color(0xFFE7F5F4),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF005A4A) : const Color(0xFFCDECE9),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: context.sp(19.0),
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF34D399) : const Color(0xFF014D40),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayName = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()
        : 'Unique Basket Customer';
    final displayPhone = _formatPhone(phone);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: context.h(AppSpacing.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(context, isDark),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.sp(17.5),
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                if (displayPhone.isNotEmpty) ...[
                  const SizedBox(height: 3.0),
                  Text(
                    displayPhone,
                    style: TextStyle(
                      fontSize: context.sp(13.5),
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF475E5A),
                    ),
                  ),
                ],
                const SizedBox(height: 5.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14.0,
                      color: Color(0xFF00796B),
                    ),
                    const SizedBox(width: 4.0),
                    Flexible(
                      child: Text(
                        'Verified mobile number',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.sp(12.0),
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF00796B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Material(
            color: isDark ? const Color(0xFF00382E) : const Color(0xFFE7F5F4),
            borderRadius: BorderRadius.circular(20.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20.0),
              onTap: onEditTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 7.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: context.sp(13.0),
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF014D40),
                      ),
                    ),
                    const SizedBox(width: 2.0),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: context.sp(16.0),
                      color: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF014D40),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
