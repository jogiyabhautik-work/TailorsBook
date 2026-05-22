import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/responsive_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/validation.dart';
import '../../core/utils/storage_helper.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EditProfileScreen({super.key, required this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _shopNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _pincodeController;
  late TextEditingController _emailController;
  late TextEditingController _gstController;
  String? _tailorType;
  String? _logoUrl;
  bool _isLoading = false;
  bool _isUploadingLogo = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['full_name']);
    _shopNameController = TextEditingController(text: widget.initialData['shop_name']);
    _phoneController = TextEditingController(text: widget.initialData['phone']);
    _addressController = TextEditingController(text: widget.initialData['address']);
    _pincodeController = TextEditingController(text: widget.initialData['pincode']);
    _emailController = TextEditingController(text: widget.initialData['email']);
    _gstController = TextEditingController(text: widget.initialData['gst_number']);
    _logoUrl = widget.initialData['shop_logo_url'];
    _tailorType = widget.initialData['tailor_type'] ?? 'Both';

    _nameController.addListener(_markChanged);
    _shopNameController.addListener(_markChanged);
    _phoneController.addListener(_markChanged);
    _addressController.addListener(_markChanged);
    _pincodeController.addListener(_markChanged);
    _emailController.addListener(_markChanged);
    _gstController.addListener(_markChanged);
  }

  File? _lastPickedLogoFile;

  Future<void> _uploadLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile == null) return;
    _lastPickedLogoFile = File(pickedFile.path);
    await _uploadLogoFromFile(_lastPickedLogoFile!);
  }

  Future<void> _uploadLogoFromFile(File file) async {
    setState(() => _isUploadingLogo = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // Compression validation is already built-in in StorageHelper
      final logoUrl = await StorageHelper.uploadShopLogo(file, userId);
      
      if (logoUrl != null) {
        await supabase.auth.updateUser(
          UserAttributes(data: {'shop_logo_url': logoUrl}),
        );
        
        final currentUserId = supabase.auth.currentUser?.id;
        if (currentUserId != null) {
          await supabase.from('tailors').update({'shop_logo_url': logoUrl}).eq('id', currentUserId);
        }

        setState(() {
          _logoUrl = logoUrl;
          _hasChanges = true;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo uploaded successfully!'), backgroundColor: DesignSystem.success),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to upload logo.'),
              backgroundColor: DesignSystem.error,
              action: SnackBarAction(
                label: 'RETRY',
                textColor: DesignSystem.white,
                onPressed: () {
                  if (_lastPickedLogoFile != null) {
                    _uploadLogoFromFile(_lastPickedLogoFile!);
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('EditProfileScreen Logo Upload Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile update failed. Please try again.'),
            backgroundColor: DesignSystem.error,
            action: SnackBarAction(
              label: 'RETRY',
              textColor: DesignSystem.white,
              onPressed: () {
                if (_lastPickedLogoFile != null) {
                  _uploadLogoFromFile(_lastPickedLogoFile!);
                }
              },
            ),
          ),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _removeLogo() async {
    setState(() => _isUploadingLogo = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      await StorageHelper.deleteShopLogo(userId);

      await supabase.auth.updateUser(
        UserAttributes(data: {'shop_logo_url': null}),
      );
      
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        await supabase.from('tailors').update({'shop_logo_url': null}).eq('id', currentUserId);
      }

      setState(() {
        _logoUrl = null;
        _hasChanges = true;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo removed successfully!'), backgroundColor: DesignSystem.success),
        );
      }
    } catch (e) {
      debugPrint('EditProfileScreen Logo Remove Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove logo. Please try again.'), backgroundColor: DesignSystem.error),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isUploadingLogo = false);
    }
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final shouldDiscard = await showResponsiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusLg)),
        title: const Text('Discard Changes?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CONTINUE EDITING', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DISCARD', style: TextStyle(fontWeight: FontWeight.w700, color: DesignSystem.error)),
          ),
        ],
      ),
    );
    return shouldDiscard ?? false;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updates = {
        'full_name': _nameController.text.trim(),
        'shop_name': _shopNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'email': _emailController.text.trim(),
        'gst_number': _gstController.text.trim(),
        'tailor_type': _tailorType,
      };

      debugPrint('EditProfileScreen: Auth update payload: $updates');
      await supabase.auth.updateUser(
        UserAttributes(data: updates),
      );

      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        // email is auth-only; not a column in the public.tailors table
        final tailorsUpdates = Map<String, dynamic>.from(updates);
        tailorsUpdates.remove('email');
        debugPrint('EditProfileScreen: Tailors table update payload: $tailorsUpdates');
        await supabase.from('tailors').update(tailorsUpdates).eq('id', userId);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: DesignSystem.success),
        );
        Navigator.pop(context, true);
      }
    } on PostgrestException catch (e) {
      debugPrint('EditProfileScreen PostgrestException: ${e.message}');
      debugPrint('EditProfileScreen PostgrestException details: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile update failed. Please try again.'), backgroundColor: DesignSystem.error),
        );
      }
    } catch (e) {
      debugPrint('EditProfileScreen Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile. Please try again.'), backgroundColor: DesignSystem.error),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldDiscard = await _onWillPop();
        if (shouldDiscard && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: DesignSystem.white,
        appBar: AppBar(
          title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          backgroundColor: DesignSystem.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: DesignSystem.charcoal,
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DesignSystem.s24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Shop Logo Upload Section
                    GestureDetector(
                      onTap: _isUploadingLogo ? null : _uploadLogo,
                      child: Container(
                        width: DesignSystem.s120,
                        height: DesignSystem.s120,
                        decoration: BoxDecoration(
                          color: DesignSystem.creamBg,
                          borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
                          border: Border.all(color: brandOrange.withValues(alpha: 0.3), width: 2),
                        ),
                        child: _isUploadingLogo
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text('Uploading...', style: TextStyle(fontSize: 11, color: DesignSystem.muted)),
                                ],
                              )
                            : _logoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                                    child: Image.network(
                                      _logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate_rounded, size: 36, color: DesignSystem.muted),
                                          SizedBox(height: 4),
                                          Text('Tap to upload', style: TextStyle(fontSize: 11, color: DesignSystem.muted)),
                                        ],
                                      ),
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_rounded, size: 36, color: DesignSystem.muted),
                                      SizedBox(height: 4),
                                      Text('Tap to upload logo', style: TextStyle(fontSize: 11, color: DesignSystem.muted)),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: DesignSystem.s8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _logoUrl != null ? 'Tap to change logo' : 'Upload shop logo',
                          style: TextStyle(fontSize: 12, color: DesignSystem.muted, fontWeight: FontWeight.w600),
                        ),
                        if (_logoUrl != null) ...[
                          const SizedBox(width: DesignSystem.s16),
                          GestureDetector(
                            onTap: _isUploadingLogo ? null : _removeLogo,
                            child: const Text(
                              'Remove',
                              style: TextStyle(fontSize: 12, color: DesignSystem.error, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: DesignSystem.s24),
                    _buildTextField(_nameController, 'Full Name', Icons.person_rounded, required: true),
                    const SizedBox(height: DesignSystem.s16),
                    _buildTextField(_shopNameController, 'Shop Name', Icons.store_rounded, required: false),
                    const SizedBox(height: DesignSystem.s16),
                    _buildTextField(_phoneController, 'Phone Number', Icons.phone_rounded, keyboardType: TextInputType.phone, required: true),
                    const SizedBox(height: DesignSystem.s16),
                    _buildTextField(_emailController, 'Email Address', Icons.email_rounded, keyboardType: TextInputType.emailAddress, required: false),
                    const SizedBox(height: DesignSystem.s16),
                    _buildTextField(_addressController, 'Shop Address', Icons.location_on_rounded, maxLines: 3, required: false),
                    const SizedBox(height: DesignSystem.s16),
                    _buildTextField(_pincodeController, 'Pincode', Icons.pin_rounded, keyboardType: TextInputType.number, required: false),
                    const SizedBox(height: DesignSystem.s16),
                    _buildTextField(_gstController, 'GST Number', Icons.receipt_long_rounded, required: false),
                    const SizedBox(height: DesignSystem.s24),

                    // Tailor Type Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: DesignSystem.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                        border: Border.all(color: DesignSystem.outlineVariant),
                      ),
                      child: AppDropdown<String>(
                        value: _tailorType,
                        label: 'Specialization',
                        hint: 'Select specialization',
                        prefixIcon: Icons.category_rounded,
                        items: ['Both', 'Ladies', 'Gents'].map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        )).toList(),
                        onChanged: (val) {
                          FocusManager.instance.primaryFocus?.unfocus();
                          setState(() => _tailorType = val);
                        },
                      ),
                    ),

                    const SizedBox(height: DesignSystem.s40),
                    SizedBox(
                      width: double.infinity,
                      height: DesignSystem.s56,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: DesignSystem.primaryButton(brandOrange).copyWith(elevation: WidgetStatePropertyAll(0)),
                        child: const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: DesignSystem.creamBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
        ),
      ),
      validator: (val) {
        final value = val?.trim() ?? '';

        if (required && value.isEmpty) {
          return 'This field is required';
        }

        if (value.isEmpty) return null;

        if (keyboardType == TextInputType.phone) {
          return Validation.validatePhone(value);
        }

        if (keyboardType == TextInputType.emailAddress) {
          final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
          if (!emailRegex.hasMatch(value)) {
            return 'Enter a valid email address';
          }
        }

        if (label == 'Pincode') {
          return Validation.validatePincode(value);
        }

        if (label == 'GST Number') {
          return Validation.validateGST(value);
        }

        return null;
      },
    );
  }
}
