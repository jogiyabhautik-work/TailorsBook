import 'package:flutter/material.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../widgets/common/provider_wrappers.dart';
import 'package:flutter/services.dart';
import '../../core/utils/responsive.dart';
import '../../models/customer_model.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/validation.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? initialCustomer;
  const AddCustomerScreen({super.key, this.initialCustomer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSaving = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomer != null) {
      _nameController.text = widget.initialCustomer!.name;
      _phoneController.text = widget.initialCustomer!.phone;
      _addressController.text = widget.initialCustomer!.address;
    }
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveCustomer() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final customerProvider = CustomerProviderWrapper.of(context);

    try {
      if (widget.initialCustomer != null) {
        // EDIT MODE
        final updated = widget.initialCustomer!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        );
        
        final success = await customerProvider.updateCustomer(updated);
        if (success && context.mounted) {
          Navigator.pop(context, updated);
        }
        return;
      }

      // CREATE MODE
      final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final newCustomer = Customer(
        id: tempId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      final savedCustomer = await customerProvider.createCustomer(newCustomer);

      if (context.mounted && savedCustomer != null) {
        Navigator.pop(context, savedCustomer);
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialCustomer != null
                ? 'Update failed: ${e.toString()}'
                : 'Failed to save customer. Please check your connection and try again.'),
            backgroundColor: DesignSystem.error,
          ),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isSaving = false);
    }
  }

  bool _isChanged() {
    final initialName = widget.initialCustomer?.name ?? '';
    final initialPhone = widget.initialCustomer?.phone ?? '';
    final initialAddress = widget.initialCustomer?.address ?? '';

    return _nameController.text.trim() != initialName.trim() ||
        _phoneController.text.trim() != initialPhone.trim() ||
        _addressController.text.trim() != initialAddress.trim();
  }

  Future<bool> _onWillPop() async {
    if (!_isChanged()) return true;
    final shouldDiscard = await showResponsiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard Changes?', style: TextStyle(fontWeight: FontWeight.w900, color: DesignSystem.charcoal)),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CONTINUE EDITING', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
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

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    final brandBlack = DesignSystem.charcoal;
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: DesignSystem.creamBg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
            // Custom App Bar
            Container(
              padding: EdgeInsets.only(
                top: appBarTopPadding(context),
                left: 16,
                right: 16,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                color: DesignSystem.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: DesignSystem.creamBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: brandBlack),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.initialCustomer != null
                        ? (l10n?.editCustomer ?? 'Edit Customer')
                        : (l10n?.newCustomer ?? 'New Customer'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: brandBlack,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedContent(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar placeholder
                          Center(
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: brandOrange.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person_outline_rounded,
                                  size: 44, color: brandOrange),
                            ),
                          ),
                          const SizedBox(height: 32),

                          _buildLabel(l10n?.fullName ?? 'Full Name'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _nameController,
                            hint: l10n?.nameHint ?? 'e.g. Ramesh Patel',
                            icon: Icons.person_outline_rounded,
                            brandOrange: brandOrange,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return l10n?.enterNameError ?? 'Please enter customer name';
                              }
                              if (v.trim().length < 2) {
                                return l10n?.nameLengthError ?? 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _buildLabel(l10n?.phone ?? 'Phone Number'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _phoneController,
                            hint: l10n?.phoneHint ?? 'e.g. +91 98765 43210',
                            icon: Icons.phone_outlined,
                            brandOrange: brandOrange,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+\- ]')),
                            ],
                            validator: (v) {
                              final result = Validation.validatePhone(v);
                              if (result != null) {
                                return l10n?.enterPhoneError ?? result;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _buildLabel(l10n?.address ?? 'Address'),
                          const SizedBox(height: 8),
                          _buildAddressField(brandOrange: brandOrange, l10n: l10n),

                          const SizedBox(height: 40),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveCustomer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandOrange,
                                foregroundColor: DesignSystem.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                disabledBackgroundColor:
                                    brandOrange.withValues(alpha: 0.6),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: DesignSystem.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      widget.initialCustomer != null
                                          ? (l10n?.updateCustomer ?? 'Update Details')
                                          : (l10n?.saveCustomer ?? 'Save Customer'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.maybePop(context),
                              child: Text(
                                l10n?.cancel ?? 'Cancel',
                                style: TextStyle(
                                  color: DesignSystem.muted,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: screenBottomPadding(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: DesignSystem.muted,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color brandOrange,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: DesignSystem.muted, fontSize: 14),
        prefixIcon:
            Icon(icon, color: DesignSystem.muted, size: 20),
        filled: true,
        fillColor: DesignSystem.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: DesignSystem.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: DesignSystem.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: brandOrange, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DesignSystem.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: DesignSystem.error, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildAddressField({required Color brandOrange, AppLocalizations? l10n}) {
    return TextFormField(
      controller: _addressController,
      maxLines: 3,
      minLines: 3,
      validator: null,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: l10n?.addressHint ?? 'Street, Area, City, Pincode...',
        hintStyle:
            TextStyle(color: DesignSystem.muted, fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 42),
          child: Icon(Icons.location_on_outlined,
              color: DesignSystem.muted, size: 20),
        ),
        filled: true,
        fillColor: DesignSystem.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: DesignSystem.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: DesignSystem.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: brandOrange, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DesignSystem.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: DesignSystem.error, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
