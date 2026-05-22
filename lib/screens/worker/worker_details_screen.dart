import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/worker_model.dart';
import '../../providers/worker_provider.dart';

import 'add_worker_screen.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../core/utils/tailor_flow_helper.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/responsive.dart';


import '../../widgets/dialogs/add_work_log_dialog.dart';
import '../../widgets/dialogs/record_worker_payment_dialog.dart';
import 'worker_assigned_work_detail_screen.dart';
import '../../models/customer_model.dart';
import '../order/order_detail_screen.dart';

class WorkerDetailsScreen extends StatefulWidget {
  final WorkerModel worker;
  const WorkerDetailsScreen({super.key, required this.worker});

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<WorkLog> _workLogs = [];
  List<WorkerPayment> _payments = [];
  List<Map<String, dynamic>> _activityLog = [];
  List<Map<String, dynamic>> _workerEarnings = [];
  WorkerPerformanceMetrics? _performance;
  bool _isLoadingData = true;
  bool _isProcessing = false;
  bool _isDialogOpening = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  WorkerModel get _currentWorker {
    final wp = WorkerProviderWrapper.of(context, listen: false);
    return wp.workers.firstWhere(
      (w) => w.id == widget.worker.id,
      orElse: () => widget.worker,
    );
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingData = true);

