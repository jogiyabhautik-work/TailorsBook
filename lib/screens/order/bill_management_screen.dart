import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/provider_wrappers.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../models/order_model.dart';
import '../../models/worker_model.dart';
import '../../core/utils/invoice_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/design_system.dart';

class BillManagementScreen extends StatefulWidget {
  const BillManagementScreen({super.key});

  @override
  State<BillManagementScreen> createState() => _BillManagementScreenState();
}

class _BillManagementScreenState extends State<BillManagementScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final List<String> _statuses = ['All', 'pending', 'stitching', 'trialing', 'ready', 'delivered'];
  DateTime _lastTapTime = DateTime.now();
  bool _isGeneratingPdf = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool _isDoubleTap() {
    final now = DateTime.now();
    final difference = now.difference(_lastTapTime);
    final isDoubleTap = difference.inMilliseconds < 500;
    _lastTapTime = now;
    return isDoubleTap;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = query);
    });
  }

  Future<void> _generateAndSharePdfWithLoading(OrderModel order, Customer customer) async {
    if (_isDoubleTap()) return;

    setState(() => _isGeneratingPdf = true);
    try {
      final orderProvider = OrderProviderWrapper.of(context);
      final workerProvider = WorkerProviderWrapper.of(context);

      // Gather enhanced invoice data
      final payments = await orderProvider.fetchOrderPayments(order.id);

      String? workerName;
      if (order.assignedWorkerId?.isNotEmpty == true) {
        final worker = workerProvider.workers.firstWhere(
          (w) => w.id == order.assignedWorkerId,
          orElse: () => WorkerModel(
            id: '',
            tailorId: '',
            name: '',
            salaryType: SalaryType.monthly,
            joiningDate: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );
        workerName = worker.name.isNotEmpty ? worker.name : null;
      }

      await InvoiceHelper.generateAndShareInvoice(
        order: order,
        customer: customer,
        payments: payments,
        workerName: workerName,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice shared successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing invoice: $e')),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = OrderProviderWrapper.of(context);
    final customerProvider = CustomerProviderWrapper.of(context);
    final brandOrange = Theme.of(context).colorScheme.primary;

    final filteredOrders = orderProvider.orders.where((order) {
      final customer = customerProvider.customers.firstWhere(
        (c) => c.id == order.customerId,
        orElse: () => Customer(id: '', name: 'Unknown', phone: '', address: ''),
      );
      final matchesSearch = customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                             order.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == 'All' || order.status.toLowerCase() == _statusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: DesignSystem.surface,
      appBar: AppBar(
        title: Text('Bill Management', style: GoogleFonts.manrope(fontWeight: FontWeight.w900, color: DesignSystem.charcoal)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: DesignSystem.surfaceContainerLowest,
        foregroundColor: DesignSystem.charcoal,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: DesignSystem.surfaceContainerLowest,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                 AppSearchBar(
                   controller: _searchController,
                   onChanged: _onSearchChanged,
                   hintText: 'Search by Customer Name or Order #',
                 ),
                const SizedBox(height: 16),
                SizedBox(
                   height: 40,
                   child: ListView.builder(
                     scrollDirection: Axis.horizontal,
                     itemCount: _statuses.length,
                     itemBuilder: (context, index) {
                       final s = _statuses[index];
                       final isSelected = _statusFilter == s;
                       return Padding(
                         padding: const EdgeInsets.only(right: 8),
                         child: AppFilterChip(
                           label: s == 'All' ? 'All' : s[0].toUpperCase() + s.substring(1),
                           isSelected: isSelected,
                           onTap: _isGeneratingPdf ? null : () => setState(() => _statusFilter = s),
                         ),
                       );
                     },
                   ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredOrders.isEmpty
                ? EmptyStateWidget(
                    title: 'No payment history',
                    subtitle: _searchQuery.isEmpty ? 'All clear! No pending or unpaid bills found.' : 'No orders found matching "$_searchQuery".',
                    icon: Icons.payments_rounded,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final customer = customerProvider.customers.firstWhere(
                        (c) => c.id == order.customerId,
                        orElse: () => Customer(id: '', name: 'Unknown', phone: '', address: ''),
                      );
                      return _buildBillCard(order, customer, brandOrange);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ready': return Colors.green;
      case 'stitching': return Colors.orange;
      case 'trialing': return Colors.purple;
      case 'delivered': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Widget _buildBillCard(OrderModel order, Customer customer, Color orange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text('${order.items.length} items \u2022 ${DateFormat('MMM dd').format(order.createdAt)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _getStatusColor(order.status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(order.status.toUpperCase(), style: TextStyle(color: _getStatusColor(order.status), fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BALANCE DUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(
                      '₹${order.pendingBalance.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.red),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 0,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingPdf 
                      ? null 
                      : () => _generateAndSharePdfWithLoading(order, customer),
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.share_rounded, size: 16),
                  label: Text(
                    _isGeneratingPdf ? 'SHARING...' : 'SHARE BILL',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
