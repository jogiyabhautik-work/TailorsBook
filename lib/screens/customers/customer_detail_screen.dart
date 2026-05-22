import 'package:flutter/material.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../models/customer_model.dart';
import '../../main.dart';
import '../../core/utils/design_system.dart';
import 'customer_measurement_screen.dart';
import '../measurements/measurement_view_screen.dart';
import 'add_customer_screen.dart';
import '../../models/measurement_record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/responsive.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TemplateProviderWrapper.of(context, listen: false)
          .fetchCustomerMeasurementsPaginated(customerId: customer.id);
    });

    final brandOrange = Theme.of(context).colorScheme.primary;
    final currentCustomer = CustomerProviderWrapper.of(context).customers.firstWhere((c) => c.id == customer.id, orElse: () => customer);
    final brandBlack = DesignSystem.charcoal;

    return Scaffold(
      backgroundColor: DesignSystem.creamBg,
      body: SafeArea(
        child: Column(
          children: [
          // Premium Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: BoxDecoration(
              color: DesignSystem.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [BoxShadow(color: DesignSystem.charcoal.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      style: IconButton.styleFrom(backgroundColor: DesignSystem.creamBg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    ),
                    Text('CLIENT PROFILE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: DesignSystem.muted, letterSpacing: 1.2)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddCustomerScreen(initialCustomer: currentCustomer),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: DesignSystem.primary.withValues(alpha: 0.1),
                            foregroundColor: DesignSystem.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                      onPressed: () async {
                        final orderProvider = OrderProviderWrapper.of(context);
                        final hasActiveOrders = orderProvider.orders.any(
                          (o) => o.customerId == currentCustomer.id
                              && o.status.toLowerCase() != 'delivered'
                              && o.status.toLowerCase() != 'cancelled',
                        );

                        if (hasActiveOrders) {
                          if (!context.mounted) return;
                          await showResponsiveDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cannot Delete'),
                              content: const Text('This customer has active orders. Complete or cancel all orders before removing this customer.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                              ],
                            ),
                          );
                          return;
                        }

                        final confirmed = await showResponsiveDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remove Customer?'),
                            content: const Text('This will remove the customer from your list. Historical orders, payments, and measurements will be preserved.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: DesignSystem.error))),
                            ],
                          ),
                        );
                        if (confirmed != true || !context.mounted) return;

                        // Show loading dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (loadingCtx) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        final customerProvider = CustomerProviderWrapper.of(context, listen: false);
                        final success = await customerProvider.deleteCustomer(currentCustomer.id);
                        if (context.mounted) {
                          Navigator.pop(context); // Close loading dialog
                          if (success) {
                            await customerProvider.fetchCustomers();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Customer removed successfully.'), backgroundColor: DesignSystem.success),
                              );
                              Navigator.pop(context); // Close details screen
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: DesignSystem.error.withValues(alpha: 0.1), 
                        foregroundColor: DesignSystem.error, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: brandOrange.withValues(alpha: 0.1),
                      child: Text(currentCustomer.name.isNotEmpty ? currentCustomer.name[0].toUpperCase() : '?', style: TextStyle(color: brandOrange, fontWeight: FontWeight.w900, fontSize: 28)),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentCustomer.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          Text(currentCustomer.phone, style: TextStyle(color: DesignSystem.muted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Quick Call/Msg Ribbon
                Row(
                  children: [
                    Expanded(
                      child: _buildRibbonAction(Icons.call_rounded, 'CALL', DesignSystem.success, () {
                        _launchAction('tel:${currentCustomer.phone}');
                      }),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildRibbonAction(Icons.message_rounded, 'WHATSAPP', DesignSystem.primary, () {
                      final msg = Uri.encodeComponent("Hello ${currentCustomer.name}! This is ${supabase.auth.currentUser?.userMetadata?['shop_name'] ?? 'TailorsBook'}. Following up regarding your order.");
                      _launchAction('https://wa.me/${currentCustomer.phone}?text=$msg');
                    }),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildRibbonAction(Icons.share_rounded, 'SHARE', DesignSystem.primary, () {
                         final shareText = "Customer Details:\nName: ${currentCustomer.name}\nPhone: ${currentCustomer.phone}\nAddress: ${currentCustomer.address}\n\nShared via TailorsBook";
                         Share.share(shareText);
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Info Cards
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedContent(
                child: Column(
                  children: [
                    // Business Statistics
                    Builder(builder: (ctx) {
                      final orderProvider = OrderProviderWrapper.of(ctx);
                      final customerOrders = orderProvider.orders.where((o) => o.customerId == currentCustomer.id).toList();
                      final totalSpent = customerOrders.fold(0.0, (sum, o) => sum + o.totalPrice);
                      final pendingBal = customerOrders.fold(0.0, (sum, o) => sum + o.pendingBalance);

                      return Row(
                        children: [
                          _buildStatCard('Orders', '${customerOrders.length}', DesignSystem.primary),
                          const SizedBox(width: 12),
                          _buildStatCard('Spent', '₹${totalSpent.toStringAsFixed(0)}', DesignSystem.success),
                          const SizedBox(width: 12),
                          _buildStatCard('Balance', '₹${pendingBal.toStringAsFixed(0)}', DesignSystem.error),
                        ],
                      );
                    }),
                    const SizedBox(height: 24),

                    // Active Orders Section (includes delivered orders with pending balance)
                    Builder(builder: (ctx) {
                      final orderProvider = OrderProviderWrapper.of(ctx);
                      final activeOrders = orderProvider.orders
                          .where((o) => o.customerId == currentCustomer.id && (o.status.toLowerCase() != 'delivered' || o.pendingBalance > 0))
                          .toList();
                      if (activeOrders.isEmpty) return const SizedBox.shrink();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Orders & Payments', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                              if (activeOrders.any((o) => o.pendingBalance > 0))
                                Text(
                                  'DUES: ₹${activeOrders.fold(0.0, (sum, o) => sum + o.pendingBalance).toStringAsFixed(0)}',
                                  style: const TextStyle(color: DesignSystem.error, fontWeight: FontWeight.w900, fontSize: 12),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...activeOrders.map((order) {
                            final hasBalance = order.pendingBalance > 0;
                            final missingItems = order.items
                                .where((item) => item.measurementId == null || item.measurementId!.isEmpty)
                                .toList();
                            final missingProductNames = missingItems.map((i) => i.productName).toSet().toList();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: DesignSystem.white, 
                                borderRadius: BorderRadius.circular(20), 
                                border: Border.all(color: hasBalance ? DesignSystem.error.withValues(alpha: 0.1) : const Color(0xFFEEEEEE)),
                                boxShadow: [BoxShadow(color: DesignSystem.charcoal.withValues(alpha: 0.01), blurRadius: 10)]
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10), 
                                        decoration: BoxDecoration(color: brandOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), 
                                        child: Icon(Icons.checkroom_rounded, size: 20, color: brandOrange)
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              order.items.map((i) => i.productName).join(', '),
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                            Text('Order #${order.id.substring(0, 5).toUpperCase()}', style: TextStyle(color: DesignSystem.muted, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: DesignSystem.creamBg, borderRadius: BorderRadius.circular(8)),
                                        child: Text(order.status.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                      ),
                                    ],
                                  ),
                                  if (missingProductNames.isNotEmpty) ...[
                                    const Divider(height: 24),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: DesignSystem.error.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: DesignSystem.error.withValues(alpha: 0.18)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, color: DesignSystem.error, size: 18),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Measurements pending: ${missingProductNames.join(', ')}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DesignSystem.error),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                ctx,
                                                MaterialPageRoute(builder: (_) => CustomerMeasurementScreen(customer: customer)),
                                              );
                                            },
                                            style: TextButton.styleFrom(foregroundColor: DesignSystem.error),
                                            child: const Text('MEASURE'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (hasBalance) ...[
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('OUTSTANDING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: DesignSystem.muted)),
                                            Text('₹${order.pendingBalance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: DesignSystem.error)),
                                          ],
                                        ),
                                        ElevatedButton(
                                          onPressed: () => _showSettlementDialog(ctx, order, orderProvider),
                                          child: const Text('SETTLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                                        ),
                                      ],
                                    ),
                                  ]
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                      );
                    }),

                    // Measurements Card
                    Builder(
                      builder: (context) {
                        final provider = TemplateProviderWrapper.of(context);
                        final measurements = provider.getCustomerMeasurements(currentCustomer.id);
                        measurements.sort((a, b) => b.date.compareTo(a.date));

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: DesignSystem.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: DesignSystem.charcoal.withValues(alpha: 0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Measurements',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: brandBlack,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: DesignSystem.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      measurements.isEmpty ? 'Not added' : '${measurements.length} Records',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: DesignSystem.muted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (measurements.isEmpty)
                                Row(
                                  children: [
                                    Icon(Icons.straighten_outlined,
                                        size: 36, color: DesignSystem.outlineVariant),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No measurements recorded yet.\nAdd them to track tailoring details.',
                                        style: TextStyle(
                                        color: DesignSystem.muted,
                                        fontSize: 13,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Builder(
                                  builder: (ctx) {
                                    final orderProvider = OrderProviderWrapper.of(ctx);
                                    final activeOrderItems = orderProvider.orders
                                        .where((o) => o.customerId == currentCustomer.id && (o.status.toLowerCase() != 'delivered' || o.pendingBalance > 0))
                                        .expand((o) => o.items)
                                        .map((i) => i.productName.toLowerCase())
                                        .toSet();

                                    // Group by templateId
                                    final groups = <String, List<MeasurementRecord>>{};
                                    for (var m in measurements) {
                                      groups.putIfAbsent(m.templateId, () => []).add(m);
                                    }

                                    final sortedGroups = groups.entries.toList();
                                    sortedGroups.sort((a, b) {
                                        final aIsActive = activeOrderItems.contains(a.value.first.templateName.toLowerCase());
                                        final bIsActive = activeOrderItems.contains(b.value.first.templateName.toLowerCase());
                                        if (aIsActive && !bIsActive) return -1;
                                        if (!aIsActive && bIsActive) return 1;
                                        return b.value.first.date.compareTo(a.value.first.date);
                                    });

                                    return SizedBox(
                                      height: 148,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: sortedGroups.length,
                                        itemBuilder: (context, index) {
                                          final entry = sortedGroups[index];
                                          final records = entry.value;
                                          records.sort((a, b) => b.date.compareTo(a.date));
                                          final current = records[0];
                                          final isActive = activeOrderItems.contains(current.templateName.toLowerCase());

                                          return _buildMiniMeasurementCard(ctx, current, brandOrange, isActive: isActive);
                                        },
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CustomerMeasurementScreen(customer: customer),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 20),
                                  label: const Text(
                                    'Add Measurements',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandOrange,
                                    foregroundColor: DesignSystem.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      },
                    ),

                    //
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}



  Widget _buildMiniMeasurementCard(BuildContext context, MeasurementRecord current, Color orange, {bool isActive = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeasurementViewScreen(record: current))),
      child: Container(
        width: 124,
        margin: const EdgeInsets.only(right: 10, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: DesignSystem.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? orange.withValues(alpha: 0.35) : const Color(0xFFF0F0F0),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive ? orange.withValues(alpha: 0.06) : DesignSystem.charcoal.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isActive ? orange.withValues(alpha: 0.12) : DesignSystem.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.checkroom_rounded, color: isActive ? orange : DesignSystem.muted, size: 18),
                ),
                if (isActive)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: DesignSystem.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: DesignSystem.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              current.templateName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: isActive ? DesignSystem.charcoal : DesignSystem.charcoal,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _formatDate(current.date),
              style: TextStyle(color: DesignSystem.muted, fontSize: 9, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded, size: 11, color: DesignSystem.outlineVariant),
                const SizedBox(width: 3),
                Text('View', style: TextStyle(fontSize: 9, color: DesignSystem.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: DesignSystem.white, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: const Color(0xFFEEEEEE)), 
          boxShadow: [BoxShadow(color: DesignSystem.charcoal.withValues(alpha: 0.01), blurRadius: 10)]
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DesignSystem.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildRibbonAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  void _launchAction(String url) async {
    final uri = Uri.parse(url);
    try {
       if (await canLaunchUrl(uri)) {
         await launchUrl(uri, mode: LaunchMode.externalApplication);
       }
    } catch (e) {
       debugPrint('Could not launch $url : $e');
    }
  }

  void _showSettlementDialog(BuildContext context, dynamic order, dynamic orderProvider) {
    final amountController = TextEditingController(text: order.pendingBalance.toStringAsFixed(0));
    String selectedOption = 'full';

    showResponsiveDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool isProcessing = false;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: DesignSystem.success.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: DesignSystem.success, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Settle Payment', style: TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            content: KeyboardSafeDialogScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.id.substring(0, 5).toUpperCase()}', style: const TextStyle(fontSize: 12, color: DesignSystem.muted)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: DesignSystem.error.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Outstanding:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('₹${order.pendingBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: DesignSystem.error)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Payment Option:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DesignSystem.muted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => selectedOption = 'full'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedOption == 'full' ? DesignSystem.success.withValues(alpha: 0.1) : DesignSystem.muted.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: selectedOption == 'full' ? DesignSystem.success : Colors.transparent, width: 2),
                              ),
                              child: Column(
                                children: [
                                    Icon(Icons.payments_rounded, color: selectedOption == 'full' ? DesignSystem.success : DesignSystem.muted, size: 20),
                                    const SizedBox(height: 4),
                                    Text('Full Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: selectedOption == 'full' ? DesignSystem.success : DesignSystem.muted)),
                                  Text('₹${order.pendingBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => selectedOption = 'custom'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedOption == 'custom' ? DesignSystem.primary.withValues(alpha: 0.1) : DesignSystem.muted.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: selectedOption == 'custom' ? DesignSystem.primary : Colors.transparent, width: 2),
                              ),
                              child: Column(
                                children: [
                                    Icon(Icons.edit_rounded, color: selectedOption == 'custom' ? DesignSystem.primary : DesignSystem.muted, size: 20),
                                    const SizedBox(height: 4),
                                    Text('Custom Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: selectedOption == 'custom' ? DesignSystem.primary : DesignSystem.muted)),
                                  Text('Enter amount', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedOption == 'custom') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Enter Amount ()',
                          prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: DesignSystem.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: DesignSystem.primaryContainer, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) => setDialogState(() {}),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: DesignSystem.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pending After Payment:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DesignSystem.muted)),
                          Builder(
                            builder: (_) {
                              final pending = order.pendingBalance - (double.tryParse(amountController.text) ?? 0);
                              return Text(
                                '₹${pending.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: pending > 0 ? DesignSystem.primary : DesignSystem.success,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ),
            actions: [
              TextButton(
                onPressed: () { if (!isProcessing) Navigator.pop(ctx); },
                child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (isProcessing) return;
                  final enteredAmount = double.tryParse(amountController.text) ?? 0;
                  if (enteredAmount > order.pendingBalance) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Amount cannot exceed outstanding balance'),
                        backgroundColor: DesignSystem.error,
                      ),
                    );
                    return;
                  }
                  setDialogState(() => isProcessing = true);
                  try {
                    final success = await orderProvider.addOrderPayment(order.id, enteredAmount, isSettle: true);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: success
                                ? Text('₹${enteredAmount.toStringAsFixed(0)} payment recorded successfully!')
                                : const Text('Payment failed. Please try again.'),
                            backgroundColor: success ? DesignSystem.success : DesignSystem.error,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    setDialogState(() => isProcessing = false);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: DesignSystem.error),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.success,
                  foregroundColor: DesignSystem.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isProcessing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(DesignSystem.white)))
                    : const Text('CONFIRM PAYMENT', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          );
        },
      ),
    ).whenComplete(amountController.dispose);
  }
}
