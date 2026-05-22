import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';
import '../../models/customer_model.dart';
import '../../models/worker_model.dart';
import '../../core/utils/design_system.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../core/utils/responsive.dart';
import 'package:intl/intl.dart';
import '../order/order_detail_screen.dart';

class WorkerAssignedWorkDetailScreen extends StatefulWidget {
  final OrderModel order;
  final WorkerModel worker;

  const WorkerAssignedWorkDetailScreen({
    super.key,
    required this.order,
    required this.worker,
  });

  @override
  State<WorkerAssignedWorkDetailScreen> createState() => _WorkerAssignedWorkDetailScreenState();
}

class _WorkerAssignedWorkDetailScreenState extends State<WorkerAssignedWorkDetailScreen> {
  late OrderModel _currentOrder;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  Future<void> _markAsReceived() async {
    if (_isProcessing) return;

    // Prevent double-receiving
    if (_currentOrder.workerAssignmentStatus == 'received_from_worker') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work already received from worker'),
          backgroundColor: DesignSystem.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final orderProvider = OrderProviderWrapper.of(context);

      // Use the provider method which includes validation
      final success = await orderProvider.markWorkReceivedFromWorker(_currentOrder.id);

      if (!success || !context.mounted) return;

      // Get the updated order from provider
      final updatedOrder = orderProvider.orders.firstWhere(
        (o) => o.id == _currentOrder.id,
        orElse: () => _currentOrder,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Worker has returned the work. You can now continue the order process.'),
          backgroundColor: DesignSystem.tertiaryContainer,
          duration: const Duration(seconds: 2),
        ),
      );

      // Wait a moment then navigate back to order detail
      await Future.delayed(const Duration(milliseconds: 500));
      if (!context.mounted) return;

      Navigator.pop(context);

      // Fetch customer before navigating
      final customerProvider = CustomerProviderWrapper.of(context, listen: false);
      final customer = customerProvider.customers.firstWhere(
        (c) => c.id == updatedOrder.customerId,
        orElse: () => Customer(id: '', name: 'Unknown', phone: '', address: ''),
      );

