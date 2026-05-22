import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../models/customer_model.dart';
import '../customers/add_customer_screen.dart';
import '../customers/customer_detail_screen.dart';
import '../customers/customer_measurement_screen.dart';
import '../order/create_order_screen.dart';
import '../../providers/customer_provider.dart';
import '../../providers/template_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/responsive.dart';

class CustomerTab extends StatefulWidget {
  const CustomerTab({super.key});

  @override
  State<CustomerTab> createState() => _CustomerTabState();
}

class _CustomerTabState extends State<CustomerTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  String _filterStatus = 'all';
  List<Customer> _filteredCustomers = [];
  final Map<String, double> _customerBalanceMap = {};
  final Map<String, int> _customerActiveOrdersMap = {};
  final Map<String, bool> _customerHasMeasurementsMap = {};
  CustomerProvider? _cachedCustomerProvider;
  bool _needsMapRebuild = true;
  OrderProvider? _cachedOrderProvider;
  TemplateProvider? _cachedTemplateProvider;

  List<OrderModel>? _lastOrders;
  List<Customer>? _lastCustomers;
  dynamic _lastMeasurements;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedCustomerProvider = CustomerProviderWrapper.of(context);
    _cachedOrderProvider = OrderProviderWrapper.of(context);
    _cachedTemplateProvider = TemplateProviderWrapper.of(context);
    _needsMapRebuild = true;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final provider = _cachedCustomerProvider;
    if (provider == null || provider.isSearching || provider.searchResults.isNotEmpty) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!provider.isLoading && provider.hasMore) provider.fetchCustomers();
    }
  }

  void _rebuildLookupMaps() {
    if (!context.mounted) return;
    final orderProvider = _cachedOrderProvider;
    final customerProvider = _cachedCustomerProvider;
    final templateProvider = _cachedTemplateProvider;
    if (orderProvider == null || customerProvider == null || templateProvider == null) return;

    final orders = orderProvider.orders;
    final customers = customerProvider.customers;
    final measurements = templateProvider.measurements;
    if (_lastOrders == orders && _lastCustomers == customers && _lastMeasurements == measurements) {
      _applyFilters(); return;
    }
    _lastOrders = orders; _lastCustomers = customers; _lastMeasurements = measurements;
    _customerBalanceMap.clear(); _customerActiveOrdersMap.clear();
    for (final order in orders) {
      if (!order.isCancelled && order.status != 'delivered') {
        _customerBalanceMap[order.customerId] = (_customerBalanceMap[order.customerId] ?? 0) + order.pendingBalance;
        _customerActiveOrdersMap[order.customerId] = (_customerActiveOrdersMap[order.customerId] ?? 0) + 1;
      }
    }
    _customerHasMeasurementsMap.clear();
    for (final customer in customers) {
      _customerHasMeasurementsMap[customer.id] = templateProvider.getCustomerMeasurements(customer.id).isNotEmpty;
    }
    _applyFilters();
  }

  void _applyFilters() {
    if (!context.mounted) return;
    final customerProvider = _cachedCustomerProvider;
    if (customerProvider == null) return;
    final sourceList = customerProvider.isSearching || customerProvider.searchResults.isNotEmpty
        ? customerProvider.searchResults : customerProvider.customers;
    _filteredCustomers = sourceList.where((c) {
      if (_filterStatus == 'dues') { final b = _customerBalanceMap[c.id] ?? 0; return b > 0; }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); _scrollController.dispose(); _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_needsMapRebuild) { _needsMapRebuild = false; _rebuildLookupMaps(); }
    final customerProvider = CustomerProviderWrapper.of(context);

    return Scaffold(
      backgroundColor: DesignSystem.surface,
      body: RefreshIndicator(
        onRefresh: () => customerProvider.fetchCustomers(refresh: true),
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
                          Text('CLIENTS', style: DesignSystem.pageTitle),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerScreen())),
                            child: Container(
                              padding: EdgeInsets.all(R.value(context, regular: 10, smallPhone: 8)),
                              decoration: BoxDecoration(color: DesignSystem.primaryContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DesignSystem.radiusMd)),
                              child: Icon(Icons.person_add_rounded, color: DesignSystem.primaryContainer, size: R.value(context, regular: 22, smallPhone: 20)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: R.gap(context)),
                      AppSearchBar(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                          _debounceTimer?.cancel();
                          _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                            final p = _cachedCustomerProvider;
                            if (p != null) { if (val.trim().isEmpty) {
                              p.clearSearch();
                            } else {
                              p.searchCustomers(val.trim());
                            } }
                          });
                        },
                        hintText: 'Search by name or phone',
                        showLoading: _searchQuery.isNotEmpty && (_cachedCustomerProvider?.isSearching ?? false),
                      ),
                      SizedBox(height: R.gap(context)),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          AppFilterChip(label: 'All', isSelected: _filterStatus == 'all', onTap: () { setState(() => _filterStatus = 'all'); _applyFilters(); }),
                          const SizedBox(width: 8),
                          AppFilterChip(label: 'With Dues', isSelected: _filterStatus == 'dues', onTap: () { setState(() => _filterStatus = 'dues'); _applyFilters(); }),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: R.sectionGap(context))),

            ..._buildSliverBody(customerProvider, _filteredCustomers),
            SliverToBoxAdapter(child: SizedBox(height: effectiveBottomPadding(context) + 16)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSliverBody(CustomerProvider customerProvider, List<Customer> filteredCustomers) {
    if (customerProvider.isLoading && filteredCustomers.isEmpty) {
      return [SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
        sliver: SliverToBoxAdapter(child: ShimmerCardLoader(count: 6, height: 120)),
      )];
    }
    if (customerProvider.hasError && filteredCustomers.isEmpty) {
      return [SliverFillRemaining(hasScrollBody: false, child: ErrorStateWidget(title: 'Connection Error', subtitle: 'Unable to load clients.', onRetry: () => customerProvider.fetchCustomers(refresh: true)))];
    }
    if (filteredCustomers.isEmpty) {
      return [SliverFillRemaining(hasScrollBody: false, child: EmptyStateWidget(icon: Icons.people_rounded, title: _searchQuery.isEmpty ? 'No clients yet' : 'No matching clients', subtitle: _searchQuery.isEmpty ? 'Add your first client to get started' : 'Try a different search term'))];
    }

    final isMobile = ResponsiveLayout.isMobile(context);
    if (isMobile) {
      return [SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
        sliver: SliverList(delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == filteredCustomers.length) {
              return Center(child: Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2, color: DesignSystem.primaryContainer))));
            }
            return RepaintBoundary(child: Padding(padding: EdgeInsets.only(bottom: R.gap(context)), child: _customerCard(filteredCustomers[index])));
          },
          childCount: filteredCustomers.length + (customerProvider.hasMore ? 1 : 0),
        )),
      )];
    }

    return [SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: R.gap(context), mainAxisSpacing: R.gap(context), childAspectRatio: 1.5,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == filteredCustomers.length) return Center(child: SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2, color: DesignSystem.primaryContainer)));
            return RepaintBoundary(child: _customerCard(filteredCustomers[index]));
          },
          childCount: filteredCustomers.length + (customerProvider.hasMore ? 1 : 0),
        ),
      ),
    )];
  }

  Widget _customerCard(Customer customer) {
    final activeOrdersCount = _customerActiveOrdersMap[customer.id] ?? 0;
    final totalBalance = _customerBalanceMap[customer.id] ?? 0;
    final hasMeasurements = _customerHasMeasurementsMap[customer.id] ?? false;
    final isVIP = activeOrdersCount >= 3;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: customer))),
      child: Container(
        decoration: BoxDecoration(
          color: DesignSystem.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
          border: Border.all(color: totalBalance > 0 ? DesignSystem.error.withValues(alpha: 0.2) : DesignSystem.outlineVariant),
          boxShadow: DesignSystem.cardShadow,
        ),
        child: Padding(
          padding: EdgeInsets.all(R.cardPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Stack(children: [
                  CircleAvatar(radius: R.avatarRadius(context), backgroundColor: DesignSystem.primaryContainer.withValues(alpha: 0.1),
                    child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?', style: GoogleFonts.manrope(color: DesignSystem.primaryContainer, fontWeight: FontWeight.w800, fontSize: 18))),
                  if (isVIP) Positioned(right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: DesignSystem.warning, shape: BoxShape.circle), child: const Icon(Icons.star_rounded, color: DesignSystem.surfaceContainerLowest, size: 10))),
                ]),
                SizedBox(width: R.gap(context)),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(customer.name, style: DesignSystem.cardTitle, overflow: TextOverflow.ellipsis)),
                    if (isVIP) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: DesignSystem.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DesignSystem.radiusSm)), child: Text('VIP', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w900, color: DesignSystem.warning))),
                  ]),
                  SizedBox(height: R.value(context, regular: 2, smallPhone: 1)),
                  Text(customer.phone, style: DesignSystem.caption),
                ])),
              ]),
              SizedBox(height: R.gap(context)),
              Row(children: [
                _infoChip(hasMeasurements ? Icons.check_rounded : Icons.straighten_rounded, hasMeasurements ? 'Measured' : 'No Measures', hasMeasurements ? DesignSystem.tertiaryContainer : DesignSystem.warning),
                const SizedBox(width: 8),
                if (activeOrdersCount > 0) _infoChip(Icons.shopping_bag_rounded, '$activeOrdersCount Active', DesignSystem.info),
                const Spacer(),
                if (totalBalance > 0) Text('₹${totalBalance.toStringAsFixed(0)}', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: DesignSystem.error)),
              ]),
              SizedBox(height: R.gap(context)),
              Row(children: [
                Expanded(child: _actionButton(Icons.call_rounded, 'Call', DesignSystem.tertiaryContainer, () { if (customer.phone.isNotEmpty) launchUrl(Uri.parse('tel:${customer.phone}')); })),
                const SizedBox(width: 8),
                Expanded(child: _actionButton(Icons.straighten_rounded, 'Measure', DesignSystem.info, () { Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerMeasurementScreen(customer: customer))); })),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _actionButton(Icons.add_rounded, 'New Order', DesignSystem.primaryContainer, () { Navigator.push(context, MaterialPageRoute(builder: (_) => CreateOrderScreen(preSelectedCustomer: customer))); })),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DesignSystem.radiusSm)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: color))]),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(DesignSystem.radiusMd)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 16), const SizedBox(width: 4), Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: color))]),
      ),
    );
  }
}
