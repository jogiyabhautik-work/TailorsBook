import 'package:flutter/material.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/responsive.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int? ordersBadgeCount;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.ordersBadgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = keyboardInset(context) > 0;
    final bottomPad = bottomSafePadding(context);

    // Hide nav bar when keyboard is visible
    if (isKeyboardOpen) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: R.value(context, regular: 24, smallPhone: 16, tablet: 48, largeTablet: 64),
      right: R.value(context, regular: 24, smallPhone: 16, tablet: 48, largeTablet: 64),
      bottom: bottomPad + 16, // Fixed gap
      child: Container(
        height: 64, // Sleeker height without labels
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: DesignSystem.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: DesignSystem.charcoal.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.straighten_outlined,
              activeIcon: Icons.straighten_rounded,
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
              badgeCount: ordersBadgeCount,
            ),
            _NavItem(
              icon: Icons.people_alt_outlined,
              activeIcon: Icons.people_alt_rounded,
              isSelected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: Icons.engineering_outlined,
              activeIcon: Icons.engineering_rounded,
              isSelected: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? DesignSystem.primaryContainer : Colors.transparent,
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? DesignSystem.white : DesignSystem.inactiveIcon,
                size: 24,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: DesignSystem.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: DesignSystem.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