      // Navigate to order detail
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: updatedOrder, customer: customer),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: DesignSystem.error,
        ),
      );
    } finally {
      if (context.mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = CustomerProviderWrapper.of(context);
    final workerProvider = WorkerProviderWrapper.of(context);
    Customer? customer;
    try {
      customer = customerProvider.customers.firstWhere(
        (c) => c.id == _currentOrder.customerId,
      );
    } catch (_) {
      customer = null;
    }

    final workerAssignments = workerProvider.assignmentsForOrder(_currentOrder.id)
        .where((a) => a.workerId == widget.worker.id)
        .toList();

    // Calculate total worker earning
    double totalWorkerEarning = workerAssignments.fold(0.0, (sum, a) => sum + a.subtotal);

    return Scaffold(
      backgroundColor: DesignSystem.surface,
      appBar: AppBar(
        backgroundColor: DesignSystem.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: DesignSystem.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Assigned Work Detail', style: DesignSystem.pageTitle),
        centerTitle: false,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context), vertical: DesignSystem.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Header Card
                        Container(
                          decoration: DesignSystem.card,
                          padding: EdgeInsets.all(R.cardPadding(context)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Order #${_currentOrder.orderToken}', style: DesignSystem.cardTitle),
                                        const SizedBox(height: DesignSystem.s4),
                                        Text(
                                          'Created ${DateFormat('MMM dd, yyyy').format(_currentOrder.createdAt)}',
                                          style: DesignSystem.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.s8, vertical: DesignSystem.s4),
                                    decoration: BoxDecoration(
                                      color: _currentOrder.workerAssignmentStatus == 'received_from_worker'
                                          ? DesignSystem.tertiaryContainer.withValues(alpha: 0.1)
                                          : DesignSystem.info.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
                                    ),
                                    child: Text(
                                      _currentOrder.workerAssignmentStatus == 'received_from_worker' ? 'Received' : 'With Worker',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _currentOrder.workerAssignmentStatus == 'received_from_worker'
                                            ? DesignSystem.tertiaryContainer
                                            : DesignSystem.info,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: DesignSystem.md),

                        // Customer Card
                        if (customer != null)
                          Container(
                            decoration: DesignSystem.card,
                            padding: EdgeInsets.all(R.cardPadding(context)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Customer', style: DesignSystem.sectionTitle),
                                const SizedBox(height: DesignSystem.s8),
                                Text(customer.name, style: DesignSystem.cardTitle),
                                if (customer.phone.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: DesignSystem.s4),
                                    child: Text(customer.phone, style: DesignSystem.caption),
                                  ),
                              ],
                            ),
                          ),

                        const SizedBox(height: DesignSystem.md),

                        // Worker Card
                        Container(
                          decoration: DesignSystem.card,
                          padding: EdgeInsets.all(R.cardPadding(context)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Assigned Worker', style: DesignSystem.sectionTitle),
                              const SizedBox(height: DesignSystem.s8),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: DesignSystem.info.withValues(alpha: 0.1),
                                    child: Text(widget.worker.name[0].toUpperCase(),
                                        style: GoogleFonts.manrope(
                                          color: DesignSystem.info,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        )),
                                  ),
                                  const SizedBox(width: DesignSystem.s12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(widget.worker.name, style: DesignSystem.cardTitle),
                                        const SizedBox(height: DesignSystem.s2),
                                        Text(
                                          widget.worker.salaryType == SalaryType.piece_rate ? 'Piece Rate' : 'Monthly',
                                          style: DesignSystem.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: DesignSystem.md),

                        // Products & Pricing
                        Container(
                          decoration: DesignSystem.card,
                          padding: EdgeInsets.all(R.cardPadding(context)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Assigned Products', style: DesignSystem.sectionTitle),
                              const SizedBox(height: DesignSystem.s12),
                              ...workerAssignments.asMap().entries.map((entry) {
                                final assignment = entry.value;
                                final index = entry.key;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: index < workerAssignments.length - 1 ? DesignSystem.s12 : 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(assignment.productName, style: DesignSystem.sectionTitle),
                                                const SizedBox(height: DesignSystem.s4),
                                                Text('Qty: ${assignment.quantity} × ₹${assignment.workerRate.toStringAsFixed(0)}', style: DesignSystem.caption),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '₹${assignment.subtotal.toStringAsFixed(0)}',
                                            style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: DesignSystem.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (index < workerAssignments.length - 1)
                                        Padding(
                                          padding: const EdgeInsets.only(top: DesignSystem.s12),
                                          child: Divider(color: DesignSystem.outlineVariant),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: DesignSystem.s12),
                              Divider(color: DesignSystem.outlineVariant),
                              const SizedBox(height: DesignSystem.s12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Worker Earning', style: DesignSystem.sectionTitle),
                                  Text(
                                    '₹${totalWorkerEarning.toStringAsFixed(0)}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: DesignSystem.primaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: DesignSystem.md),

                        // Timeline
                        Container(
                          decoration: DesignSystem.card,
                          padding: EdgeInsets.all(R.cardPadding(context)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Timeline', style: DesignSystem.sectionTitle),
                              const SizedBox(height: DesignSystem.s12),
                              _timelineItem(
                                'Assigned',
                                DateFormat('MMM dd, yyyy • hh:mm a').format(
                                  _currentOrder.createdAt,
                                ),
                                DesignSystem.info,
                              ),
                              const SizedBox(height: DesignSystem.s12),
                              if (_currentOrder.workerReceivedAt != null)
                                _timelineItem(
                                  'Received',
                                  DateFormat('MMM dd, yyyy • hh:mm a').format(
                                    _currentOrder.workerReceivedAt!,
                                  ),
                                  DesignSystem.tertiaryContainer,
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: DesignSystem.xl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _currentOrder.workerAssignmentStatus != 'received_from_worker'
          ? Container(
              padding: EdgeInsets.all(R.cardPadding(context)),
              decoration: BoxDecoration(
                color: DesignSystem.surfaceContainerLowest,
                border: Border(
                  top: BorderSide(color: DesignSystem.outlineVariant),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _markAsReceived,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignSystem.tertiaryContainer,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusBtn),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Received Order From Worker',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                  ),
                  const SizedBox(height: DesignSystem.md),
                  OutlinedButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: DesignSystem.outlineVariant),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusBtn),
                      ),
                    ),
                    child: Text(
                      'Not Received Yet',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: DesignSystem.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: EdgeInsets.all(R.cardPadding(context)),
              decoration: BoxDecoration(
                color: DesignSystem.tertiaryContainer.withValues(alpha: 0.1),
                border: Border(
                  top: BorderSide(color: DesignSystem.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: DesignSystem.tertiaryContainer),
                  const SizedBox(width: DesignSystem.s12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Work Received', style: DesignSystem.sectionTitle),
                        Text(
                          DateFormat('MMM dd, yyyy').format(_currentOrder.workerReceivedAt!),
                          style: DesignSystem.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _timelineItem(String label, String time, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: DesignSystem.s12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: DesignSystem.sectionTitle),
            const SizedBox(height: DesignSystem.s4),
            Text(time, style: DesignSystem.caption),
          ],
        ),
      ],
    );
  }
}
