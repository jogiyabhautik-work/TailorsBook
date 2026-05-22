import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';
import '../../models/customer_model.dart';
import '../../models/worker_model.dart';
import '../../core/utils/design_system.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'worker_assigned_work_detail_screen.dart';

class WorkerAssignedWorkListScreen extends StatefulWidget {
  const WorkerAssignedWorkListScreen({super.key});

  @override
  State<WorkerAssignedWorkListScreen> createState() => _WorkerAssignedWorkListScreenState();
}

class _WorkerAssignedWorkListScreenState extends State<WorkerAssignedWorkListScreen> {
  @override
  Widget build(BuildContext context) {
    final orderProvider = OrderProviderWrapper.of(context);
    final workerProvider = WorkerProviderWrapper.of(context);

    // Filter orders that are assigned to workers
    final assignedOrders = orderProvider.orders.where((order) {
      return order.assignedWorkerId != null && order.assignedWorkerId!.isNotEmpty && order.workMode == 'worker_assigned';
    }).toList();

    // Further filter to show only orders that are waiting to be received (exclude received)
    final pendingOrders = assignedOrders.where((order) {
      return order.workerAssignmentStatus == 'assigned' ||
          order.workerAssignmentStatus == 'in_progress';
    }).toList();

    // Sort by assigned date (newest first)
    pendingOrders.sort((a, b) => b.lastModifiedAt?.compareTo(a.lastModifiedAt ?? DateTime.now()) ?? 0);

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
        title: Text('Assigned Work', style: DesignSystem.pageTitle),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await orderProvider.fetchOrders();
          await workerProvider.fetchWorkers();
        },
        color: DesignSystem.primaryContainer,
        child: pendingOrders.isEmpty
            ? Center(
              child: Padding(
                padding: EdgeInsets.all(R.cardPadding(context)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignSystem.s16),
                      decoration: BoxDecoration(
                        color: DesignSystem.info.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.assignment_turned_in_rounded, size: 40, color: DesignSystem.info),
                    ),
                    const SizedBox(height: DesignSystem.md),
                    Text('No assigned work', style: DesignSystem.cardTitle),
                    const SizedBox(height: DesignSystem.s4),
                    Text('Work assigned to workers will appear here', style: DesignSystem.caption, textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context), vertical: DesignSystem.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${pendingOrders.length} ${pendingOrders.length == 1 ? 'Order' : 'Orders'} in Progress', style: DesignSystem.sectionTitle),
                            const SizedBox(height: DesignSystem.s4),
                            Text('Waiting for workers to complete', style: DesignSystem.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = pendingOrders[index];
                        WorkerModel? worker;
                        try {
                          worker = workerProvider.workers.firstWhere(
                            (w) => w.id == order.assignedWorkerId,
                          );
                        } catch (_) {
                          worker = null;
                        }

                        if (worker == null) return const SizedBox.shrink();

                        return Padding(
                          padding: EdgeInsets.only(bottom: DesignSystem.md),
                          child: _assignedWorkCard(context, order, worker),
                        );
                      },
                      childCount: pendingOrders.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: effectiveBottomPadding(context) + 16),
                ),
               ],
             ),
           ),
         );
       }

  Widget _assignedWorkCard(BuildContext context, OrderModel order, WorkerModel worker) {
    Customer? customer;
    try {
      customer = CustomerProviderWrapper.of(context).customers.firstWhere(
        (c) => c.id == order.customerId,
      );
    } catch (_) {
      customer = null;
    }

    final isReceived = order.workerAssignmentStatus == 'received_from_worker';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerAssignedWorkDetailScreen(order: order, worker: worker),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: DesignSystem.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
          border: Border.all(color: isReceived ? DesignSystem.tertiaryContainer.withValues(alpha: 0.3) : DesignSystem.outlineVariant),
          boxShadow: DesignSystem.cardShadow,
        ),
        child: Padding(
          padding: EdgeInsets.all(R.cardPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order token and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${order.orderToken}', style: DesignSystem.cardTitle),
                      const SizedBox(height: DesignSystem.s4),
                      Text(
                        customer != null ? customer.name : 'Unknown Customer',
                        style: DesignSystem.caption,
                      ),
                    ],
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.s8, vertical: DesignSystem.s4),
                    decoration: BoxDecoration(
                      color: isReceived ? DesignSystem.tertiaryContainer.withValues(alpha: 0.1) : DesignSystem.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
                      border: Border.all(
                        color: isReceived ? DesignSystem.tertiaryContainer.withValues(alpha: 0.3) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isReceived ? Icons.check_circle_rounded : Icons.work_rounded,
                          size: 14,
                          color: isReceived ? DesignSystem.tertiaryContainer : DesignSystem.info,
                        ),
                        const SizedBox(width: DesignSystem.s4),
                        Text(
                          isReceived ? 'Received' : 'With Worker',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isReceived ? DesignSystem.tertiaryContainer : DesignSystem.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: DesignSystem.md),

              // Worker info
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: DesignSystem.info.withValues(alpha: 0.1),
                    child: Text(
                      worker.name[0].toUpperCase(),
                      style: GoogleFonts.manrope(
                        color: DesignSystem.info,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignSystem.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assigned to', style: DesignSystem.caption),
                        Text(worker.name, style: DesignSystem.sectionTitle),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: DesignSystem.md),

              // Products and Worker Earnings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display worker assigned products instead of order.items.length
                        ...WorkerProviderWrapper.of(context).assignmentsForOrder(order.id)
                            .where((a) => a.workerId == worker.id)
                            .map((a) => Padding(
                                  padding: const EdgeInsets.only(bottom: DesignSystem.s4),
                                  child: Text(
                                    '${a.quantity}x ${a.productName.isNotEmpty ? a.productName : "Item"}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: DesignSystem.primaryContainer,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                        if (WorkerProviderWrapper.of(context).assignmentsForOrder(order.id).where((a) => a.workerId == worker.id).isEmpty)
                          Text(
                            'No assigned products',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: DesignSystem.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.s8, vertical: DesignSystem.s4),
                        decoration: BoxDecoration(
                          color: DesignSystem.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
                        ),
                        child: Text(
                          DateFormat('MMM dd').format(order.createdAt),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: DesignSystem.warning,
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignSystem.s8),
                      Text(
                        '₹${WorkerProviderWrapper.of(context).assignmentsForOrder(order.id).where((a) => a.workerId == worker.id).fold(0.0, (sum, a) => sum + a.subtotal).toStringAsFixed(0)}',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: DesignSystem.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
