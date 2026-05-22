import 'package:flutter/material.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../core/utils/design_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../models/order_model.dart';
import '../../models/customer_model.dart';
import '../../core/utils/invoice_helper.dart';

class InvoiceCustomizationScreen extends StatefulWidget {
  const InvoiceCustomizationScreen({super.key});

  @override
  State<InvoiceCustomizationScreen> createState() => _InvoiceCustomizationScreenState();
}

class _InvoiceCustomizationScreenState extends State<InvoiceCustomizationScreen> {
  final _welcomeController = TextEditingController();
  final _termsController = TextEditingController();
  final _paymentController = TextEditingController();
  
  bool _showAddress = true;
  bool _showPhone = true;
  bool _showGST = true;
  bool _showCustomerPhone = true;
  bool _showItemPrices = true;
  bool _showStatus = true;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _welcomeController.addListener(_markChanged);
    _termsController.addListener(_markChanged);
    _paymentController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    _termsController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final shouldDiscard = await showResponsiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard Changes?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('You have unsaved invoice customization changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CONTINUE EDITING', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DISCARD', style: TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.error)),
          ),
        ],
      ),
    );
    return shouldDiscard ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? DesignSystem.error : DesignSystem.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _loadPreferences() {
    final user = supabase.auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _showSnackBar('User session not found. Please log in again.', isError: true);
          Navigator.pop(context);
        }
      });
      return;
    }
    
    final metadata = user.userMetadata;
    
    setState(() {
      _showAddress = metadata?['pdf_show_address'] ?? true;
      _showPhone = metadata?['pdf_show_phone'] ?? true;
      _showGST = metadata?['pdf_show_gst'] ?? true;
      _showCustomerPhone = metadata?['pdf_show_customer_phone'] ?? true;
      _showItemPrices = metadata?['pdf_show_item_prices'] ?? true;
      _showStatus = metadata?['pdf_show_status'] ?? true;
      
      _welcomeController.text = metadata?['pdf_welcome_msg'] ?? 'Thank you for choosing our services! Visit again.';
      _termsController.text = metadata?['pdf_terms'] ?? '1. No returns after delivery.\n2. Please bring original bill for collection.';
      _paymentController.text = metadata?['pdf_payment_info'] ?? '';
      _isLoading = false;
    });
  }

  Future<void> _savePreferences({bool popOnSave = true}) async {
    // Validation
    if (_welcomeController.text.length > 200) {
      _showSnackBar('Welcome message cannot exceed 200 characters.', isError: true);
      return;
    }
    if (_termsController.text.length > 500) {
      _showSnackBar('Terms and conditions cannot exceed 500 characters.', isError: true);
      return;
    }
    if (_paymentController.text.length > 300) {
      _showSnackBar('Payment details cannot exceed 300 characters.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'pdf_show_address': _showAddress,
            'pdf_show_phone': _showPhone,
            'pdf_show_gst': _showGST,
            'pdf_show_customer_phone': _showCustomerPhone,
            'pdf_show_item_prices': _showItemPrices,
            'pdf_show_status': _showStatus,
            'pdf_welcome_msg': _welcomeController.text.trim(),
            'pdf_terms': _termsController.text.trim(),
            'pdf_payment_info': _paymentController.text.trim(),
          },
        ),
      );
      if (context.mounted) {
        if (popOnSave) {
          _showSnackBar('Personalization saved!');
          setState(() => _hasChanges = false);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (context.mounted && popOnSave) setState(() => _isLoading = false);
    }
  }

  Future<void> _previewInvoice() async {
    setState(() => _isLoading = true);
    await _savePreferences(popOnSave: false);
    if (!context.mounted) return;
    
    try {
      final dummyCustomer = Customer(
        id: 'dummy',
        name: 'John Doe',
        phone: '+91 9876543210',
        address: '123 Tailor Street, Fashion City',
      );

      final dummyOrder = OrderModel(
        id: '12345678-abcd',
        userId: 'dummy_user',
        customerId: 'dummy',
        status: 'stitching',
        totalPrice: 2500,
        advancePaid: 1000,
        createdAt: DateTime.now(),
        deliveryDate: DateTime.now().add(const Duration(days: 7)),
        orderToken: 'T-8492',
        items: [
          OrderItem(
            id: 'item1',
            orderId: '12345678-abcd',
            productName: 'Premium Formal Shirt',
            quantity: 2,
            unitPrice: 750,
          ),
          OrderItem(
            id: 'item2',
            orderId: '12345678-abcd',
            productName: 'Custom Trousers',
            quantity: 1,
            unitPrice: 1000,
          )
        ]
      );
      
      await InvoiceHelper.generateAndShareInvoice(order: dummyOrder, customer: dummyCustomer);
    } catch(e) {
      if (context.mounted) _showSnackBar('Preview Error: $e', isError: true);
    } finally {
      if (context.mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orange = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Personalize Invoice', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: DesignSystem.white,
        elevation: 0,
        foregroundColor: DesignSystem.charcoal,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SHOP DISPLAY OPTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DesignSystem.muted, letterSpacing: 1)),
            const SizedBox(height: 12),
            _buildToggleCard([
              _buildToggleItem('Display Shop Address', 'Show your physical location', _showAddress, (val) {
                setState(() => _showAddress = val);
                _markChanged();
              }),
              const Divider(height: 1, indent: 64),
              _buildToggleItem('Display Shop Phone', 'Show shop contact details', _showPhone, (val) {
                setState(() => _showPhone = val);
                _markChanged();
              }),
              const Divider(height: 1, indent: 64),
              _buildToggleItem('Display GST Number', 'Include tax registration', _showGST, (val) {
                setState(() => _showGST = val);
                _markChanged();
              }),
            ]),
            
            const SizedBox(height: 32),
            const Text('CUSTOMER & ITEM OPTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DesignSystem.muted, letterSpacing: 1)),
            const SizedBox(height: 12),
            _buildToggleCard([
              _buildToggleItem('Display Customer Phone', 'Show client number on bill', _showCustomerPhone, (val) {
                setState(() => _showCustomerPhone = val);
                _markChanged();
              }),
              const Divider(height: 1, indent: 64),
              _buildToggleItem('Show Item Prices', 'Display price for every garment', _showItemPrices, (val) {
                setState(() => _showItemPrices = val);
                _markChanged();
              }),
              const Divider(height: 1, indent: 64),
              _buildToggleItem('Show Order Status', 'Display Pending/Delivered status', _showStatus, (val) {
                setState(() => _showStatus = val);
                _markChanged();
              }),
            ]),

            const SizedBox(height: 32),
            _buildTextSection('INVOICE FOOTER MESSAGE', 'e.g. Visit Again!', _welcomeController),
            
            const SizedBox(height: 24),
            _buildTextSection('TERMS & CONDITIONS', 'e.g. No returns...', _termsController),
            
            const SizedBox(height: 24),
            _buildTextSection('PAYMENT DETAILS', 'e.g. GPay: 9876543210@upi', _paymentController),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _previewInvoice,
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('PREVIEW DUMMY INVOICE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: orange,
                  side: BorderSide(color: orange, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _savePreferences(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: DesignSystem.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('SAVE SETTINGS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildTextSection(String title, String hint, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DesignSystem.muted, letterSpacing: 1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: DesignSystem.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEEEEEE))),
          child: TextField(
            controller: ctrl,
            maxLines: null,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(hintText: hint, border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleItem(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: DesignSystem.muted)),
      activeThumbColor: Theme.of(context).colorScheme.primary,
    );
  }
}
