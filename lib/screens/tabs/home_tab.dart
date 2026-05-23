import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tailorsbook/screens/tabs/profile_tab.dart';
import '../order/create_order_screen.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../models/order_model.dart';
import '../../models/customer_model.dart';
import '../order/order_detail_screen.dart';
import '../dashboard/business_dashboard_screen.dart';
import '../tabs/worker_tab.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  User? _user;
  Map<String, dynamic>? _metadata;

  List<OrderModel>? _lastOrders;
  List<OrderModel> _cachedActiveOrders = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = TemplateProviderWrapper.of(context, listen: false);
      tp.fetchMeasurements();
    });
  }

  DateTime? _deliveryDay(OrderModel o) {
    if (o.deliveryDate == null) return null;
    return DateTime(o.deliveryDate!.year, o.deliveryDate!.month, o.deliveryDate!.day);
  }

  void _loadUserData() {
    setState(() {
      _user = Supabase.instance.client.auth.currentUser;
      _metadata = _user?.userMetadata;
    });
  }

  @override
  Widget build(BuildContext context) {
    final templateProvider = TemplateProviderWrapper.of(context);
    final orderProvider = OrderProviderWrapper.of(context);
    final customerProvider = CustomerProviderWrapper.of(context);

    final String fullName = _metadata?['full_name'] ?? 'Tailor';
    final String firstName = fullName.split(' ')[0];
    final String currentDate = DateFormat('EEE, dd MMM').format(DateTime.now());

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final orders = orderProvider.orders;
    if (_lastOrders == null || _lastOrders != orders) {
      _lastOrders = orders;
      _cachedActiveOrders = orders
          .where((o) => !o.isCancelled && o.status.toLowerCase() != 'delivered')
          .toList();
    }
    final activeOrders = _cachedActiveOrders;

    final overdueOrders = activeOrders.where((o) {
      final d = _deliveryDay(o);
      return d != null && d.isBefore(today);
    }).toList();

    final completedOrders = orders.where((o) => o.status.toLowerCase() == 'delivered').toList();
    final totalRevenue = orders.fold<double>(0, (sum, o) => sum + o.totalPrice);
    final completionRate = orders.isEmpty ? 0.0 : completedOrders.length / orders.length * 100;

    return RefreshIndicator(
      onRefresh: () async {
        _loadUserData();
        await Future.wait([
          orderProvider.fetchOrders(),
          customerProvider.fetchCustomers(),
          templateProvider.fetchMeasurements(),
        ]);
      },
      color: DesignSystem.primaryContainer,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topSafePadding(context) + R.value(context, regular: 16, smallPhone: 12))),

          SliverToBoxAdapter(
            child: ConstrainedContent(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
                child: Row(
                  children: [
                    // ── Profile Ring Avatar ──────────────────────────────
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileTab()));
                        if (context.mounted) _loadUserData();
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Outer glow ring
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  DesignSystem.primaryContainer,
                                  DesignSystem.primary,
                                  DesignSystem.primaryContainer.withValues(alpha: 0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: DesignSystem.surface,
                              ),
                              child: CircleAvatar(
                                radius: R.avatarRadius(context),
                                backgroundColor: DesignSystem.primaryContainer.withValues(alpha: 0.08),
                                backgroundImage: (_metadata?['shop_logo_url'] as String? ?? '').isNotEmpty
                                    ? NetworkImage(_metadata!['shop_logo_url'] as String) as ImageProvider
                                    : null,
                                child: (_metadata?['shop_logo_url'] as String? ?? '').isEmpty
                                    ? Text(
                                        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                                        style: GoogleFonts.manrope(
                                          color: DesignSystem.primaryContainer,
                                          fontWeight: FontWeight.w800,
                                          fontSize: R.value(context, regular: 18, smallPhone: 16),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          // Online indicator dot
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: DesignSystem.tertiaryContainer,
                                shape: BoxShape.circle,
                                border: Border.all(color: DesignSystem.surface, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: R.value(context, regular: 12, smallPhone: 10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentDate, style: DesignSystem.greetingText),
                          Text('Hello, $firstName!', style: DesignSystem.pageTitle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: R.sectionGap(context))),

          SliverToBoxAdapter(
            child: ConstrainedContent(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: 'BUSINESS OVERVIEW'),
                    SizedBox(height: R.gap(context)),
                    _buildBentoGrid(context, activeOrders.length, overdueOrders.length, totalRevenue, completionRate),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: R.sectionGap(context))),

          SliverToBoxAdapter(
            child: ConstrainedContent(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: 'QUICK ACTIONS'),
                    SizedBox(height: R.gap(context)),
                    _buildQuickActions(context),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: R.sectionGap(context))),

          SliverToBoxAdapter(
            child: ConstrainedContent(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RECENT ORDERS', style: DesignSystem.sectionTitle),
                    TextButton(
                      onPressed: () => TemplateProviderWrapper.of(context, listen: false).setIndex(1),
                      child: Text('View All', style: DesignSystem.caption),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ConstrainedContent(
                  child: _buildRecentOrdersList(orderProvider, customerProvider),
                ),
                SizedBox(height: effectiveBottomPadding(context) + 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context, int activeCount, int overdueCount, double totalRevenue, double completionRate) {
    final isTablet = Breakpoints.isTabletOrWider(context);
    if (isTablet) {
      return ResponsiveCardGrid(
        childAspectRatio: 2.0,
        children: [
          _bentoCard(icon: Icons.shopping_bag_rounded, value: activeCount.toString(), label: 'Active Orders', color: DesignSystem.primaryContainer, bgColor: DesignSystem.primaryContainer.withValues(alpha: 0.08)),
          _bentoCard(icon: Icons.warning_rounded, value: overdueCount.toString(), label: 'Overdue', color: DesignSystem.error, bgColor: DesignSystem.errorContainer),
          _bentoCard(icon: Icons.currency_rupee_rounded, value: '₹${totalRevenue.toStringAsFixed(0)}', label: 'Total Revenue', color: DesignSystem.tertiaryContainer, bgColor: DesignSystem.tertiaryContainer.withValues(alpha: 0.08)),
          _bentoCard(icon: Icons.speed_rounded, value: '${completionRate.toStringAsFixed(0)}%', label: 'Completion', color: DesignSystem.info, bgColor: DesignSystem.infoContainer),
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _bentoCard(icon: Icons.shopping_bag_rounded, value: activeCount.toString(), label: 'Active Orders', color: DesignSystem.primaryContainer, bgColor: DesignSystem.primaryContainer.withValues(alpha: 0.08))),
            SizedBox(width: R.gap(context)),
            Expanded(child: _bentoCard(icon: Icons.warning_rounded, value: overdueCount.toString(), label: 'Overdue', color: DesignSystem.error, bgColor: DesignSystem.errorContainer)),
          ],
        ),
        SizedBox(height: R.gap(context)),
        Row(
          children: [
            Expanded(child: _bentoCard(icon: Icons.currency_rupee_rounded, value: '₹${totalRevenue.toStringAsFixed(0)}', label: 'Total Revenue', color: DesignSystem.tertiaryContainer, bgColor: DesignSystem.tertiaryContainer.withValues(alpha: 0.08))),
            SizedBox(width: R.gap(context)),
            Expanded(child: _bentoCard(icon: Icons.speed_rounded, value: '${completionRate.toStringAsFixed(0)}%', label: 'Completion', color: DesignSystem.info, bgColor: DesignSystem.infoContainer)),
          ],
        ),
      ],
    );
  }

  Widget _bentoCard({required IconData icon, required String value, required String label, required Color color, required Color bgColor}) {
    return Container(
      padding: EdgeInsets.all(R.cardPadding(context)),
      decoration: DesignSystem.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(R.value(context, regular: 8, smallPhone: 6)),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(DesignSystem.radiusSm)),
            child: Icon(icon, color: color, size: R.value(context, regular: 18, smallPhone: 16)),
          ),
          SizedBox(height: R.value(context, regular: 12, smallPhone: 8)),
          Text(value, style: DesignSystem.statValue),
          const SizedBox(height: 2),
          Text(label, style: DesignSystem.statLabel),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _quickActionBtn(icon: Icons.add_rounded, label: 'New Order', color: DesignSystem.primaryContainer, onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOrderScreen()));
          if (context.mounted) {
            OrderProviderWrapper.of(context, listen: false).fetchOrders();
            CustomerProviderWrapper.of(context, listen: false).fetchCustomers();
          }
        })),
        SizedBox(width: R.gap(context)),
        Expanded(child: _quickActionBtn(icon: Icons.engineering_rounded, label: 'Workers', color: DesignSystem.info, onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerTab()));
        })),
        SizedBox(width: R.gap(context)),
        Expanded(child: _quickActionBtn(icon: Icons.people_rounded, label: 'Clients', color: DesignSystem.primaryContainer, onTap: () {
          TemplateProviderWrapper.of(context, listen: false).setIndex(2);
        })),
        SizedBox(width: R.gap(context)),
        Expanded(child: _quickActionBtn(icon: Icons.analytics_rounded, label: 'Analytics', color: DesignSystem.primaryContainer, onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessDashboardScreen()));
          if (context.mounted) OrderProviderWrapper.of(context, listen: false).fetchOrders();
        })),
      ],
    );
  }

  Widget _quickActionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: R.value(context, regular: 16, smallPhone: 12), horizontal: 4),
        decoration: DesignSystem.card,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(R.value(context, regular: 10, smallPhone: 8)),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(DesignSystem.radiusSm)),
              child: Icon(icon, color: color, size: R.value(context, regular: 20, smallPhone: 18)),
            ),
            SizedBox(height: R.value(context, regular: 8, smallPhone: 6)),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: R.value(context, regular: 11, smallPhone: 10), fontWeight: FontWeight.w700, color: DesignSystem.charcoal)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersList(OrderProvider orderProvider, CustomerProvider customerProvider) {
    final recentOrders = orderProvider.orders.where((o) => !o.isCancelled).take(5).toList();
    if (recentOrders.isEmpty) {
      return EmptyStateWidget(icon: Icons.receipt_long_rounded, title: 'No orders yet', subtitle: 'Create your first order to get started');
    }
    return Column(
      children: recentOrders.map((order) {
        final customer = customerProvider.customers.firstWhere(
          (c) => c.id == order.customerId,
          orElse: () => Customer(id: order.customerId, name: 'Unknown', phone: '', address: ''),
        );
        return _recentOrderCard(order, customer);
      }).toList(),
    );
  }

  Widget _recentOrderCard(OrderModel order, Customer customer) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order, customer: customer))),
      child: Container(
        margin: EdgeInsets.only(bottom: R.gap(context)),
        padding: EdgeInsets.all(R.cardPadding(context)),
        decoration: DesignSystem.card,
        child: Row(
          children: [
            CircleAvatar(
              radius: R.value(context, regular: 20, smallPhone: 18),
              backgroundColor: DesignSystem.primaryContainer.withValues(alpha: 0.1),
              child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?', style: GoogleFonts.manrope(color: DesignSystem.primaryContainer, fontWeight: FontWeight.w800, fontSize: R.value(context, regular: 16, smallPhone: 14))),
            ),
            SizedBox(width: R.gap(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: DesignSystem.cardTitle),
                  SizedBox(height: R.value(context, regular: 2, smallPhone: 1)),
                  Text(order.orderToken, style: DesignSystem.caption),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(label: statusLabel, color: statusColor),
                const SizedBox(height: 4),
                Text('₹${order.totalPrice.toStringAsFixed(0)}', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: DesignSystem.charcoal)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return DesignSystem.warning;
      case 'in progress': case 'stitching': return DesignSystem.info;
      case 'ready': return DesignSystem.tertiaryContainer;
      case 'delivered': return DesignSystem.primaryContainer;
      case 'cancelled': return DesignSystem.error;
      default: return DesignSystem.muted;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'PENDING';
      case 'in progress': case 'stitching': return 'IN PROGRESS';
      case 'ready': return 'READY';
      case 'delivered': return 'DELIVERED';
      case 'cancelled': return 'CANCELLED';
      default: return status.toUpperCase();
    }
  }
}
