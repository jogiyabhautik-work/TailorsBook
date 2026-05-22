import 'package:flutter/material.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/provider_wrappers.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/utils/design_system.dart';

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
}
