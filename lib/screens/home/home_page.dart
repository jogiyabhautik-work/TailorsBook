import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../widgets/common/provider_wrappers.dart';
import 'package:flutter/services.dart';
import '../../widgets/navigation/app_bottom_nav_bar.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/responsive.dart';
import '../tabs/home_tab.dart';
import '../tabs/customer_tab.dart';
import '../tabs/measurement_tab.dart';
import '../tabs/orders_tab.dart';
import '../tabs/worker_tab.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final List<Widget> _pages;
  final GlobalKey _scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Page order: Home, Orders, Customers
    _pages = const [
      HomeTab(),              // Index 0
      OrdersTab(),            // Index 1
      CustomerTab(),          // Index 2
    ];
  }

  Future<bool> _confirmExitApp() async {
    final result = await showResponsiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusXxl)),
        title: Text('Exit App', style: DesignSystem.cardTitle),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: R.value(ctx, regular: 400, tablet: 480)),
          child: const Text('Are you sure you want to exit?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: DesignSystem.bodyText)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusMd))),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final templateProvider = TemplateProviderWrapper.of(context);
    final orderProvider    = OrderProviderWrapper.of(context);
    final currentIndex     = templateProvider.activeIndex;

    final dueTodayCount = orderProvider.orders.where((o) {
      if (o.deliveryDate == null || o.status.toLowerCase() == 'delivered' || o.isCancelled) return false;
      final now = DateTime.now();
      final delivery = DateTime(o.deliveryDate!.year, o.deliveryDate!.month, o.deliveryDate!.day);
      final today = DateTime(now.year, now.month, now.day);
      return delivery.isAtSameMomentAs(today);
    }).length;
    final activeOrderCount = orderProvider.orders
        .where((o) => o.status.toLowerCase() != 'delivered')
        .length;
    final badgeCount = dueTodayCount > 0 ? dueTodayCount : activeOrderCount;

    final bool keyboardVisible = isKeyboardOpen(context);
    final bottomPad = bottomSafePadding(context);
    final totalBottomOffset = bottomPad + kNavBarTotalHeight + kMinBottomPadding;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (currentIndex != 0) {
          templateProvider.setIndex(0);
          return;
        }
        final ok = await _confirmExitApp();
        if (ok) SystemNavigator.pop();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: DesignSystem.surface,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // ── Page content (pushes up behind nav) ──
            Positioned.fill(
              bottom: 0,
              child: IndexedStack(
                index: currentIndex,
                children: _pages,
              ),
            ),

            // ── Floating pill navigation bar ──
            AppBottomNavBar(
              currentIndex: currentIndex,
              onTap: (index) => templateProvider.setIndex(index),
              ordersBadgeCount: badgeCount > 0 ? badgeCount : null,
            ),
          ],
        ),
      ),
    );
  }
}
