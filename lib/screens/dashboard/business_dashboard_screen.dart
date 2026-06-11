import 'package:flutter/material.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/provider_wrappers.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/utils/design_system.dart';
import 'fabric_reference_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DashboardProviderWrapper.of(context, listen: false).fetchMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = DashboardProviderWrapper.of(context);
    final metrics = dashboardProvider.metrics;
    final brandOrange = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: DesignSystem.surface,
      appBar: AppBar(
        title: Text('Business Analytics', style: GoogleFonts.manrope(fontWeight: FontWeight.w900, color: DesignSystem.charcoal)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: DesignSystem.surfaceContainerLowest,
        foregroundColor: DesignSystem.charcoal,
        actions: [
          IconButton(
            icon: const Icon(Icons.straighten_rounded),
            tooltip: 'Fabric Estimator',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FabricReferenceScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => dashboardProvider.fetchMetrics(),
          ),
        ],
      ),
      body: _buildBody(dashboardProvider, metrics, brandOrange),
    );
  }

  Widget _buildBody(
    DashboardProvider provider,
    BusinessMetrics metrics,
    Color brandOrange,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMsg = provider.error;
    if (errorMsg != null) {
      return ErrorStateWidget(
        title: 'Could not load dashboard',
        subtitle: errorMsg,
        onRetry: () => provider.fetchMetrics(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchMetrics(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRevenueCard(metrics, brandOrange),
            const SizedBox(height: 16),
            _buildTodaysBrief(brandOrange),
            const SizedBox(height: 16),
            _buildTrialSchedule(brandOrange),
            const SizedBox(height: 16),
            _buildOrderStatsGrid(metrics, brandOrange),
            const SizedBox(height: 16),
            _buildCustomerCard(metrics, brandOrange),
            const SizedBox(height: 16),
            _buildGarmentTypesCard(metrics, brandOrange),
            const SizedBox(height: 16),
            _buildWorkerProductivityCard(metrics, brandOrange),
            const SizedBox(height: 16),
            _buildFabricUsageCard(metrics, brandOrange),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(BusinessMetrics metrics, Color brandOrange) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brandOrange, brandOrange.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MONTHLY REVENUE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(metrics.monthlyRevenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                metrics.revenueGrowthPercent >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${metrics.revenueGrowthPercent >= 0 ? '+' : ''}${metrics.revenueGrowthPercent.toStringAsFixed(1)}% vs last month',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Pending: ${fmt.format(metrics.pendingBalanceSum)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatsGrid(BusinessMetrics metrics, Color brandOrange) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORDERS OVERVIEW',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBox('TOTAL', metrics.totalOrders.toString(), Colors.grey),
              _statBox('ACTIVE', metrics.activeOrders.toString(), brandOrange),
              _statBox('DONE', metrics.completedOrders.toString(), Colors.green),
              _statBox('CANCEL', metrics.cancelledOrders.toString(), Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BusinessMetrics metrics, Color brandOrange) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CUSTOMERS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBox('ACTIVE', metrics.activeCustomers.toString(), Colors.blue),
              _statBox('REPEAT', metrics.repeatCustomers.toString(), Colors.teal),
              _statBox('ALTERATIONS', metrics.alterationFrequency.toString(), Colors.deepOrange),
            ],
          ),
          if (metrics.activeCustomers > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(
                value: metrics.repeatCustomers / metrics.activeCustomers,
                backgroundColor: Colors.grey.shade200,
                color: Colors.teal,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          if (metrics.activeCustomers > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${(metrics.repeatCustomers / metrics.activeCustomers * 100).toStringAsFixed(0)}% repeat rate',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGarmentTypesCard(BusinessMetrics metrics, Color brandOrange) {
    if (metrics.topGarmentTypes.isEmpty) return const SizedBox.shrink();
    final total = metrics.topGarmentTypes.values.fold(0, (a, b) => a + b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOP GARMENT TYPES',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ...metrics.topGarmentTypes.entries.map((entry) {
            final pct = total > 0 ? entry.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '${entry.value} (${(pct * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.grey.shade200,
                      color: brandOrange,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWorkerProductivityCard(BusinessMetrics metrics, Color brandOrange) {
    if (metrics.workerProductivity.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WORKER PRODUCTIVITY',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ...metrics.workerProductivity.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: brandOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person_rounded, size: 16, color: brandOrange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: brandOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.value} orders',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: brandOrange,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFabricUsageCard(BusinessMetrics metrics, Color brandOrange) {
    if (metrics.fabricUsage.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FABRIC USAGE',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ...metrics.fabricUsage.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.checkroom_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                  Text(
                    '${entry.value.toStringAsFixed(1)}m',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTodaysBrief(Color brandOrange) {
    final orderProvider = OrderProviderWrapper.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todaysTrials = orderProvider.orders.where((o) {
      if (o.trialDate == null || o.isCancelled || o.status.toLowerCase() == 'delivered') return false;
      final trialDay = DateTime(o.trialDate!.year, o.trialDate!.month, o.trialDate!.day);
      return trialDay.isAtSameMomentAs(today);
    }).length;

    final todaysDeliveries = orderProvider.orders.where((o) {
      if (o.deliveryDate == null || o.isCancelled || o.status.toLowerCase() == 'delivered') return false;
      final deliveryDay = DateTime(o.deliveryDate!.year, o.deliveryDate!.month, o.deliveryDate!.day);
      return deliveryDay.isAtSameMomentAs(today);
    }).length;

    if (todaysTrials == 0 && todaysDeliveries == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.charcoal,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.charcoal.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                "TODAY'S BRIEF",
                style: GoogleFonts.manrope(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _briefItem(
                  icon: Icons.accessibility_new_rounded,
                  count: todaysTrials,
                  label: "Trials",
                  color: Colors.purpleAccent,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white10),
              Expanded(
                child: _briefItem(
                  icon: Icons.local_shipping_rounded,
                  count: todaysDeliveries,
                  label: "Deliveries",
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _briefItem({required IconData icon, required int count, required String label, required Color color}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTrialSchedule(Color brandOrange) {
    final orderProvider = OrderProviderWrapper.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekFromNow = today.add(const Duration(days: 7));

    final trialOrders = orderProvider.orders.where((o) {
      if (o.trialDate == null || o.isCancelled || o.status.toLowerCase() == 'delivered') return false;
      final trialDay = DateTime(o.trialDate!.year, o.trialDate!.month, o.trialDate!.day);
      return (trialDay.isAtSameMomentAs(today) || trialDay.isAfter(today)) && trialDay.isBefore(weekFromNow);
    }).toList();

    trialOrders.sort((a, b) => a.trialDate!.compareTo(b.trialDate!));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'UPCOMING TRIALS (7 DAYS)',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: Colors.grey,
                ),
              ),
              if (trialOrders.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${trialOrders.length}',
                    style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (trialOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No trials scheduled for the next 7 days.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trialOrders.length,
                itemBuilder: (context, index) {
                  final order = trialOrders[index];
                  final trialDay = DateTime(order.trialDate!.year, order.trialDate!.month, order.trialDate!.day);
                  final isToday = trialDay.isAtSameMomentAs(today);

                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.purple.withValues(alpha: 0.05) : DesignSystem.creamBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isToday ? Colors.purple.withValues(alpha: 0.2) : DesignSystem.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(isToday ? 'hh:mm a' : 'MMM dd, EEE').format(order.trialDate!),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: isToday ? Colors.purple : Colors.black87,
                          ),
                        ),
                        if (isToday)
                          Text('TODAY', style: TextStyle(color: Colors.purple, fontSize: 8, fontWeight: FontWeight.w900)),
                        const Spacer(),
                        Text(
                          order.items.isNotEmpty ? order.items.first.productName : 'Order',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        Text(
                          '#${order.orderToken}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