    try {
      final wp = WorkerProviderWrapper.of(context, listen: false);
      final op = OrderProviderWrapper.of(context, listen: false);

      await wp.fetchAssignments();
      final results = await Future.wait([
        wp.fetchWorkLogs(widget.worker.id),
        wp.fetchPayments(widget.worker.id),
        wp.fetchWorkerActivity(widget.worker.id),
        wp.fetchWorkerPerformance(widget.worker.id, op.orders),
        wp.fetchWorkerEarnings(widget.worker.id),
      ]).timeout(const Duration(seconds: 15));

      if (context.mounted) {
        setState(() {
          _workLogs = results[0] as List<WorkLog>;
          _payments = results[1] as List<WorkerPayment>;
          _activityLog = results[2] as List<Map<String, dynamic>>;
          _performance = results[3] as WorkerPerformanceMetrics;
          _workerEarnings = results[4] as List<Map<String, dynamic>>;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading worker details: $e');
      if (context.mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load some data. Please check your connection.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _workLogEarnings =>
      _workLogs.fold(0.0, (sum, log) => sum + log.totalAmount);

  double get _assignmentEarnings =>
      _workerEarnings.fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));

  double get _totalEarnings {
    final worker = _currentWorker;
    if (worker.salaryType == SalaryType.monthly) {
      return worker.monthlyRate;
    }
    return _workLogEarnings + _assignmentEarnings;
  }

  double get _totalAdvances {
    return _payments.where((p) => p.paymentType == 'advance').fold(0.0, (sum, p) => sum + p.amount);
  }

  double get _totalSalariesPaid {
    return _payments.where((p) => p.paymentType == 'salary').fold(0.0, (sum, p) => sum + p.amount);
  }

  double get _pendingBalance => _totalEarnings - _totalAdvances - _totalSalariesPaid;

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    // Register build-time dependencies so widget rebuilds on provider changes
    WorkerProviderWrapper.of(context);
    OrderProviderWrapper.of(context);
    final worker = _currentWorker;

    return Scaffold(
      backgroundColor: DesignSystem.surface,
      appBar: AppBar(
        title: Text(worker.name, style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: false,
        backgroundColor: DesignSystem.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddWorkerScreen(workerToEdit: worker)),
              ).then((_) => _loadData(silent: true));
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            _buildSummaryHeader(worker, DesignSystem.primaryContainer),
            Container(
              color: DesignSystem.surfaceContainerLowest,
              child: TabBar(
                controller: _tabController,
                labelColor: DesignSystem.primaryContainer,
                unselectedLabelColor: DesignSystem.secondary,
                indicatorColor: DesignSystem.primaryContainer,
                labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 12),
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                tabs: const [
                  Tab(text: 'Work Logs'),
                  Tab(text: 'Payments'),
                  Tab(text: 'Assigned'),
                  Tab(text: 'Performance'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWorkLogsList(),
                  _buildPaymentsList(),
                  _buildAssignedWorkList(brandOrange),
                  _buildPerformanceTab(brandOrange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(WorkerModel worker, Color brandOrange) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.md),
      decoration: const BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(DesignSystem.radiusXl), bottomRight: Radius.circular(DesignSystem.radiusXl)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSummaryItem('Earnings', '₹${_totalEarnings.toStringAsFixed(0)}', DesignSystem.info)),
              Expanded(child: _buildSummaryItem('Advances', '₹${_totalAdvances.toStringAsFixed(0)}', DesignSystem.warning)),
              Expanded(child: _buildSummaryItem('Pending', '₹${_pendingBalance.toStringAsFixed(0)}', DesignSystem.error)),
            ],
          ),
          if (_performance != null) ...[
            const SizedBox(height: DesignSystem.sm),
            Row(
              children: [
                Expanded(child: _smallStat('${_performance?.completedOrders ?? 0}', 'Completed')),
                Expanded(child: _smallStat('${_performance?.activeOrders ?? 0}', 'Active')),
                Expanded(child: _smallStat('${_performance?.delayedOrders ?? 0}', 'Delayed')),
                Expanded(child: _smallStat('${(_performance?.avgCompletionDays ?? 0).toStringAsFixed(1)}d', 'Avg Time')),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showAddWorkLogDialog(context, brandOrange),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignSystem.primary.withValues(alpha: 0.1),
                    foregroundColor: DesignSystem.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: const FittedBox(child: Text('Add Work Log', style: TextStyle(fontWeight: FontWeight.bold))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showAddPaymentDialog(context, brandOrange),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignSystem.success.withValues(alpha: 0.1),
                    foregroundColor: DesignSystem.success,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: const FittedBox(child: Text('Add Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallStat(String value, String label) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: GoogleFonts.manrope(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        Text(label, style: GoogleFonts.manrope(fontSize: 10, color: DesignSystem.secondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 12, color: DesignSystem.secondary, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        const SizedBox(height: DesignSystem.s8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ),
      ],
    );
  }

  // ——— Performance Tab ———

  Widget _buildPerformanceTab(Color orange) {
    if (_performance == null) return _buildEmptyTab('Loading performance data...');

    return SingleChildScrollView(
      padding: EdgeInsets.all(R.pagePadding(context)),
      child: ConstrainedContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCard('Performance Metrics', [
              _metricRow('Completed Orders', '${_performance!.completedOrders}', DesignSystem.tertiaryContainer, Icons.check_circle_rounded),
              _metricRow('Active Orders', '${_performance!.activeOrders}', DesignSystem.info, Icons.work_rounded),
              _metricRow('Delayed Orders', '${_performance!.delayedOrders}', DesignSystem.error, Icons.warning_rounded),
              _metricRow('Avg Completion', '${_performance!.avgCompletionDays.toStringAsFixed(1)} days', DesignSystem.primaryContainer, Icons.timer_rounded),
              _metricRow('Alteration Count', '${_performance!.alterationCount}', DesignSystem.warning, Icons.tune_rounded),
            ]),
            SizedBox(height: R.gap(context)),
            _buildMetricCard('Earnings Summary', [
              _metricRow('Total Earnings', '₹${_performance!.totalEarnings.toStringAsFixed(0)}', DesignSystem.info, Icons.account_balance_wallet_rounded),
              _metricRow('Commission', '₹${_performance!.totalCommission.toStringAsFixed(0)}', DesignSystem.tertiaryContainer, Icons.trending_up_rounded),
            ]),
            SizedBox(height: R.value(context, regular: 16, smallPhone: 12)),
            _buildActivityTimeline(),
            SizedBox(height: R.value(context, regular: 100, smallPhone: 90)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(title, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w900, color: DesignSystem.secondary, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)),
        ],
      ),
    );
  }

  // ——— Activity Timeline ———

  Widget _buildActivityTimeline() {
    if (_activityLog.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACTIVITY TIMELINE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: DesignSystem.muted, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...List.generate(_activityLog.length > 10 ? 10 : _activityLog.length, (i) {
            final entry = _activityLog[i];
            final type = entry['activity_type'] as String? ?? '';
            final desc = entry['description'] as String? ?? '';
            final date = entry['created_at'] != null ? DateTime.tryParse(entry['created_at'].toString()) : null;

            IconData icon;
            Color color;
            switch (type) {
              case 'assigned':
                icon = Icons.person_add_rounded;
                color = DesignSystem.primary;
                break;
              case 'reassigned':
                icon = Icons.swap_horiz_rounded;
                color = DesignSystem.primary;
                break;
              case 'completed':
                icon = Icons.check_circle_rounded;
                color = DesignSystem.success;
                break;
              default:
                icon = Icons.circle_rounded;
                color = DesignSystem.muted;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(desc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        if (date != null)
                          Text(DateFormat('dd MMM, hh:mm a').format(date), style: TextStyle(fontSize: 10, color: DesignSystem.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (_activityLog.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('+ ${_activityLog.length - 10} more entries', style: TextStyle(fontSize: 11, color: DesignSystem.muted)),
            ),
        ],
      ),
    );
  }

  // ——— Work Logs Tab ———

  Widget _buildWorkLogsList() {
    if (_workLogs.isEmpty) return _buildEmptyTab('No work logs added yet.');
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(R.pagePadding(context), R.gap(context), R.pagePadding(context), R.value(context, regular: 100, smallPhone: 90)),
      itemCount: _workLogs.length,
      itemBuilder: (context, index) {
        final log = _workLogs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: DesignSystem.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: DesignSystem.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.architecture_rounded, color: DesignSystem.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${log.quantity} units x ₹${log.ratePerPiece}', style: TextStyle(color: DesignSystem.muted, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${log.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(DateFormat('MMM dd').format(log.workDate), style: const TextStyle(color: DesignSystem.muted, fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ——— Payments Tab ———

  Widget _buildPaymentsList() {
    if (_payments.isEmpty) return _buildEmptyTab('No payments recorded yet.');
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(R.pagePadding(context), R.gap(context), R.pagePadding(context), R.value(context, regular: 100, smallPhone: 90)),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        final isAdvance = payment.paymentType == 'advance';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: DesignSystem.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: isAdvance ? DesignSystem.primary.withValues(alpha: 0.1) : DesignSystem.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(isAdvance ? Icons.money_off_rounded : Icons.payments_rounded,
                    color: isAdvance ? DesignSystem.primary : DesignSystem.success),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isAdvance ? 'Advance Payout' : 'Salary Payment', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (payment.notes != null) Text(payment.notes!, style: TextStyle(color: DesignSystem.muted, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${payment.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(DateFormat('MMM dd').format(payment.paymentDate), style: const TextStyle(color: DesignSystem.muted, fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ——— Assigned Work Tab ———

  Widget _buildAssignedWorkList(Color orange) {
    final orderProvider = OrderProviderWrapper.of(context);
    final workerProvider = WorkerProviderWrapper.of(context);
    final assigned = orderProvider.ordersForWorker(widget.worker.id)
        .where((o) => TailorFlowHelper.normalize(o.status) != 'delivered')
        .toList();

    if (assigned.isEmpty) return _buildEmptyTab('No work assigned to this worker yet.');

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(R.pagePadding(context), R.gap(context), R.pagePadding(context), R.value(context, regular: 100, smallPhone: 90)),
      itemCount: assigned.length,
      itemBuilder: (context, index) {
        final order = assigned[index];
        final isDelayed = order.deliveryDate != null && order.deliveryDate!.isBefore(DateTime.now());
        final orderAssignments = workerProvider.assignmentsForOrder(order.id)
            .where((a) => a.workerId == widget.worker.id)
            .toList();
        final totalEarnings = orderAssignments.fold(0.0, (sum, a) => sum + a.subtotal);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: DesignSystem.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDelayed ? DesignSystem.error.withValues(alpha: 0.2) : const Color(0xFFEEEEEE)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkerAssignedWorkDetailScreen(order: order, worker: widget.worker),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ORDER #${order.orderToken}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                  Row(
                    children: [
                      if (isDelayed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(color: DesignSystem.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: const Text('DELAYED', style: TextStyle(color: DesignSystem.error, fontSize: 8, fontWeight: FontWeight.w900)),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          TailorFlowHelper.getStatusLabel(order.status).toUpperCase(),
                          style: TextStyle(color: orange, fontWeight: FontWeight.w900, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),
              // Product-wise pricing
              ...orderAssignments.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: DesignSystem.surface, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.checkroom_rounded, size: 16, color: DesignSystem.muted),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.productName.isNotEmpty ? a.productName : 'Item',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (a.quantity > 0)
                            Text(
                              'Qty: ${a.quantity}',
                              style: TextStyle(color: DesignSystem.muted, fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${a.workerRate.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: DesignSystem.charcoal),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '×${a.quantity}',
                      style: TextStyle(color: DesignSystem.muted, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${a.subtotal.toStringAsFixed(0)}',
                        style: TextStyle(color: orange, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
              if (orderAssignments.isEmpty && order.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: DesignSystem.surface, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.checkroom_rounded, size: 16, color: DesignSystem.muted),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.items.map((i) => '${i.quantity}x ${i.productName}').join(', '),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Worker pricing not set',
                              style: TextStyle(color: DesignSystem.error, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (order.deliveryDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: isDelayed ? DesignSystem.error : DesignSystem.muted),
                      const SizedBox(width: 6),
                      Text(
                        'Due: ${DateFormat('dd MMM, yyyy').format(order.deliveryDate!)}',
                        style: TextStyle(color: isDelayed ? DesignSystem.error : DesignSystem.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              if (totalEarnings > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: DesignSystem.success.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DesignSystem.success.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Worker Earnings',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DesignSystem.success),
                      ),
                      Text(
                        '₹${totalEarnings.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: DesignSystem.success),
                      ),
                    ],
                  ),
                ),
              // Mark work completed button
              if (orderAssignments.any((a) => a.status == 'assigned' || a.status == 'in_progress'))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Prevent double-tap
                        if (_isProcessing) return;
                        setState(() => _isProcessing = true);
                        try {
                          for (final a in orderAssignments) {
                            await workerProvider.updateAssignmentStatus(a.id, 'completed');
                          }
                          // Also update the order's workerAssignmentStatus
                          final orderProvider = OrderProviderWrapper.of(context);
                          for (final a in orderAssignments) {
                            final order = orderProvider.orders.where((o) => o.id == a.orderId).firstOrNull;
                            if (order != null && order.workerAssignmentStatus != 'received_from_worker') {
                              await orderProvider.markWorkReceivedFromWorker(order.id);
                            }
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Worker has returned the work. You can now continue the order process.')),
                            );
                            _loadData(silent: true);
                            
                            // Fetch customer before navigating
                            final customerProvider = CustomerProviderWrapper.of(context, listen: false);
                            final customer = customerProvider.customers.firstWhere(
                              (c) => c.id == order.customerId,
                              orElse: () => Customer(id: '', name: 'Unknown', phone: '', address: ''),
                            );
                            
                            // Navigate to order detail
                            final currentOrderProvider = OrderProviderWrapper.of(context, listen: false);
                            final updatedOrder = currentOrderProvider.orders.firstWhere(
                              (o) => o.id == order.id,
                              orElse: () => order,
                            );
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(order: updatedOrder, customer: customer),
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) setState(() => _isProcessing = false);
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text('MARK WORK COMPLETED', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DesignSystem.success,
                        side: BorderSide(color: DesignSystem.success.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
      },
    );
  }

  Widget _buildEmptyTab(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: DesignSystem.outlineVariant),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: DesignSystem.muted, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Add Work Log Dialog ──
  void _showAddWorkLogDialog(BuildContext context, Color orange) {
    if (_isDialogOpening) return;
    _isDialogOpening = true;
    showDialog(
      context: context,
      builder: (ctx) => AddWorkLogDialog(
        workerId: _currentWorker.id,
        onSuccess: () => _loadData(silent: true),
      ),
    ).whenComplete(() => _isDialogOpening = false);
  }

  // ── Add Payment Dialog ──
  void _showAddPaymentDialog(BuildContext context, Color orange) {
    if (_isDialogOpening) return;
    _isDialogOpening = true;
    showDialog(
      context: context,
      builder: (ctx) => RecordWorkerPaymentDialog(
        workerId: _currentWorker.id,
        onSuccess: () => _loadData(silent: true),
      ),
    ).whenComplete(() => _isDialogOpening = false);
  }
}
