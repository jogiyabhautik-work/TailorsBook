import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../l10n/static_en.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/responsive.dart';
import 'login_screen.dart';
import '../home/home_page.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shopController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _stateController = TextEditingController();
  
  String _tailorType = 'Both';
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _shopController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final shop = _shopController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final pin = _pinCodeController.text.trim();
    final state = _stateController.text.trim();

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'shop_name': shop,
          'phone': phone,
          'tailor_type': _tailorType,
          'address': address,
          'pincode': pin,
          'state': state,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Registration failed. Please try again.');
      }

      // Insert into the public tailors table
      // We do this BEFORE context.mounted check because it's a critical data step.
      // But we need context for navigation later.
      await supabase.from('tailors').insert({
        'id': user.id,
        'full_name': name,
        'shop_name': shop,
        'phone': phone,
        'tailor_type': _tailorType,
        'address': address,
        'pincode': pin,
        'state': state,
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(StaticEnglish.regSuccess),
          backgroundColor: DesignSystem.tertiaryContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage(title: 'TailorsBook')),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: DesignSystem.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      debugPrint('Registration Error: $error');
      if (context.mounted) {
        final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.unexpectedError ?? 'An unexpected error occurred during registration'),
            backgroundColor: DesignSystem.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: DesignSystem.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: DesignSystem.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: DesignSystem.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedContent(
            maxWidth: 600,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignSystem.s28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: DesignSystem.s10),
                    Container(
                      padding: const EdgeInsets.all(DesignSystem.s12),
                      decoration: BoxDecoration(
                        color: DesignSystem.creamBg,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                      ),
                      child: Image.asset(
                        'assets/icons/TailorsBook_icon_square.png',
                        height: 48, width: 48, fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: DesignSystem.s20),
                    Text(
                      StaticEnglish.createProfile,
                      style: DesignSystem.pageTitle.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: DesignSystem.s12),
                    Text(
                      StaticEnglish.registerSubtitle,
                      style: TextStyle(color: DesignSystem.muted, fontSize: 15),
                    ),
                    const SizedBox(height: DesignSystem.s36),

                    _buildSectionHeader(StaticEnglish.accountBasics),
                    _buildInput(
                      controller: _nameController,
                      label: StaticEnglish.fullName,
                      icon: Icons.person_outline_rounded,
                      hint: 'e.g., Ahmed Khan',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your full name';
                        if (value.trim().length < 3) return 'Name must be at least 3 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignSystem.s20),
                    _buildInput(
                      controller: _phoneController,
                      label: StaticEnglish.phone,
                      icon: Icons.phone_android_rounded,
                      hint: 'e.g., 9876543210',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your phone number';
                        if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) return 'Please enter a valid 10-digit phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignSystem.s20),
                    _buildInput(
                      controller: _emailController,
                      label: StaticEnglish.shopEmail,
                      icon: Icons.alternate_email_rounded,
                      hint: 'ahmed@royaltailors.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) return 'Please enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignSystem.s20),
                    _buildInput(
                      controller: _passwordController,
                      label: StaticEnglish.choosePassword,
                      icon: Icons.lock_open_rounded,
                      hint: '••••••••',
                      isPassword: true,
                      obscure: _obscureText,
                      onToggle: () => setState(() => _obscureText = !_obscureText),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please choose a password';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),

                    _buildSectionHeader(StaticEnglish.storeDetails),
                    _buildInput(
                      controller: _shopController,
                      label: 'SHOP NAME',
                      icon: Icons.storefront_rounded,
                      hint: 'e.g., Royal Tailors & Co.',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your shop name';
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignSystem.s20),
                    _buildTailorTypeSelector(),

                    _buildSectionHeader(StaticEnglish.location),
                    _buildInput(
                      controller: _addressController,
                      label: StaticEnglish.storeAddress,
                      icon: Icons.map_outlined,
                      hint: 'Street, Area, Building',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your store address';
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignSystem.s20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align fields to top to handle error messages gracefully
                      children: [
                        Expanded(
                          child: _buildInput(
                            controller: _pinCodeController,
                            label: StaticEnglish.pinCode,
                            icon: Icons.pin_drop_outlined,
                            hint: 'e.g., 400001',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) return 'Invalid PIN';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: DesignSystem.s20),
                        Expanded(
                          child: _buildInput(
                            controller: _stateController,
                            label: StaticEnglish.state,
                            icon: Icons.location_city_rounded,
                            hint: 'e.g., Maharashtra',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: DesignSystem.s40),

                    SizedBox(
                      width: double.infinity,
                      height: DesignSystem.s56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: DesignSystem.primaryButton(DesignSystem.charcoal).copyWith(
                          shadowColor: WidgetStatePropertyAll(DesignSystem.charcoal.withValues(alpha: 0.12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: DesignSystem.white, strokeWidth: 2))
                            : Text(StaticEnglish.getStarted, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      ),
                    ),

                    const SizedBox(height: DesignSystem.s40),

                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(StaticEnglish.newToApp, style: TextStyle(color: DesignSystem.muted)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                            child: Text(
                              StaticEnglish.loginInstead,
                              style: TextStyle(color: brandOrange, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignSystem.s48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: DesignSystem.s28, bottom: DesignSystem.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: DesignSystem.charcoal,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: DesignSystem.s4),
          Container(
            width: 36, height: 3,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTailorTypeSelector() {
    final brandOrange = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StaticEnglish.tailorType,
          style: TextStyle(
            color: DesignSystem.muted,
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: DesignSystem.s12),
        Row(
          children: ['Ladies', 'Gents', 'Both'].map((type) {
            bool isSelected = _tailorType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tailorType = type),
                child: Container(
                  margin: EdgeInsets.only(right: type == 'Both' ? 0 : DesignSystem.s8),
                  padding: const EdgeInsets.symmetric(vertical: DesignSystem.s12),
                  decoration: BoxDecoration(
                    color: isSelected ? brandOrange : DesignSystem.creamBg,
                    borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                    border: isSelected ? null : Border.all(color: DesignSystem.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? DesignSystem.white : DesignSystem.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final brandOrange = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: DesignSystem.muted,
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: DesignSystem.s8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: DesignSystem.outlineVariant, fontSize: 14, fontWeight: FontWeight.w400),
            prefixIcon: Icon(icon, color: brandOrange, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: DesignSystem.muted),
                    onPressed: onToggle,
                  )
                : null,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: DesignSystem.border, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: brandOrange, width: 1.5),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: DesignSystem.error, width: 1.5),
            ),
            focusedErrorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: DesignSystem.error, width: 2.0),
            ),
            errorStyle: const TextStyle(fontSize: 12, height: 1.2),
            contentPadding: const EdgeInsets.symmetric(vertical: DesignSystem.s12),
          ),
        ),
      ],
    );
  }
}
