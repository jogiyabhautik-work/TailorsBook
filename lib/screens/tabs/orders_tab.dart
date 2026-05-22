import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../models/order_model.dart';
import '../../models/customer_model.dart';
import '../order/order_detail_screen.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/tailor_flow_helper.dart';
import '../../providers/order_provider.dart';
import '../../providers/customer_provider.dart';
import '../order/create_order_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  String _currentFilter = 'all';
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  List<OrderModel> _displayedOrders = [];
  Map<String, Customer> _customerMap = {};
  Map<String, dynamic> _workerMap = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       OrderProviderWrapper.of(context).fetchOrders();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (context.mounted) setState(() => _searchQuery = query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = CustomerProviderWrapper.of(context);
    final workerProvider = WorkerProviderWrapper.of(context);
    final orderProvider = OrderProviderWrapper.of(context);

    _customerMap = {for (var c in customerProvider.customers) c.id: c};
    _workerMap = {for (var w in workerProvider.workers) w.id: w};

    _displayedOrders = orderProvider.orders.where((o) {
      if (_currentFilter == 'all') return true;
      return o.status.toLowerCase() == _currentFilter;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      _displayedOrders = _displayedOrders.where((o) {
        final customer = _customerMap[o.customerId];
        final name = customer?.name.toLowerCase() ?? '';
        final phone = customer?.phone ?? '';
        final token = o.orderToken.toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery) || token.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    _displayedOrders.sort((a, b) {
      if (a.status == b.status) {
        if (a.deliveryDate == null && b.deliveryDate == null) return 0;
        if (a.deliveryDate == null) return 1;
        if (b.deliveryDate == null) return -1;
        return a.deliveryDate!.compareTo(b.deliveryDate!);
      }
      return 0;
    });

    return Scaffold(
      backgroundColor: DesignSystem.surface,
      body: RefreshIndicator(
        onRefresh: () => orderProvider.fetchOrders(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topSafePadding(context) + R.value(context, regular: 16, smallPhone: 12))),

            SliverToBoxAdapter(
              child: ConstrainedContent(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ORDERS', style: DesignSystem.pageTitle),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOrderScreen())),
                            child: Container(
                              padding: EdgeInsets.all(R.value(context, regular: 10, smallPhone: 8)),
                              decoration: BoxDecoration(color: DesignSystem.primaryContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DesignSystem.radiusMd)),
                              child: Icon(Icons.add_rounded, color: DesignSystem.primaryContainer, size: R.value(context, regular: 22, smallPhone: 20)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: R.gap(context)),
                      AppSearchBar(
                        onChanged: _onSearchChanged,
                        hintText: 'Search by name, phone, or token',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: R.gap(context))),

            SliverToBoxAdapter(
              child: ConstrainedContent(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
                  child: Row(
                    children: [
                      AppFilterChip(label: 'All', isSelected: _currentFilter == 'all', onTap: () => setState(() => _currentFilter = 'all'), count: orderProvider.orders.length),
                      const SizedBox(width: 8),
                      AppFilterChip(label: 'Pending', isSelected: _currentFilter == 'pending', onTap: () => setState(() => _currentFilter = 'pending'), count: orderProvider.orders.where((o) => o.status == 'pending').length),
                      const SizedBox(width: 8),
                      AppFilterChip(label: 'Stitching', isSelected: _currentFilter == 'stitching', onTap: () => setState(() => _currentFilter = 'stitching'), count: orderProvider.orders.where((o) => o.status == 'stitching').length),
                      const SizedBox(width: 8),
                      AppFilterChip(label: 'Fitting', isSelected: _currentFilter == 'trialing', onTap: () => setState(() => _currentFilter = 'trialing'), count: orderProvider.orders.where((o) => o.status == 'trialing').length),
                      const SizedBox(width: 8),
                      AppFilterChip(label: 'Ready', isSelected: _currentFilter == 'ready', onTap: () => setState(() => _currentFilter = 'ready'), count: orderProvider.orders.where((o) => o.status == 'ready').length),
                      const SizedBox(width: 8),
                      AppFilterChip(label: 'Delivered', isSelected: _currentFilter == 'delivered', onTap: () => setState(() => _currentFilter = 'delivered'), count: orderProvider.orders.where((o) => o.status == 'delivered').length),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: R.sectionGap(context))),

            if (orderProvider.isLoading && _displayedOrders.isEmpty)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
                sliver: SliverToBoxAdapter(
                  child: ShimmerCardLoader(count: 4, height: 120),
                ),
              )
            else if (orderProvider.errorMessage != null && _displayedOrders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorStateWidget(
                  title: 'Connection Error',
                  subtitle: 'Unable to load orders. Please check your connection.',
                  onRetry: () => orderProvider.fetchOrders(),
                ),
              )
            else if (_displayedOrders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildFilterEmptyState(),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
                sliver: _buildOrdersList(orderProvider, customerProvider),
              ),
            SliverToBoxAdapter(child: SizedBox(height: effectiveBottomPadding(context) + 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(OrderProvider orderProvider, CustomerProvider customerProvider) {
    final isTablet = Breakpoints.isTabletOrWider(context);
    if (isTablet) {
      final ordersWidgets = _displayedOrders.map((order) {
        final customer = _customerMap[order.customerId] ?? Customer(id: '', name: 'Unknown', phone: '', address: '');
        final worker = order.assignedWorkerId != null ? _workerMap[order.assignedWorkerId] : null;
        return _orderCard(order, customer, worker);
      }).toList();
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: R.gap(context),
          mainAxisSpacing: R.gap(context),
          childAspectRatio: 1.3,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => ordersWidgets[i],
          childCount: ordersWidgets.length,
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final order = _displayedOrders[index];
          final customer = _customerMap[order.customerId] ?? Customer(id: '', name: 'Unknown', phone: '', address: '');
          final worker = order.assignedWorkerId != null ? _workerMap[order.assignedWorkerId] : null;
          return Padding(
            padding: EdgeInsets.only(bottom: R.gap(context)),
            child: _orderCard(order, customer, worker),
          );
        },
        childCount: _displayedOrders.length,
      ),
    );
  }

  Widget _orderCard(OrderModel order, Customer customer, dynamic worker) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);
    final daysLeft = order.deliveryDate?.difference(DateTime.now()).inDays;
    bool isUrgent = daysLeft != null && daysLeft <= 2 && !['delivered', 'cancelled'].contains(order.status.toLowerCase());

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order, customer: customer))),
      child: Container(
        decoration: BoxDecoration(
          color: DesignSystem.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
          border: Border.all(color: isUrgent ? DesignSystem.error.withValues(alpha: 0.2) : DesignSystem.outlineVariant),
          boxShadow: DesignSystem.cardShadow,
        ),
        child: Padding(
          padding: EdgeInsets.all(R.cardPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        Text(customer.name, style: DesignSystem.cardTitle, overflow: TextOverflow.ellipsis),
                        SizedBox(height: R.value(context, regular: 2, smallPhone: 1)),
                        Row(children: [Icon(Icons.tag_rounded, size: 12, color: DesignSystem.muted), const SizedBox(width: 4), Text(order.orderToken, style: DesignSystem.caption)]),
                      ],
                    ),
                  ),
                  StatusBadge(label: statusLabel, color: statusColor),
                ],
              ),
              SizedBox(height: R.gap(context)),
              Container(
                padding: EdgeInsets.all(R.cardPadding(context)),
                decoration: BoxDecoration(color: DesignSystem.surface, borderRadius: BorderRadius.circular(DesignSystem.radiusMd)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: isUrgent ? DesignSystem.error : DesignSystem.muted),
                      const SizedBox(width: 6),
                      Text(TailorFlowHelper.formatDate(order.deliveryDate), style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: isUrgent ? DesignSystem.error : DesignSystem.muted)),
                    ]),
                    Text('₹${order.totalPrice.toStringAsFixed(0)}', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: DesignSystem.charcoal)),
                  ],
                ),
              ),
              SizedBox(height: R.gap(context)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.person_outline_rounded, size: 14, color: DesignSystem.muted),
                    const SizedBox(width: 4),
                    Text(worker?.name ?? 'Unassigned', style: GoogleFonts.manrope(fontSize: 11, color: DesignSystem.muted, fontWeight: FontWeight.w500)),
                  ]),
                  if (order.pendingBalance > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: DesignSystem.errorContainer, borderRadius: BorderRadius.circular(DesignSystem.radiusSm)),
                      child: Text('Due: ₹${order.pendingBalance.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: DesignSystem.error, fontSize: 10, fontWeight: FontWeight.w800)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: DesignSystem.tertiaryContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DesignSystem.radiusSm)),
                      child: Text('PAID', style: GoogleFonts.manrope(color: DesignSystem.tertiaryContainer, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'PENDING';
      case 'stitching': return 'STITCHING';
      case 'trialing': return 'FITTING';
      case 'ready': return 'READY';
      case 'delivered': return 'DELIVERED';
      case 'cancelled': return 'CANCELLED';
      default: return status.toUpperCase();
    }
  }

  Widget _buildFilterEmptyState() {
    final filterIcons = {
      'all': Icons.receipt_long_rounded, 'pending': Icons.hourglass_empty_rounded,
      'stitching': Icons.cut_rounded, 'trialing': Icons.accessibility_new_rounded,
      'ready': Icons.check_circle_outline_rounded, 'delivered': Icons.local_shipping_rounded,
    };
    return EmptyStateWidget(icon: filterIcons[_currentFilter] ?? Icons.receipt_long_rounded, title: 'No orders', subtitle: 'Try changing the filter or create a new order');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return DesignSystem.warning;
      case 'stitching': return DesignSystem.info;
      case 'trialing': return DesignSystem.primaryContainer;
      case 'ready': return DesignSystem.tertiaryContainer;
      case 'delivered': return DesignSystem.primaryContainer;
      case 'cancelled': return DesignSystem.error;
      default: return DesignSystem.muted;
    }
  }
}
