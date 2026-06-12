import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/static_en.dart';
import '../../core/utils/design_system.dart';
import 'registration_screen.dart';
import 'forgot_password_screen.dart';
import '../home/home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (context.mounted) {
        if (response.user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyHomePage(title: 'TailorsBook')),
          );
        }
      }
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
      if (context.mounted) {
        final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.unexpectedError ?? 'An unexpected error occurred'),
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
    final brandBlack = const Color(0xFF1C1C1C);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: DesignSystem.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              // Top Header/Art
              Container(
                height: size.height * 0.38,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: brandBlack,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(DesignSystem.radiusXxl),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [brandBlack, const Color(0xFF2C3E50)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40, right: -40,
                      child: CircleAvatar(radius: 80, backgroundColor: brandOrange.withValues(alpha: 0.08)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.s32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(DesignSystem.s12),
                            decoration: BoxDecoration(
                              color: DesignSystem.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
                            ),
                            child: Image.asset(
                              'assets/icons/TailorsBook_icon_square.png',
                              height: 56, width: 56,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: DesignSystem.s24),
                          Text(
                            StaticEnglish.welcomeBack,
                            style: const TextStyle(
                              color: DesignSystem.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: DesignSystem.s12),
                          Text(
                            StaticEnglish.loginSubtitle,
                            style: TextStyle(color: DesignSystem.muted, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Form Section
              ConstrainedContent(
                child: Padding(
                  padding: const EdgeInsets.all(DesignSystem.s28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: DesignSystem.s20),
                        _buildTextField(
                          controller: _emailController,
                          hint: StaticEnglish.email,
                          icon: Icons.alternate_email_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Please enter your email';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) return 'Please enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: DesignSystem.s20),
                        _buildTextField(
                          controller: _passwordController,
                          hint: StaticEnglish.password,
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscure: _obscureText,
                          onToggle: () => setState(() => _obscureText = !_obscureText),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your password';
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                            child: Text(StaticEnglish.forgotPassword, style: TextStyle(color: brandOrange, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: DesignSystem.s28),
                        SizedBox(
                          width: double.infinity,
                          height: DesignSystem.s56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: DesignSystem.primaryButton(brandOrange).copyWith(
                              shadowColor: WidgetStatePropertyAll(brandOrange.withValues(alpha: 0.3)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: DesignSystem.white, strokeWidth: 2))
                                : Text(StaticEnglish.login, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                          ),
                        ),
                        const SizedBox(height: DesignSystem.s16),
                        TextButton(
                          onPressed: _isLoading ? null : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                                    SizedBox(width: 8),
                                    Text('Magic Link — Coming Soon! 🚀', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF1C1C1C),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Text(StaticEnglish.loginMagicLink, style: TextStyle(color: brandBlack.withValues(alpha: 0.4), fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: DesignSystem.s40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(StaticEnglish.newToApp, style: TextStyle(color: DesignSystem.muted)),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationScreen())),
                              child: Text(
                                StaticEnglish.registerNow,
                                style: TextStyle(color: brandBlack, fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: DesignSystem.inputField(
        hint: hint,
        prefixIcon: icon,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: DesignSystem.muted),
                onPressed: onToggle,
              )
            : null,
      ),
    );
  }
}
