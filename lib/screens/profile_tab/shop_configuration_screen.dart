import 'dart:convert';
import 'package:flutter/material.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/responsive_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../core/utils/validation.dart';
import '../../core/utils/design_system.dart';

class ShopConfigurationScreen extends StatefulWidget {
  const ShopConfigurationScreen({super.key});

  @override
  State<ShopConfigurationScreen> createState() => _ShopConfigurationScreenState();
}

class _ShopConfigurationScreenState extends State<ShopConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController(text: '₹ (INR)');
  String _selectedCategory = 'Boutique';
  
  final List<String> _categories = ['Boutique', 'Custom Tailoring', 'Alteration Shop', 'Industrial', 'Men\'s Only', 'Ladies Only'];
  
  final Map<String, Map<String, dynamic>> _shopHours = {
    'Monday': {'open': '09:00 AM', 'close': '09:00 PM', 'closed': false},
    'Tuesday': {'open': '09:00 AM', 'close': '09:00 PM', 'closed': false},
    'Wednesday': {'open': '09:00 AM', 'close': '09:00 PM', 'closed': false},
    'Thursday': {'open': '09:00 AM', 'close': '09:00 PM', 'closed': false},
    'Friday': {'open': '09:00 AM', 'close': '09:00 PM', 'closed': false},
    'Saturday': {'open': '09:00 AM', 'close': '09:00 PM', 'closed': false},
    'Sunday': {'open': '09:00 AM', 'close': '09:00 PM', 'closed': true},
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
    _gstController.addListener(_markChanged);
    _currencyController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _gstController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final shouldDiscard = await showResponsiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard Changes?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('You have unsaved shop configuration changes. Do you want to discard them?'),
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

  void _loadCurrentConfig() {
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
    if (metadata != null) {
      setState(() {
        _gstController.text = metadata['gst_number'] ?? '';
        _selectedCategory = metadata['shop_category'] ?? 'Boutique';
        _currencyController.text = metadata['currency'] ?? '₹ (INR)';
        
        if (metadata['shop_hours'] != null) {
          try {
            final Map<String, dynamic> rawHours = Map<String, dynamic>.from(metadata['shop_hours']);
            rawHours.forEach((key, value) {
              if (_shopHours.containsKey(key)) {
                _shopHours[key] = Map<String, dynamic>.from(value);
              }
            });
          } catch (e) {
            debugPrint('Error parsing shop hours: $e');
          }
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    final gstError = Validation.validateGST(_gstController.text.trim());
    if (gstError != null) {
      _showSnackBar(gstError, isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final res = await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'gst_number': _gstController.text.trim(),
            'shop_category': _selectedCategory,
            'currency': _currencyController.text.trim(),
            'shop_hours': jsonDecode(jsonEncode(_shopHours)),
            'address': '123 Tailor Street, Fashion City',
          },
        ),
      );

      if (res.user != null) {
        final metadata = res.user!.userMetadata;
        if (metadata != null && metadata['shop_hours'] != null) {
          try {
            final Map<String, dynamic> rawHours = Map<String, dynamic>.from(metadata['shop_hours']);
            setState(() {
              rawHours.forEach((key, value) {
                if (_shopHours.containsKey(key)) {
                  _shopHours[key] = Map<String, dynamic>.from(value);
                }
              });
            });
          } catch (e) {
            debugPrint('Error parsing shop hours from response: $e');
          }
        }
      }

      if (context.mounted) {
        _showSnackBar('Shop Configuration Saved!');
        setState(() => _hasChanges = false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (context.mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    final brandBlack = const Color(0xFF1C1C1C);

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
          title: const Text('Shop Configuration', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          backgroundColor: DesignSystem.white,
          elevation: 0,
          foregroundColor: brandBlack,
          actions: [
            if (_isSaving)
              const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            else
              TextButton(
                onPressed: _saveConfig,
                child: Text('SAVE', style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Business Details'),
                const SizedBox(height: 16),
                _buildModernField('GST / TAX ID', _gstController, Icons.receipt_long_rounded),
                const SizedBox(height: 16),
                _buildDropdownField('Shop Category', _selectedCategory, _categories, (val) {
                  _markChanged();
                  setState(() => _selectedCategory = val!);
                }),
                const SizedBox(height: 16),
                _buildModernField('Currency Symbol', _currencyController, Icons.payments_rounded),
                
                const SizedBox(height: 32),
                _buildSectionTitle('Operating Hours'),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: DesignSystem.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    children: _shopHours.keys.map((day) {
                      return _buildHourRow(day);
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
    );
  }

  Widget _buildModernField(String label, TextEditingController controller, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          icon: Icon(icon, color: DesignSystem.outlineVariant, size: 20),
          labelText: label,
          labelStyle: TextStyle(color: DesignSystem.muted, fontSize: 13, fontWeight: FontWeight.w600),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: AppDropdown<String>(
        value: value,
        label: label,
        items: items.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
        onChanged: (val) {
          FocusManager.instance.primaryFocus?.unfocus();
          onChanged(val);
        },
      ),
    );
  }

  Widget _buildHourRow(String day) {
    final Map<String, dynamic> data = _shopHours[day]!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Expanded(
            flex: 4,
            child: data['closed']
                ? const Center(child: Text('CLOSED', style: TextStyle(color: DesignSystem.error, fontWeight: FontWeight.w900, fontSize: 12)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(data['open'], style: TextStyle(color: DesignSystem.muted, fontSize: 13)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text('-', style: TextStyle(color: DesignSystem.muted)),
                      ),
                      Text(data['close'], style: TextStyle(color: DesignSystem.muted, fontSize: 13)),
                    ],
                  ),
          ),
          Switch.adaptive(
            value: !data['closed'],
            onChanged: (val) {
              _markChanged();
              setState(() {
                _shopHours[day] = Map<String, dynamic>.from(_shopHours[day]!);
                _shopHours[day]!['closed'] = !val;
              });
            },
            activeThumbColor: DesignSystem.success,
          ),
        ],
      ),
    );
  }
}
