import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../models/customer_model.dart';
import '../../models/worker_model.dart';
import '../../models/payment_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/fabric_provider.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/tailor_flow_helper.dart';
import 'alteration_notes_screen.dart';
import '../../core/utils/invoice_helper.dart';
import 'item_measurement_selection_screen.dart';
import 'view_measurement_screen.dart';
import '../../core/services/notification_service.dart';
import '../../widgets/dialogs/worker_pricing_dialog.dart';
import '../../main.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  final Customer customer;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.customer,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String? _updatingItemId;
  bool _isGeneratingPdf = false;
  bool _workersInitialized = false;
  int _workerDropdownKeyCounter = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_workersInitialized) {
      _workersInitialized = true;
      final workerProvider = WorkerProviderWrapper.of(context, listen: false);
      if (workerProvider.workers.isEmpty && !workerProvider.isLoading) {
        workerProvider.fetchWorkers();
      }
      final orderProvider = OrderProviderWrapper.of(context);
      if (orderProvider.orders.isEmpty && !orderProvider.isLoading) {
        orderProvider.fetchOrders();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Customer _resolveCustomer(OrderModel order) {
    try {
      final customerProvider = CustomerProviderWrapper.of(context);
      return customerProvider.customers.firstWhere(
        (c) => c.id == order.customerId,
        orElse: () => widget.customer,
      );
    } catch (_) {
      return widget.customer;
    }
  }

  void _showDeliveryNotification(String customerName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Order for $customerName has been marked as DELIVERED!',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _generateAndSharePdf(OrderModel order, Customer customer) async {
    setState(() => _isGeneratingPdf = true);
    try {
      await InvoiceHelper.generateAndShareInvoice(
        order: order,
        customer: customer,
      );
      if (context.mounted) {
        showGlobalSnackBar('Invoice shared successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        showGlobalSnackBar('Error sharing invoice: $e', isError: true);
      }
    } finally {
      if (context.mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final orderProvider = OrderProviderWrapper.of(context);
      final workerProvider = WorkerProviderWrapper.of(context);

      final currentOrder = orderProvider.orders.firstWhere(
        (o) => o.id == widget.order.id,
        orElse: () => widget.order,
      );

      final Customer customer = _resolveCustomer(currentOrder);
      final brandOrange = Theme.of(context).colorScheme.primary;
      final bool isInitialLoading =
          orderProvider.isLoading && orderProvider.orders.isEmpty;

      final assignedWorker = (currentOrder.assignedWorkerId != null &&
              currentOrder.assignedWorkerId!.trim().isNotEmpty)
          ? workerProvider.workers.firstWhere(
              (w) => w.id == currentOrder.assignedWorkerId,
              orElse: () => WorkerModel(
                id: currentOrder.assignedWorkerId!,
                tailorId: '',
                name: 'Worker Not Found',
                salaryType: SalaryType.monthly,
                joiningDate: DateTime.now(),
                createdAt: DateTime.now(),
              ),
            )
          : null;

      final String? dropdownWorkerValue = assignedWorker != null &&
              (workerProvider.activeWorkers
                      .any((w) => w.id == assignedWorker.id) ||
                  workerProvider.workers.any((w) => w.id == assignedWorker.id))
          ? assignedWorker.id
          : null;

      return Scaffold(
        backgroundColor: DesignSystem.creamBg,
        appBar: AppBar(
          title: const Text(
            'Order Details',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            if (isInitialLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              _isGeneratingPdf
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.share_rounded,
                          color: Colors.orange),
                      onPressed: () =>
                          _generateAndSharePdf(currentOrder, customer),
                      tooltip: 'Share Invoice',
                    ),
            if (!isInitialLoading)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red),
                onPressed: () async {
                  final status = currentOrder.status.toLowerCase();
                  if (status == 'delivered' || status == 'cancelled') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Delivered or cancelled orders cannot be deleted.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Order?'),
                      content: const Text(
                          'This will remove the order, its items, and its payments.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('DELETE',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (loadingCtx) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    final success =
                        await orderProvider.deleteOrder(currentOrder.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      if (success) {
                        await orderProvider.fetchOrders();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Order deleted successfully.'),
                                backgroundColor: Colors.green),
                          );
                          Navigator.pop(context);
                        }
                      }
                    }
                  }
                },
                tooltip: 'Delete Order',
              ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: brandOrange,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),

              if (currentOrder.deliveryDate != null)
                _buildUrgencyBanner(currentOrder.deliveryDate!, brandOrange),

              _buildPendingBalanceBanner(currentOrder.pendingBalance),

              const SizedBox(height: 16),

              if (!currentOrder.hasAllMeasurements &&
                  currentOrder.status.toLowerCase() == 'pending')
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.straighten_rounded,
                            color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Measurements Missing',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.red.shade900,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${currentOrder.missingMeasurementsCount} items need measurements before stitching can start.',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Customer Details ──
              _buildSection(
                title: 'Customer Details',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: brandOrange.withValues(alpha: 0.1),
                      child: Text(
                        customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: brandOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            customer.phone,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (customer.address.isNotEmpty)
                            Text(
                              customer.address,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => launchUrl(
                            Uri.parse('tel:${customer.phone}'),
                          ),
                          icon: const Icon(
                            Icons.call_rounded,
                            color: Colors.green,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.green.withValues(alpha: 0.1),
                          ),
                          tooltip: 'Call Customer',
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          onPressed: () {
                            final message =
                                'Hello ${customer.name}, this is regarding your order #${currentOrder.orderToken} from TailorsBook.';
                            final encodedMessage =
                                Uri.encodeComponent(message);
                            launchUrl(
                              Uri.parse(
                                'https://wa.me/${customer.phone.replaceAll(RegExp(r'\D'), '')}?text=$encodedMessage',
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.message_rounded,
                            color: Colors.teal,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.teal.withValues(alpha: 0.1),
                          ),
                          tooltip: 'WhatsApp',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Items & Stitching Progress ──
              _buildSection(
                title: 'Items & Stitching Progress',
                child: Column(
                  children: [
                    if (currentOrder.workerAssignmentStatus == 'received_from_worker')
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Worker has returned the work. Continue Trial, Alteration, or Ready process.',
                                style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    currentOrder.items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No items in this order',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: currentOrder.items
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return _buildOrderItemTile(
                                context,
                                index + 1,
                                item,
                                currentOrder,
                                orderProvider,
                                brandOrange,
                                _updatingItemId == item.id,
                                customer,
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Payment Summary ──
              _buildSection(
                title: 'Payment Summary',
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Total Amount',
                      '₹${currentOrder.totalPrice.toStringAsFixed(0)}',
                    ),
                    _buildSummaryRow(
                      'Advance Received',
                      '₹${currentOrder.advancePaid.toStringAsFixed(0)}',
                      color: Colors.green,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1),
                    ),
                    _buildSummaryRow(
                      'Pending Balance',
                      '₹${currentOrder.pendingBalance.toStringAsFixed(0)}',
                      isTotal: true,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _paymentStatusChip(currentOrder.paymentStatus),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _showPaymentHistory(
                            context,
                            currentOrder,
                            orderProvider,
                          ),
                          icon: const Icon(Icons.history_rounded, size: 16),
                          label: const Text(
                            'View History',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (currentOrder.pendingBalance > 0.01 &&
                        currentOrder.status.toLowerCase() != 'delivered')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showPaymentDialog(
                            context,
                            currentOrder,
                            orderProvider,
                          ),
                          icon:
                              const Icon(Icons.payments_rounded, size: 18),
                          label: const Text(
                            'RECORD PAYMENT',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Order Schedule ──
              _buildSection(
                title: 'Order Schedule',
                child: Column(
                  children: [
                    _buildTimelineRow(
                      Icons.calendar_month_rounded,
                      'Order Date',
                      DateFormat('dd MMM, yyyy')
                          .format(currentOrder.createdAt),
                    ),
                    if (currentOrder.trialDate != null)
                      _buildTimelineRow(
                        Icons.accessibility_new_rounded,
                        'Fitting/Trial',
                        DateFormat('dd MMM, yyyy')
                            .format(currentOrder.trialDate!),
                        color: Colors.purple,
                      ),
                    if (currentOrder.deliveryDate != null)
                      _buildTimelineRow(
                        Icons.local_shipping_rounded,
                        'Delivery Due',
                        DateFormat('dd MMM, yyyy')
                            .format(currentOrder.deliveryDate!),
                        color: Colors.orange,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Material Tracking ──
              _buildSection(
                title: 'Material Tracking',
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Fabric/Cloth Received?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        currentOrder.fabricReceived
                            ? '✅ Cloth is in the workshop'
                            : '❌ Waiting for customer to bring cloth',
                      ),
                      value: currentOrder.fabricReceived,
                      activeThumbColor: brandOrange,
                      onChanged: (val) async {
                        await orderProvider.updateOrderFabric(
                          currentOrder.id,
                          val,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                val
                                    ? 'Fabric marked as RECEIVED'
                                    : 'Fabric marked as PENDING',
                              ),
                              backgroundColor:
                                  val ? Colors.green : Colors.grey,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      secondary: CircleAvatar(
                        backgroundColor: currentOrder.fabricReceived
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.checkroom_rounded,
                          color: currentOrder.fabricReceived
                              ? Colors.green
                              : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                    const Divider(height: 16),
                    Builder(
                      builder: (context) {
                        FabricProvider? fabricProvider;
                        try {
                          fabricProvider =
                              FabricProviderWrapper.of(context, listen: false);
                        } catch (e) {
                          // Provider not available
                        }
                        if (fabricProvider == null) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: currentOrder.items.map((item) {
                            final info =
                                fabricProvider!.getFabricDisplayInfo(item.id);
                            if (info == null) return const SizedBox.shrink();
                            final sourceRaw =
                                info['source_raw']?.toString() ?? '';
                            final fabricName =
                                info['fabric_name']?.toString();
                            final meters =
                                (info['meters'] as num?)?.toDouble() ?? 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    sourceRaw == 'SHOP'
                                        ? Icons.store_rounded
                                        : Icons.person_rounded,
                                    size: 14,
                                    color: sourceRaw == 'SHOP'
                                        ? Colors.blue.shade400
                                        : Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${item.productName}: ${sourceRaw == 'SHOP' ? '${fabricName ?? 'Shop'} ${meters}m' : 'Customer provided'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Worker Assignment ──
              _buildSection(
                title: 'Worker Assignment',
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: assignedWorker != null
                            ? Colors.blue.withValues(alpha: 0.05)
                            : Colors.orange.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: assignedWorker != null
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: assignedWorker != null
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              assignedWorker != null
                                  ? Icons.engineering_rounded
                                  : Icons.person_off_rounded,
                              color: assignedWorker != null
                                  ? Colors.blue
                                  : Colors.orange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assignedWorker?.name ?? 'No Worker Assigned',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: assignedWorker != null
                                        ? Colors.black87
                                        : Colors.orange.shade800,
                                  ),
                                ),
                                Text(
                                  currentOrder.isSelfStitch
                                      ? 'Disabled (Self-Stitching is active)'
                                      : assignedWorker != null
                                          ? 'Tap dropdown below to change'
                                          : 'Assign a worker to start stitching',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: currentOrder.isSelfStitch
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (assignedWorker != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_workerDropdownKeyCounter),
                      initialValue: dropdownWorkerValue,
                      decoration: InputDecoration(
                        hintText: 'Change or assign a worker',
                        prefixIcon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: DesignSystem.creamBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        ...workerProvider.activeWorkers.map((w) {
                          final realActiveCount =
                              orderProvider.activeOrderCountForWorker(w.id);
                          return DropdownMenuItem(
                            value: w.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(w.name),
                                if (realActiveCount >= 5) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '⚠️$realActiveCount',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        if (workerProvider.workers.length !=
                            workerProvider.activeWorkers.length)
                          const DropdownMenuItem(
                            enabled: false,
                            value: '__inactive_separator__',
                            child: Text(
                              '--- Inactive workers ---',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ...workerProvider.workers
                            .where((w) => !w.isActive)
                            .map((w) {
                          return DropdownMenuItem(
                            enabled: false,
                            value: w.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  w.name,
                                  style:
                                      TextStyle(color: Colors.grey.shade400),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'inactive',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (currentOrder.status.toLowerCase() ==
                                  'delivered' ||
                              currentOrder.isSelfStitch ||
                              currentOrder.workerAssignmentStatus == 'received_from_worker')
                          ? null
                          : (val) async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              if (val == '__inactive_separator__') return;

                              if (currentOrder.assignedWorkerId != null &&
                                  val != currentOrder.assignedWorkerId) {
                                final bool isUnassign = val == null;
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(isUnassign ? 'Remove Worker Assignment?' : 'Reassign Worker?'),
                                    content: Text(isUnassign 
                                        ? 'This will remove the worker assignment. You can then choose Self-Stitch or assign another worker.' 
                                        : 'This order is already assigned. Do you want to reassign it to another worker?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                DesignSystem.error),
                                        child: Text(isUnassign ? 'Remove Assignment' : 'Reassign'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) {
                                  setState(() => _workerDropdownKeyCounter++);
                                  return;
                                }
                              }

                              if (val == null) {
                                final success =
                                    await orderProvider.updateOrderWorker(
                                  currentOrder.id,
                                  null,
                                );
                                if (context.mounted) {
                                  showGlobalSnackBar(
                                    success
                                        ? 'Worker unassigned'
                                        : 'Failed to unassign worker.',
                                    isError: !success,
                                  );
                                }
                                return;
                              }

                              final error = workerProvider
                                  .validateWorkerForAssignment(val);
                              if (error != null) {
                                if (context.mounted) {
                                  showGlobalSnackBar(error, isError: true);
                                }
                                return;
                              }

                              if (context.mounted) {
                                final pricingResult =
                                    await showDialog<WorkerPricingDialogResult>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => WorkerPricingDialog(
                                    items: currentOrder.items,
                                  ),
                                );
                                if (pricingResult == null) {
                                  setState(() => _workerDropdownKeyCounter++);
                                  return;
                                }
                                final success =
                                    await orderProvider.updateOrderWorker(
                                  currentOrder.id,
                                  val,
                                );
                                if (success) {
                                  final wp = WorkerProviderWrapper.of(context,
                                      listen: false);
                                  await wp.assignWorkerWithPricing(
                                    workerId: val,
                                    orderId: currentOrder.id,
                                    pricingData: pricingResult.pricingData,
                                  );
                                }
                                if (context.mounted) {
                                  showGlobalSnackBar(
                                    success
                                        ? 'Worker assigned with pricing'
                                        : 'Failed to update worker assignment.',
                                    isError: !success,
                                  );
                                }
                              }
                            },
                    ),
                    if (workerProvider.workers.isEmpty &&
                        !workerProvider.isLoading) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  Colors.orange.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 18, color: Colors.orange.shade800),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No crew members registered. Go to the workshop crew tab to register workers.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Self-Stitch Section ──
              if (currentOrder.assignedWorkerId == null ||
                  currentOrder.assignedWorkerId!.isEmpty)
                _buildSection(
                  title: currentOrder.isSelfStitch
                      ? 'Self-Stitch Mode'
                      : 'Stitching Options',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: currentOrder.isSelfStitch
                          ? Colors.green.withValues(alpha: 0.05)
                          : DesignSystem.creamBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: currentOrder.isSelfStitch
                            ? Colors.green.withValues(alpha: 0.2)
                            : DesignSystem.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: currentOrder.isSelfStitch
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                currentOrder.isSelfStitch
                                    ? Icons.person_rounded
                                    : Icons.handyman_rounded,
                                color: currentOrder.isSelfStitch
                                    ? Colors.green
                                    : Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentOrder.isSelfStitch
                                        ? 'You are stitching this order yourself'
                                        : 'Stitch this order yourself',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    currentOrder.isSelfStitch
                                        ? 'Worker assignment not needed. Manage lifecycle manually.'
                                        : 'Skip worker assignment and stitch yourself',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: DesignSystem.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: currentOrder.status.toLowerCase() ==
                                    'delivered'
                                ? null
                                : () async {
                                    final newVal = !currentOrder.isSelfStitch;
                                    final success =
                                        await orderProvider.toggleSelfStitch(
                                            currentOrder.id, newVal);
                                    if (context.mounted && success) {
                                      showGlobalSnackBar(
                                        newVal
                                            ? 'Self-stitch mode enabled'
                                            : 'Self-stitch mode disabled',
                                      );
                                    }
                                  },
                            icon: Icon(
                              currentOrder.isSelfStitch
                                  ? Icons.remove_circle_outline_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 18,
                              color: currentOrder.isSelfStitch
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            label: Text(
                              currentOrder.isSelfStitch
                                  ? 'DISABLE SELF-STITCH'
                                  : 'ENABLE SELF-STITCH',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: currentOrder.isSelfStitch
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: currentOrder.isSelfStitch
                                  ? Colors.red
                                  : Colors.green,
                              side: BorderSide(
                                color: currentOrder.isSelfStitch
                                    ? Colors.red.withValues(alpha: 0.4)
                                    : Colors.green.withValues(alpha: 0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // ── Notify Customer ──
              _buildSection(
                title: 'Notify Customer',
                child: _buildNotificationActions(currentOrder, customer),
              ),

              // ── Special Instructions ──
              if (currentOrder.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                _buildSection(
                  title: 'Special Instructions',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      currentOrder.notes!,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),

              _buildStatusHistory(currentOrder),

              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint('[OrderDetailScreen] Build Error: $e\n$stack');
      return Scaffold(
        appBar: AppBar(title: const Text('Order Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Failed to display order details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try going back and reopening the order.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('GO BACK'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DesignSystem.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.5,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildNotificationActions(OrderModel order, Customer customer) {
    final status = order.status.toLowerCase();
    final isDelivered = status == 'delivered' || status == 'cancelled';
    final itemStatuses =
        order.items.map((i) => i.status.toLowerCase()).toSet();

    final actions = <Map<String, dynamic>>[];

    if (customer.phone.isNotEmpty) {
      actions.add({
        'label': 'Order Created Update',
        'eventType': NotificationEventType.orderCreated,
        'icon': Icons.shopping_bag_rounded,
      });
      if (itemStatuses.contains('stitching')) {
        actions.add({
          'label': 'Stitching Started',
          'eventType': NotificationEventType.stitchingStarted,
          'icon': Icons.cut_rounded,
        });
      }
      if (order.trialDate != null && itemStatuses.contains('trialing')) {
        actions.add({
          'label': 'Trial Reminder',
          'eventType': NotificationEventType.trialReady,
          'icon': Icons.accessibility_new_rounded,
        });
      }
      if (itemStatuses.contains('ready')) {
        actions.add({
          'label': 'Order Ready',
          'eventType': NotificationEventType.orderReady,
          'icon': Icons.check_circle_outline_rounded,
        });
      }
      if (isDelivered) {
        actions.add({
          'label': 'Delivered Update',
          'eventType': NotificationEventType.delivered,
          'icon': Icons.local_shipping_rounded,
        });
      }
      if (!isDelivered && order.pendingBalance > 0) {
        actions.add({
          'label': 'Payment Reminder',
          'eventType': NotificationEventType.paymentReminder,
          'icon': Icons.payments_rounded,
        });
      }
    }

    if (actions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          customer.phone.isEmpty
              ? 'No phone number available for this customer.'
              : 'No relevant notifications at this stage.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      );
    }

    return Column(
      children: [
        ...actions.map((action) {
          final eventType = action['eventType'] as NotificationEventType;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _sendNotification(eventType, order, customer),
                icon: Icon(action['icon'] as IconData,
                    size: 16, color: Colors.green.shade700),
                label: Text(
                  action['label'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade800,
                  side: BorderSide(color: Colors.green.shade200),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _showNotificationHistory(order, customer),
          icon: Icon(Icons.history_rounded,
              size: 16, color: Colors.grey.shade600),
          label: Text(
            'View History',
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _sendNotification(NotificationEventType eventType,
      OrderModel order, Customer customer) async {
    final garmentType =
        order.items.isNotEmpty ? order.items.first.productName : 'Garment';
    await NotificationService().sendWhatsApp(
      context: context,
      phone: customer.phone,
      eventType: eventType,
      customerName: customer.name,
      orderId: order.orderToken,
      garmentType: garmentType,
      trialDate: order.trialDate != null
          ? DateFormat('dd MMM').format(order.trialDate!)
          : '',
      deliveryDate: order.deliveryDate != null
          ? DateFormat('dd MMM').format(order.deliveryDate!)
          : '',
      balanceAmount: order.pendingBalance > 0
          ? order.pendingBalance.toStringAsFixed(0)
          : '',
      shopName: 'TailorsBook',
      customerId: customer.id,
      orderUuid: order.id,
    );
  }

  Future<void> _showNotificationHistory(
      OrderModel order, Customer customer) async {
    final history = await NotificationService().getNotificationHistory(
      orderId: order.id,
      customerId: customer.id,
    );

    if (!context.mounted) return;

    showKeyboardSafeModalBottomSheet(
      context: context,
      builder: (ctx) => KeyboardSafeBottomSheet(
        maxHeightFactor: 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification History',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.notifications_off_outlined,
                        size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'No notifications sent yet',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final entry = history[index];
                    final status = entry['status']?.toString() ?? '';
                    final eventType = entry['event_type']?.toString() ?? '';
                    final createdAt = entry['created_at']?.toString() ?? '';
                    final date = DateTime.tryParse(createdAt);
                    final preview =
                        entry['message_preview']?.toString() ?? '';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: status == 'opened'
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          status == 'opened'
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: status == 'opened'
                              ? Colors.green
                              : Colors.red,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        eventType.replaceAll(
                            RegExp(r'([a-z])([A-Z])'), r'$1 $2'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        preview,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        date != null
                            ? DateFormat('dd/MM hh:mm a').format(date)
                            : '',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemTile(
    BuildContext context,
    int index,
    OrderItem item,
    OrderModel order,
    OrderProvider provider,
    Color brandOrange,
    bool isUpdatingItem,
    Customer customer,
  ) {
    String getButtonLabel(String currentStatus) {
      final s = TailorFlowHelper.normalize(currentStatus);
      if (s == TailorFlowHelper.statusPending) return 'START STITCHING';
      if (s == TailorFlowHelper.statusStitching) return 'MOVE TO FITTING';
      if (s == TailorFlowHelper.statusTrialing) return 'ADD ALTERATION';
      if (s == TailorFlowHelper.statusAlteration) return 'MARK READY';
      if (s == TailorFlowHelper.statusReady) return 'MARK DELIVERED';
      if (s == TailorFlowHelper.statusDelivered) return 'DELIVERED';
      if (s == TailorFlowHelper.statusCancelled) return 'CANCELLED';
      return 'CONTINUE';
    }

    final nextStatus = TailorFlowHelper.nextStatus(item.status);
    final isCompleted =
        TailorFlowHelper.normalize(item.status) == 'delivered' ||
            TailorFlowHelper.normalize(item.status) == 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignSystem.creamBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignSystem.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$index.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: brandOrange,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              _buildStatusBadge(item.status),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '${item.quantity} x ₹${item.unitPrice.toStringAsFixed(0)} = ₹${(item.quantity * item.unitPrice).toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  if (item.measurementId == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemMeasurementSelectionScreen(
                          order: order,
                          item: item,
                          customer: customer,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewMeasurementScreen(
                          order: order,
                          item: item,
                          customer: customer,
                          measurementId: item.measurementId!,
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(
                  item.measurementId == null
                      ? Icons.add_circle_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 14,
                  color:
                      item.measurementId == null ? Colors.red : Colors.green,
                ),
                label: Text(
                  item.measurementId == null
                      ? 'ADD MEASUREMENT'
                      : 'VIEW MEASUREMENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item.measurementId == null
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor:
                      (item.measurementId == null ? Colors.red : Colors.green)
                          .withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          _buildItemFabricInfo(item, brandOrange),
          const SizedBox(height: 12),
          if (!isCompleted)
            if (order.workMode == 'worker_assigned' && order.workerAssignmentStatus != 'received_from_worker')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This order is currently assigned to a worker. Receive it back before continuing.',
                        style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                onPressed: isUpdatingItem
                    ? null
                    : () => _updateItemToNextStatus(
                          order,
                          item,
                          provider,
                          nextStatus,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: isUpdatingItem
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        getButtonLabel(item.status),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: item.status.toLowerCase() == 'cancelled'
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.status.toLowerCase() == 'cancelled'
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.status.toLowerCase() == 'cancelled'
                        ? Icons.cancel
                        : Icons.check_circle,
                    color: item.status.toLowerCase() == 'cancelled'
                        ? Colors.red
                        : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.status.toUpperCase(),
                    style: TextStyle(
                      color: item.status.toLowerCase() == 'cancelled'
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          if (item.status.toLowerCase() == 'cancelled')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isUpdatingItem
                      ? null
                      : () => _restoreCancelledItem(order, item, provider),
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text(
                    'RESTORE ORDER ITEM',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
          if (!isCompleted &&
              TailorFlowHelper.normalize(item.status) == 'ready' &&
              order.pendingBalance > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Clear balance of ₹${order.pendingBalance.toStringAsFixed(0)} to deliver',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemFabricInfo(OrderItem item, Color brandOrange) {
    FabricProvider? fabricProvider;
    try {
      fabricProvider = FabricProviderWrapper.of(context, listen: false);
    } catch (e) {
      return const SizedBox.shrink();
    }
    
    final info = fabricProvider.getFabricDisplayInfo(item.id);
    if (info == null) return const SizedBox.shrink();

    final source = info['source']?.toString() ?? '';
    final sourceRaw = info['source_raw']?.toString() ?? '';
    final fabricName = info['fabric_name']?.toString();
    final meters = (info['meters'] as num?)?.toDouble() ?? 0.0;
    final status = info['status']?.toString() ?? '';
    final purpose = info['purpose']?.toString() ?? '';

    Color statusColor;
    switch (purpose) {
      case 'consumed':
        statusColor = Colors.blue;
        break;
      case 'restored':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: sourceRaw == 'SHOP'
              ? Colors.blue.withValues(alpha: 0.04)
              : Colors.green.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sourceRaw == 'SHOP'
                ? Colors.blue.withValues(alpha: 0.15)
                : Colors.green.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              sourceRaw == 'SHOP'
                  ? Icons.store_rounded
                  : Icons.person_rounded,
              size: 14,
              color: sourceRaw == 'SHOP'
                  ? Colors.blue.shade400
                  : Colors.green.shade600,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                sourceRaw == 'SHOP'
                    ? '$source${fabricName != null ? ' • $fabricName' : ''} • ${meters.toStringAsFixed(1)}m'
                    : source,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateItemToNextStatus(
    OrderModel order,
    OrderItem item,
    OrderProvider provider,
    String? nextStatus,
  ) async {
    if (nextStatus == null) return;

    final fabricProvider = FabricProviderWrapper.of(context, listen: false);

    if (nextStatus == 'stitching' ||
        nextStatus == 'ready' ||
        nextStatus == 'delivered') {
      final guardrailError = fabricProvider.checkFabricGuardrails(
        item.id,
        order.fabricReceived,
      );
      if (guardrailError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(guardrailError), backgroundColor: Colors.red),
        );
        return;
      }
    }

    if (nextStatus == 'stitching') {
      if (item.measurementId == null || item.measurementId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please add measurements for this item before starting stitching.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!order.isSelfStitch &&
          (order.assignedWorkerId == null ||
              order.assignedWorkerId!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please assign a worker or enable self-stitch before starting stitching.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (nextStatus == 'delivered' && order.pendingBalance > 0) {
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.block_rounded, color: Colors.red.shade600, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Delivery Blocked',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.red.shade700, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '₹${order.pendingBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        color: Colors.red.shade700,
                      ),
                    ),
                    Text(
                      'PENDING BALANCE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.red.shade500,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This order cannot be marked as delivered until the full balance of ₹${order.pendingBalance.toStringAsFixed(0)} is cleared.',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        color: Colors.amber.shade800, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Collect the remaining balance first, then mark as delivered.',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showPaymentDialog(context, order, provider);
              },
              icon: const Icon(Icons.payments_rounded, size: 18),
              label: const Text('RECORD PAYMENT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (nextStatus == 'ready' &&
        order.trialDate != null &&
        order.status != 'trialing' &&
        order.status != 'alteration') {
      if (!context.mounted) return;
      final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Trial Not Recorded'),
              content: const Text(
                'A trial date was set for this order, but it hasn\'t been through the trialing stage yet. Mark as READY anyway?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('WAIT'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('YES, MARK READY'),
                ),
              ],
            ),
          ) ??
          false;
      if (!proceed || !context.mounted) return;
    }

    String? alterationNote;
    if (nextStatus == 'alteration') {
      if (!context.mounted) return;
      alterationNote = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (_) => AlterationNotesScreen(
            title: 'Alteration Notes',
            initialNote: item.alterationNotes ?? '',
          ),
        ),
      );
      if (!context.mounted) return;
      
      // If user cancelled by pressing back button
      if (alterationNote == null) return;
      
      // If user chose to skip alteration
      if (alterationNote == '__SKIP_ALTERATION__') {
        nextStatus = 'ready';
        alterationNote = null;
      }
    }

    setState(() => _updatingItemId = item.id);
    try {
      final success = await provider.updateOrderItemStatus(
        order.id,
        item.id,
        nextStatus,
        alterationNote: alterationNote,
      );

      if (!success && nextStatus == 'delivered' && context.mounted) {
        final currentOrder = provider.orders.firstWhere(
          (o) => o.id == order.id,
          orElse: () => order,
        );
        _showPaymentDialog(context, currentOrder, provider);
      }

      if (context.mounted) {
        String message = '';
        switch (nextStatus) {
          case 'stitching':
            message = 'Item moved to stitching';
            break;
          case 'trialing':
            message = 'Item moved to Trial/Fitting stage';
            break;
          case 'alteration':
            message = 'Alteration notes saved';
            break;
          case 'ready':
            message = 'Item marked as Ready for delivery';
            break;
          case 'delivered':
            message = 'Item marked as Delivered';
            break;
        }
        if (message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      if (context.mounted) setState(() => _updatingItemId = null);
    }
  }

  Future<void> _restoreCancelledItem(
    OrderModel order,
    OrderItem item,
    OrderProvider provider,
  ) async {
    final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Restore Item?',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: const Text(
              'This will move the item back to PENDING status. Proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('RESTORE'),
              ),
            ],
          ),
        ) ??
        false;

    if (proceed) {
      if (!context.mounted) return;
      setState(() => _updatingItemId = item.id);
      try {
        final success = await provider.updateOrderItemStatus(
          order.id,
          item.id,
          'pending',
        );

        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item restored successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } finally {
        if (context.mounted) setState(() => _updatingItemId = null);
      }
    }
  }

  void _showPaymentHistory(
    BuildContext context,
    OrderModel order,
    OrderProvider provider,
  ) {
    showKeyboardSafeModalBottomSheet(
      context: context,
      builder: (ctx) => FutureBuilder<List<PaymentModel>>(
        future: provider.fetchOrderPayments(order.id),
        builder: (context, snapshot) {
          final bool isLoading =
              snapshot.connectionState == ConnectionState.waiting;
          final payments = snapshot.data ?? [];
          final double totalPaid =
              payments.fold(0.0, (sum, p) => sum + p.amount);

          return KeyboardSafeBottomSheet(
            maxHeightFactor: 0.85,
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment History',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Paid: ₹${totalPaid.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 3)),
                    )
                  else if (payments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No payments recorded',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Payments will appear here once added',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    ...payments.map((p) {
                      final isRefunded = p.refundStatus != 'none';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRefunded
                              ? Colors.red.shade50
                              : DesignSystem.creamBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRefunded
                                ? Colors.red.shade200
                                : DesignSystem.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isRefunded
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : (p.isAdvance ? Colors.blue : Colors.green)
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isRefunded
                                    ? Icons.refresh_rounded
                                    : (p.isAdvance
                                        ? Icons.account_balance_rounded
                                        : Icons.payments_rounded),
                                color: isRefunded
                                    ? Colors.red
                                    : (p.isAdvance ? Colors.blue : Colors.green),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${p.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      decoration: isRefunded
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: isRefunded
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd MMM yyyy, hh:mm a')
                                        .format(p.paymentDate),
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11),
                                  ),
                                  if (p.paymentNote != null &&
                                      p.paymentNote!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        p.paymentNote!,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (p.paymentMethod != 'cash')
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        margin:
                                            const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          p.paymentMethod.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isRefunded
                                            ? Colors.red.withValues(alpha: 0.1)
                                            : (p.isAdvance
                                                    ? Colors.blue
                                                    : Colors.green)
                                                .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isRefunded
                                            ? 'REFUNDED'
                                            : (p.isAdvance
                                                ? 'ADVANCE'
                                                : 'RECEIVED'),
                                        style: TextStyle(
                                          color: isRefunded
                                              ? Colors.red
                                              : (p.isAdvance
                                                  ? Colors.blue
                                                  : Colors.green),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('CLOSE',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── KEY FIX: was using nonexistent showResponsiveDialog; replaced with
  //             showDialog and kept .whenComplete for controller disposal ──
  void _showPaymentDialog(
    BuildContext context,
    OrderModel order,
    OrderProvider provider,
  ) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedMethod = 'cash';
    bool isSaving = false;
    bool isAdvance = false;

    final paymentMethods = [
      {'value': 'cash', 'label': 'Cash', 'icon': Icons.money_rounded},
      {'value': 'upi', 'label': 'UPI', 'icon': Icons.phone_android_rounded},
      {'value': 'card', 'label': 'Card', 'icon': Icons.credit_card_rounded},
      {
        'value': 'cheque',
        'label': 'Cheque',
        'icon': Icons.receipt_long_rounded
      },
      {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz_rounded},
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Record Payment',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: KeyboardSafeDialogScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Remaining Balance:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${order.pendingBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  enabled: !isSaving,
                  decoration: InputDecoration(
                    labelText: 'Amount Received (₹)',
                    hintText: 'Enter amount',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: const Icon(Icons.payment_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  items: paymentMethods.map((m) {
                    return DropdownMenuItem<String>(
                      value: m['value'] as String,
                      child: Row(
                        children: [
                          Icon(m['icon'] as IconData,
                              size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(m['label'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: isSaving
                      ? null
                      : (val) {
                          FocusManager.instance.primaryFocus?.unfocus();
                          if (val != null) {
                            setDialogState(() => selectedMethod = val);
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  enabled: !isSaving,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'e.g. advance payment',
                    prefixIcon: const Icon(Icons.note_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text(
                    'Mark as Advance',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  value: isAdvance,
                  onChanged: (val) =>
                      setDialogState(() => isAdvance = val),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                if (isSaving)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final amountString = amountController.text.trim();
                      if (amountString.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter an amount')),
                        );
                        return;
                      }

                      final amount = double.tryParse(amountString);
                      if (amount == null ||
                          amountString.contains(RegExp(r'[^\d.]'))) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid number'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      final safeAmount =
                          double.parse(amount.toStringAsFixed(2));
                      if (safeAmount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Amount must be greater than zero'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      bool allowSettleOverride = false;
                      if (safeAmount - order.pendingBalance > 0.01) {
                        final proceed = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(20)),
                                title:
                                    const Text('Overpayment Warning'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Amount: ₹${safeAmount.toStringAsFixed(0)}'),
                                    Text(
                                        'Remaining: ₹${order.pendingBalance.toStringAsFixed(0)}'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This will overpay by ₹${(safeAmount - order.pendingBalance).toStringAsFixed(0)}. Proceed?',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(c, false),
                                    child: const Text('CORRECT IT'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(c, true),
                                    child: const Text('YES, PROCEED'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (!proceed) return;
                        allowSettleOverride = true;
                      }

                      setDialogState(() => isSaving = true);

                      final success = await provider.addOrderPayment(
                        order.id,
                        safeAmount,
                        isAdvance: isAdvance,
                        isSettle: allowSettleOverride,
                        paymentMethod: selectedMethod,
                        paymentNote:
                            noteController.text.trim().isNotEmpty
                                ? noteController.text.trim()
                                : null,
                      );

                      if (success) {
                        if (context.mounted) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Payment recorded successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  provider.errorMessage ?? 'Payment failed'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('SAVE PAYMENT'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      amountController.dispose();
      noteController.dispose();
    });
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    switch (status.toLowerCase()) {
      case 'stitching':
        color = Colors.orange;
        break;
      case 'trialing':
        color = Colors.purple;
        break;
      case 'alteration':
        color = Colors.deepOrange;
        break;
      case 'ready':
        color = Colors.green;
        break;
      case 'delivered':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        TailorFlowHelper.getStatusLabel(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isTotal ? 20 : 16,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(
    IconData icon,
    String label,
    String date, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color ?? Colors.grey),
          ),
          const SizedBox(width: 15),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            date,
            style:
                const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBanner(DateTime deliveryDate, Color brandOrange) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final delivery =
        DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day);
    final daysUntil = delivery.difference(today).inDays;

    if (daysUntil < 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OVERDUE by ${daysUntil.abs()} day${daysUntil.abs() > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Delivery was due on ${DateFormat('dd MMM').format(deliveryDate)}',
                    style:
                        TextStyle(color: Colors.red.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (daysUntil == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.today_rounded, color: Colors.orange.shade800, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DUE TODAY',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Complete and deliver this order today',
                    style: TextStyle(
                        color: Colors.orange.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (daysUntil <= 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: brandOrange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: brandOrange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_filled_rounded,
                color: brandOrange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due in $daysUntil day${daysUntil > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: brandOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Delivery date: ${DateFormat('dd MMM').format(deliveryDate)}',
                    style: TextStyle(
                        color: brandOrange.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPendingBalanceBanner(double pendingBalance) {
    if (pendingBalance <= 0.01) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_rounded,
              color: Colors.amber.shade800, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENDING BALANCE: ₹${pendingBalance.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Collect payment before delivery',
                  style:
                      TextStyle(color: Colors.amber.shade800, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'paid':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        label = 'PAID';
        break;
      case 'partial':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        label = 'PARTIAL';
        break;
      default:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        label = 'UNPAID';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildStatusHistory(OrderModel order) {
    if (order.statusHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Order Progress History',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DesignSystem.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.statusHistory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final entry = order.statusHistory[index];
              final date =
                  DateTime.tryParse(entry['at'] ?? '') ?? DateTime.now();
              final isLast = index == order.statusHistory.length - 1;
              final label = entry['label'] ??
                  TailorFlowHelper.getStatusLabel(entry['to'] ?? 'pending');
              final note = entry['note'] as String?;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isLast
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLast
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 40,
                            color: Colors.grey.shade200,
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                label.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: isLast
                                      ? Colors.black
                                      : Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM, hh:mm a').format(date),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          if (note != null && note.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                note,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}