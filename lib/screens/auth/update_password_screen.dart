import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../core/utils/design_system.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password must be at least 8 characters'),
          backgroundColor: DesignSystem.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: DesignSystem.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('Updating password via passwordRecovery event');
      await supabase.auth.updateUser(
        UserAttributes(password: password),
      );
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password updated successfully!'),
            backgroundColor: DesignSystem.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        // Navigate back to login screen, popping all current routes
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: DesignSystem.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Something went wrong. Please try again.'),
            backgroundColor: DesignSystem.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: DesignSystem.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Premium Dark Header ──────────────────────────────────────────
            Container(
              height: size.height * 0.36,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1C1C1C), Color(0xFF2C3E50)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(DesignSystem.radiusXxl),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -40, right: -40,
                    child: CircleAvatar(radius: 80, backgroundColor: brandOrange.withValues(alpha: 0.07)),
                  ),
                  Positioned(
                    bottom: -20, left: -20,
                    child: CircleAvatar(radius: 50, backgroundColor: brandOrange.withValues(alpha: 0.04)),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.s24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          // Key icon
                          Container(
                            padding: const EdgeInsets.all(DesignSystem.s16),
                            decoration: BoxDecoration(
                              color: brandOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
                              border: Border.all(color: brandOrange.withValues(alpha: 0.25)),
                            ),
                            child: Icon(Icons.password_rounded, color: brandOrange, size: 28),
                          ),
                          const SizedBox(height: DesignSystem.s20),
                          const Text(
                            'Update\nPassword',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: DesignSystem.s12),
                          Text(
                            'Enter and confirm your new password below.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.5),
                          ),
                          const SizedBox(height: DesignSystem.s24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Form State ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(DesignSystem.s28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildFormState(brandOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormState(Color brandOrange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: DesignSystem.s8),
        Text(
          'New Password',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: DesignSystem.charcoal,
          ),
        ),
        const SizedBox(height: DesignSystem.s8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: DesignSystem.inputField(
            hint: 'Min. 8 characters',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: DesignSystem.muted, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: DesignSystem.s20),
        Text(
          'Confirm Password',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: DesignSystem.charcoal,
          ),
        ),
        const SizedBox(height: DesignSystem.s8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _updatePassword(),
          decoration: DesignSystem.inputField(
            hint: 'Re-enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: DesignSystem.muted, size: 20),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: DesignSystem.s32),
        SizedBox(
          width: double.infinity,
          height: DesignSystem.s56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updatePassword,
            style: DesignSystem.primaryButton(brandOrange).copyWith(
              shadowColor: WidgetStatePropertyAll(brandOrange.withValues(alpha: 0.3)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'UPDATE PASSWORD',
                        style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
