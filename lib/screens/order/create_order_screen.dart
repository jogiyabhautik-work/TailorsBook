import 'package:flutter/material.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../widgets/common/provider_wrappers.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/responsive.dart';
import '../../models/customer_model.dart';
import '../../models/order_model.dart';
import '../../models/worker_model.dart';
import '../../models/fabric_model.dart';
import '../../models/measurement_template.dart';
import '../customers/add_customer_screen.dart';
import '../customers/customer_measurement_screen.dart';
import '../../widgets/dialogs/worker_pricing_dialog.dart';
import '../../widgets/dialogs/add_garment_dialog.dart';
import '../../core/utils/validation.dart';

class _ItemFabricConfig {
  String source = 'CUSTOMER';
  String? shopFabricId;
  final TextEditingController quantityController = TextEditingController(text: '0');

  void dispose() {
    quantityController.dispose();
  }
}

class CreateOrderScreen extends StatefulWidget {
  final Customer? preSelectedCustomer;
  const CreateOrderScreen({super.key, this.preSelectedCustomer});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  Customer? _selectedCustomer;
  WorkerModel? _selectedWorker;
  DateTime? _deliveryDate;
  DateTime? _trialDate;
  final TextEditingController _advanceController = TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();
  final List<OrderItem> _items = [];
  final Map<String, _ItemFabricConfig> _fabricConfigs = {};
  final bool _fabricReceived = false;
  bool _isSubmitting = false;
  String _workMode = 'self_stitch'; // 'self_stitch', 'worker_assigned', or 'pending_decision'

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preSelectedCustomer;
  }

  @override
  void dispose() {
    _advanceController.dispose();
    _notesController.dispose();
    for (final config in _fabricConfigs.values) {
      config.dispose();
    }
    super.dispose();
  }

  double get _totalPrice => _items.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));

  double get _pendingBalance {
    final advance = double.tryParse(_advanceController.text) ?? 0.0;
    final balance = _totalPrice - advance;
    return balance < 0 ? 0.0 : balance;
  }

  _ItemFabricConfig _getOrCreateFabricConfig(String itemId) {
    if (!_fabricConfigs.containsKey(itemId)) {
      _fabricConfigs[itemId] = _ItemFabricConfig();
    }
    return _fabricConfigs[itemId]!;
  }

  Future<void> _showAddItemDialog() async {
    if (_selectedCustomer == null) {
      showGlobalSnackBar('Please select a customer first.', isError: true);
      return;
    }

    final templateProvider = TemplateProviderWrapper.of(context, listen: false);
    
    final result = await showResponsiveDialog<AddGarmentDialogResult>(
      context: context,
      builder: (context) => AddGarmentDialog(templates: templateProvider.templates),
    );

    if (result != null && context.mounted) {
      setState(() {
        final itemId = const Uuid().v4();
        _items.add(OrderItem(
          id: itemId,
          orderId: '',
          productName: result.name,
          quantity: result.quantity,
          unitPrice: result.price,
        ));
        _fabricConfigs[itemId] = _ItemFabricConfig();
      });
    }
  }

  void _removeItem(OrderItem item) {
    setState(() {
      _items.remove(item);
      _fabricConfigs.remove(item.id)?.dispose();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isTrial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!context.mounted) return;
    if (picked != null) {
      if (isTrial) {
        if (_deliveryDate != null) {
          final deliveryZeroTime = DateTime(_deliveryDate!.year, _deliveryDate!.month, _deliveryDate!.day);
          final trialZeroTime = DateTime(picked.year, picked.month, picked.day);
          final diff = deliveryZeroTime.difference(trialZeroTime).inDays;
          if (diff < 1) {
            showGlobalSnackBar('Trial/Fitting date must be at least 1 day before delivery date.', isError: true);
            return;
          }
        }
        setState(() {
          _trialDate = picked;
        });
      } else {
        if (_trialDate != null) {
          final deliveryZeroTime = DateTime(picked.year, picked.month, picked.day);
          final trialZeroTime = DateTime(_trialDate!.year, _trialDate!.month, _trialDate!.day);
          final diff = deliveryZeroTime.difference(trialZeroTime).inDays;
          if (diff < 1) {
            showGlobalSnackBar('Delivery date must be at least 1 day after trial/fitting date.', isError: true);
            return;
          }
        }
        setState(() {
          _deliveryDate = picked;
        });
      }
    }
  }

  void _navigateToMeasurements(OrderItem item) {
    if (_selectedCustomer == null) {
      showGlobalSnackBar('Select a customer first.', isError: true);
      return;
    }

    final templateProvider = TemplateProviderWrapper.of(context);
    final allTemplates = templateProvider.getAllTemplates();

    ProductTemplate? matchedTemplate;
    for (final template in allTemplates) {
      if (template.name.toLowerCase() == item.productName.toLowerCase()) {
        matchedTemplate = template;
        break;
      }
    }

    if (matchedTemplate == null) {
      showGlobalSnackBar('No measurement template found for ${item.productName}. Add one first.', isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerMeasurementScreen(
          customer: _selectedCustomer!,
          initialTemplate: matchedTemplate,
        ),
      ),
    );
  }

  Future<void> _saveOrder() async {
    if (_isSubmitting) return;

    // â”€â”€ Customer Validation â”€â”€
    if (_selectedCustomer == null) {
      showGlobalSnackBar('Please select a customer.', isError: true);
      return;
    }
    if (_selectedCustomer!.id.startsWith('temp_')) {
      showGlobalSnackBar('Cannot create order with a temporary customer.', isError: true);
      return;
    }

    // â”€â”€ Items Validation â”€â”€
    if (_items.isEmpty) {
      showGlobalSnackBar('Please add at least one product/item.', isError: true);
      return;
    }
    for (final item in _items) {
      final itemError = Validation.validateOrderItem(
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      );
      if (itemError != null) {
        showGlobalSnackBar('$itemError (${item.productName})', isError: true);
        return;
      }
    }

    // â”€â”€ Work Mode Validation â”€â”€
    final workModeError = Validation.validateWorkMode(_workMode);
    if (workModeError != null) {
      showGlobalSnackBar(workModeError, isError: true);
      return;
    }

    // â”€â”€ Worker Validation (if worker_assigned) â”€â”€
    if (_workMode == 'worker_assigned') {
      if (_selectedWorker == null) {
        showGlobalSnackBar('Please select a worker to assign this order.', isError: true);
        return;
      }
      if (!_selectedWorker!.isActive) {
        showGlobalSnackBar('Cannot assign to an inactive worker.', isError: true);
        return;
      }
    }

    // â”€â”€ Delivery Date Validation â”€â”€
    final deliveryError = Validation.validateDeliveryDate(_deliveryDate);
    if (deliveryError != null) {
      showGlobalSnackBar(deliveryError, isError: true);
      return;
    }

    // â”€â”€ Trial Date Validation â”€â”€
    final trialError = Validation.validateTrialDate(_trialDate, _deliveryDate);
    if (trialError != null) {
      showGlobalSnackBar(trialError, isError: true);
      return;
    }

    // â”€â”€ Payment Validation â”€â”€
    final advance = double.tryParse(_advanceController.text) ?? 0.0;
    final advanceError = Validation.validateAdvanceAmount(advance, _totalPrice);
    if (advanceError != null) {
      showGlobalSnackBar(advanceError, isError: true);
      return;
    }

    // â”€â”€ Fabric Quantity Validation â”€â”€
    final fabricProvider = FabricProviderWrapper.of(context, listen: false);
    for (final item in _items) {
      final config = _fabricConfigs[item.id];
      if (config != null && config.source == 'SHOP' && config.shopFabricId != null) {
        final qty = double.tryParse(config.quantityController.text) ?? 0;
        if (qty <= 0) {
          showGlobalSnackBar('Enter fabric quantity for ${item.productName}', isError: true);
          return;
        }
        final error = fabricProvider.validateFabricQuantity(config.shopFabricId!, qty);
        if (error != null) {
          showGlobalSnackBar('${item.productName}: $error', isError: true);
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final orderProvider = OrderProviderWrapper.of(context);

      // â”€â”€ Worker Pricing Dialog (if worker_assigned) â”€â”€
      WorkerPricingDialogResult? pricingResult;
      if (_workMode == 'worker_assigned' && _selectedWorker != null && context.mounted) {
        pricingResult = await showDialog<WorkerPricingDialogResult>(
          context: context,
          barrierDismissible: false,
          builder: (_) => KeyboardAwareDialogContent(
            child: WorkerPricingDialog(
              items: _items,
              totalOrderAmount: _totalPrice,
            ),
          ),
        );
        if (pricingResult == null) {
          if (context.mounted) setState(() => _isSubmitting = false);
          return;
        }
        // Validate pricing data at service level before saving
        final pricingError = Validation.validateWorkerAssignment(
          workerId: _selectedWorker!.id,
          workerIsActive: _selectedWorker!.isActive,
          pricingData: pricingResult.pricingData,
          totalOrderAmount: _totalPrice,
        );
        if (pricingError != null) {
          showGlobalSnackBar(pricingError, isError: true);
          if (context.mounted) setState(() => _isSubmitting = false);
          return;
        }
      }

      final newOrder = OrderModel(
        id: '',
        userId: '',
        customerId: _selectedCustomer!.id,
        status: 'pending',
        deliveryDate: _deliveryDate,
        trialDate: _trialDate,
        totalPrice: _totalPrice,
        advancePaid: advance,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: DateTime.now(),
        assignedWorkerId: _selectedWorker?.id,
        fabricReceived: _fabricReceived,
        workMode: _workMode,
        isSelfStitch: _workMode == 'self_stitch',
        workerAssignmentStatus: _workMode == 'worker_assigned' ? 'assigned' : 'not_assigned',
      );

      final success = await orderProvider.createOrder(newOrder, _items);
      if (success && context.mounted) {
        // â”€â”€ Save Worker Pricing Data â”€â”€
        if (_workMode == 'worker_assigned' && _selectedWorker != null && pricingResult != null) {
          final wp = WorkerProviderWrapper.of(context, listen: false);
          final createdOrder = orderProvider.orders.firstWhere(
            (o) => o.customerId == _selectedCustomer!.id && o.createdAt.isAfter(DateTime.now().subtract(const Duration(seconds: 10))),
            orElse: () => newOrder,
          );
          await wp.assignWorkerWithPricing(
            workerId: _selectedWorker!.id,
            orderId: createdOrder.id,
            pricingData: pricingResult.pricingData,
          );
        }

        for (final item in _items) {
          final config = _fabricConfigs[item.id];
          if (config != null && config.source == 'SHOP' && config.shopFabricId != null) {
            final qty = double.tryParse(config.quantityController.text) ?? 0;
            if (qty > 0) {
              await fabricProvider.allocateFabric(
                orderItemId: item.id,
                fabricSource: 'SHOP',
                shopFabricId: config.shopFabricId,
                metersAllocated: qty,
              );
            }
          }
          if (!context.mounted) return;
        }
        if (context.mounted) Navigator.pop(context);
      }
    } finally {
      if (context.mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = CustomerProviderWrapper.of(context);
    final workerProvider = WorkerProviderWrapper.of(context);
    final fabricProvider = FabricProviderWrapper.of(context);
    final brandOrange = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: DesignSystem.surface,
      appBar: AppBar(
        title: Text('New Order', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: false,
        backgroundColor: DesignSystem.surfaceContainerLowest,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: DesignSystem.charcoal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            DesignSystem.gridMargin,
            DesignSystem.gridMargin,
            DesignSystem.gridMargin,
            DesignSystem.gridMargin + effectiveBottomPadding(context),
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedContent(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DesignSystem.lg),

              // â”€â”€ Section: Customer Info â”€â”€
              _buildSection(
                icon: Icons.person_rounded,
                title: 'Customer Info',
                child: Column(
                  children: [
                    AppDropdown<Customer>(
                      value: _selectedCustomer,
                      label: 'Select Customer',
                      hint: 'Select Customer',
                      prefixIcon: Icons.person_rounded,
                      items: [
                        if (_selectedCustomer != null && !customerProvider.customers.any((c) => c.id == _selectedCustomer!.id))
                          DropdownMenuItem<Customer>(
                            value: _selectedCustomer,
                            child: Text('${_selectedCustomer!.name} (${_selectedCustomer!.phone})'),
                          ),
                        ...customerProvider.customers.map((c) => DropdownMenuItem<Customer>(
                          value: c,
                          child: Text('${c.name} (${c.phone})'),
                        )),
                      ],
                      onChanged: (val) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() => _selectedCustomer = val);
                      },
                    ),
                    const SizedBox(height: DesignSystem.s8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerScreen()));
                          if (!context.mounted) return;
                          if (result != null && result is Customer) {
                            await customerProvider.fetchCustomers();
                            if (!context.mounted) return;
                            setState(() {
                              _selectedCustomer = customerProvider.customers.firstWhere(
                                (c) => c.id == result.id,
                                orElse: () => result,
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: Text('Add New Customer', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                        style: TextButton.styleFrom(foregroundColor: DesignSystem.primaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignSystem.lg),

              // â”€â”€ Section: Product / Items with per-item Fabric â”€â”€
              _buildSection(
                icon: Icons.shopping_bag_rounded,
                title: 'Product / Items',
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Garments (${_items.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ElevatedButton.icon(
                          onPressed: _showAddItemDialog,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text('Add Item', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignSystem.primaryContainer,
                            foregroundColor: DesignSystem.surfaceContainerLowest,
                            padding: const EdgeInsets.symmetric(horizontal: DesignSystem.s16, vertical: DesignSystem.s8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusMd)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_items.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: DesignSystem.xl),
                        decoration: BoxDecoration(
                          color: DesignSystem.surface,
                          borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
                          border: Border.all(color: DesignSystem.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 40, color: DesignSystem.secondary.withValues(alpha: 0.3)),
                            const SizedBox(height: DesignSystem.s8),
                            Text('No items added yet', style: GoogleFonts.manrope(color: DesignSystem.secondary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: DesignSystem.s4),
                            Text('Tap "Add Item" to add garments', style: GoogleFonts.manrope(color: DesignSystem.secondary.withValues(alpha: 0.6), fontSize: 12)),
                          ],
                        ),
                      )
                    else
                      ..._items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final fabricConfig = _getOrCreateFabricConfig(item.id);
                        final isShopStock = fabricConfig.source == 'SHOP';
                        final selectedFabric = fabricConfig.shopFabricId != null
                            ? fabricProvider.shopFabrics.where((f) => f.id == fabricConfig.shopFabricId).firstOrNull
                            : null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: DesignSystem.s12),
                          padding: const EdgeInsets.all(DesignSystem.s14),
                          decoration: DesignSystem.card,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: number, name, price, delete
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: DesignSystem.primaryContainer.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                                    ),
                                    child: Center(child: Text('${index + 1}', style: GoogleFonts.manrope(color: DesignSystem.primaryContainer, fontWeight: FontWeight.w900, fontSize: 16))),
                                  ),
                                  const SizedBox(width: DesignSystem.s12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.productName, style: DesignSystem.cardTitle),
                                        Text('Qty: ${item.quantity} x ₹${item.unitPrice.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: DesignSystem.secondary, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Text('₹${(item.quantity * item.unitPrice).toStringAsFixed(0)}', style: GoogleFonts.manrope(fontWeight: FontWeight.w900, fontSize: 15)),
                                  const SizedBox(width: DesignSystem.s4),
                                  InkWell(
                                    onTap: () => _removeItem(item),
                                    borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
                                    child: Padding(
                                      padding: const EdgeInsets.all(DesignSystem.s6),
                                      child: Icon(Icons.close_rounded, size: 20, color: DesignSystem.error.withValues(alpha: 0.6)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Fabric source selection
                              Row(
                                children: [
                                  _buildSourceChip('CUSTOMER', 'Customer', fabricConfig, brandOrange),
                                  const SizedBox(width: 8),
                                  _buildSourceChip('SHOP', 'Shop Stock', fabricConfig, brandOrange),
                                ],
                              ),

                              // Shop stock fabric selection (shown only when SHOP is selected)
                              if (isShopStock) ...[
                                const SizedBox(height: 10),
                                AppDropdown<String?>(
                                  value: fabricConfig.shopFabricId,
                                  label: 'Select Fabric',
                                  hint: 'Choose fabric',
                                  prefixIcon: Icons.inventory_2_rounded,
                                  items: [
                                    const DropdownMenuItem<String?>(value: null, child: Text('Choose fabric', style: TextStyle(fontSize: 13))),
                                    ...fabricProvider.shopFabrics.map((f) {
                                      final isLowStock = f.quantityMeters <= 5;
                                      return DropdownMenuItem<String?>(
                                        value: f.id,
                                        child: Text(
                                          '${f.name} (${f.quantityMeters}m left)',
                                          style: TextStyle(fontSize: 13, color: isLowStock ? Colors.red.shade700 : null),
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) {
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    setState(() => fabricConfig.shopFabricId = val);
                                  },
                                ),
                                if (fabricConfig.shopFabricId != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: fabricConfig.quantityController,
                                          decoration: InputDecoration(
                                            labelText: 'Meters Required',
                                            prefixIcon: const Icon(Icons.straighten_rounded, size: 18),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (selectedFabric != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Stock: ${selectedFabric.quantityMeters}m',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: selectedFabric.quantityMeters <= 5 ? Colors.red : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (fabricConfig.quantityController.text.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    _buildStockIndicator(fabricConfig, selectedFabric),
                                  ],
                                ],
                                if (fabricProvider.shopFabrics.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 12, color: Colors.orange.shade700),
                                        const SizedBox(width: 4),
                                        Text('No fabrics in inventory. Add from Inventory screen.', style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: DesignSystem.lg),

              // â”€â”€ Section: Measurements â”€â”€
              _buildSection(
                icon: Icons.straighten_rounded,
                title: 'Measurements',
                child: Column(
                  children: [
                    if (_selectedCustomer == null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text('Select a customer and add items first', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          ],
                        ),
                      )
                    else if (_items.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text('Add items to take measurements', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: _items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _navigateToMeasurements(item),
                                icon: const Icon(Icons.straighten_rounded, size: 16),
                                label: const Text('Measure', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: brandOrange,
                                  side: BorderSide(color: brandOrange.withValues(alpha: 0.4)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // â”€â”€ Section: Delivery & Trial Dates â”€â”€
            _buildSection(
              icon: Icons.calendar_month_rounded,
              title: 'Delivery & Trial Dates',
              child: Column(
                children: [
                  // Delivery Date Picker
                  InkWell(
                    onTap: () => _selectDate(context, false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _deliveryDate == null ? DesignSystem.creamBg : DesignSystem.primaryContainer.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _deliveryDate == null ? DesignSystem.border : DesignSystem.primaryContainer.withValues(alpha: 0.3),
                          width: _deliveryDate == null ? 1 : 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_rounded,
                            size: 20,
                            color: _deliveryDate == null ? DesignSystem.muted : DesignSystem.primaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery Date',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: DesignSystem.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _deliveryDate != null
                                      ? DateFormat('dd MMM, yyyy').format(_deliveryDate!)
                                      : 'Tap to select delivery date',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _deliveryDate != null ? DesignSystem.charcoal : DesignSystem.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: DesignSystem.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Trial/Fitting Date Picker
                  InkWell(
                    onTap: () => _selectDate(context, true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _trialDate == null ? DesignSystem.creamBg : Colors.purple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _trialDate == null ? DesignSystem.border : Colors.purple.withValues(alpha: 0.3),
                          width: _trialDate == null ? 1 : 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.accessibility_new_rounded,
                            size: 20,
                            color: _trialDate == null ? DesignSystem.muted : Colors.purple,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trial / Fitting Date',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: DesignSystem.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _trialDate != null
                                      ? DateFormat('dd MMM, yyyy').format(_trialDate!)
                                      : 'Optional \u2014 Tap to select',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _trialDate != null ? DesignSystem.charcoal : DesignSystem.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: DesignSystem.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_trialDate != null && _deliveryDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 12, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Trial is ${_deliveryDate!.difference(_trialDate!).inDays} day(s) before delivery',
                            style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DesignSystem.lg),

            // â”€â”€ Section: Work Mode â”€â”€
            _buildSection(
              icon: Icons.handyman_rounded,
              title: 'Who will stitch this order?',
              child: Column(
                children: [
                  // Self-Stitch Option
                  _buildWorkModeOption(
                    value: 'self_stitch',
                    title: 'I will stitch this order',
                    subtitle: 'Tailor/shop will handle stitching internally',
                    icon: Icons.person_rounded,
                    brandOrange: brandOrange,
                  ),
                  const SizedBox(height: 12),
                  // Assign Worker Option
                  _buildWorkModeOption(
                    value: 'worker_assigned',
                    title: 'Assign to Worker',
                    subtitle: 'Give this order to a worker with product-wise rates',
                    icon: Icons.group_rounded,
                    brandOrange: brandOrange,
                  ),
                  if (_workMode == 'worker_assigned') ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // Worker Selection Dropdown
                    AppDropdown<String>(
                      value: _selectedWorker?.id,
                      label: 'Select Worker',
                      hint: 'Select Worker',
                      prefixIcon: Icons.engineering_rounded,
                      items: workerProvider.workers.map((w) {
                        return DropdownMenuItem<String>(
                          value: w.id,
                          child: Text('${w.name} (${w.salaryType.name})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() {
                          _selectedWorker = val != null
                              ? workerProvider.workers.firstWhere((w) => w.id == val, orElse: () => _selectedWorker!)
                              : null;
                        });
                      },
                    ),
                    if (workerProvider.workers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 12, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text('No workers registered. Add from Workshop tab.', style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: DesignSystem.lg),

            // â”€â”€ Section: Payment â”€â”€
            _buildSection(
              icon: Icons.payments_rounded,
              title: 'Payment',
              child: Column(
                children: [
                    TextField(
                      controller: _advanceController,
                      decoration: InputDecoration(
                        labelText: 'Advance Paid',
                        prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                        filled: true,
                        fillColor: DesignSystem.creamBg,
                        border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(15))),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Pending Balance',
                      '₹${_pendingBalance.toStringAsFixed(0)}',
                      isTotal: true,
                      color: _pendingBalance > 0 ? Colors.red : Colors.green,
                    ),
                    if (_pendingBalance > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 12, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Balance must be cleared before delivery',
                              style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: DesignSystem.xl),

              // â”€â”€ Submit Button â”€â”€
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignSystem.primaryContainer,
                    foregroundColor: DesignSystem.surfaceContainerLowest,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusLg)),
                    disabledBackgroundColor: DesignSystem.secondary.withValues(alpha: 0.3),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(DesignSystem.surfaceContainerLowest)))
                      : Text(
                          'CREATE ORDER \u2014 ₹${_totalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                        ),
                ),
              ),
              SizedBox(height: effectiveBottomPadding(context)),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildSourceChip(String value, String label, _ItemFabricConfig config, Color brandOrange) {
    final isSelected = config.source == value;
    return GestureDetector(
      onTap: () => setState(() {
        config.source = value;
        if (value == 'CUSTOMER') {
          config.shopFabricId = null;
          config.quantityController.text = '0';
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? brandOrange.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? brandOrange : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value == 'CUSTOMER' ? Icons.person_rounded : Icons.store_rounded,
              size: 14,
              color: isSelected ? brandOrange : Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? brandOrange : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockIndicator(_ItemFabricConfig config, ShopFabricModel? selectedFabric) {
    final qty = double.tryParse(config.quantityController.text) ?? 0;
    if (selectedFabric == null || qty <= 0) return const SizedBox.shrink();

    final available = selectedFabric.quantityMeters;
    final isExceeded = qty > available;
    final isLow = qty > available * 0.8;

    return Row(
      children: [
        Icon(
          isExceeded ? Icons.error_outline : (isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline),
          size: 14,
          color: isExceeded ? Colors.red : (isLow ? Colors.orange : Colors.green),
        ),
        const SizedBox(width: 4),
        Text(
          isExceeded
              ? 'Exceeds stock by ${(qty - available).toStringAsFixed(1)}m'
              : isLow
                  ? 'Uses ${((qty / available) * 100).toStringAsFixed(0)}% of available stock'
                  : 'Sufficient stock available',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isExceeded ? Colors.red : (isLow ? Colors.orange : Colors.green.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkModeOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color brandOrange,
  }) {
    final isSelected = _workMode == value;
    return GestureDetector(
      onTap: () => setState(() => _workMode = value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? brandOrange.withValues(alpha: 0.08) : DesignSystem.creamBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? brandOrange : DesignSystem.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? brandOrange.withValues(alpha: 0.15) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? brandOrange : DesignSystem.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isSelected ? brandOrange : DesignSystem.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: DesignSystem.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? brandOrange : DesignSystem.border,
                  width: 2,
                ),
                color: isSelected ? brandOrange : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child, IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignSystem.md),
      decoration: DesignSystem.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(DesignSystem.s8),
                  decoration: BoxDecoration(
                    color: DesignSystem.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
                  ),
                  child: Icon(icon, size: 18, color: DesignSystem.primaryContainer),
                ),
                const SizedBox(width: DesignSystem.s10),
              ],
              Text(
                title.toUpperCase(),
                style: DesignSystem.sectionTitle,
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.md),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              fontSize: isTotal ? 22 : 16,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
