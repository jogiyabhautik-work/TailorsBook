import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../core/utils/design_system.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
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
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your email address'),
          backgroundColor: DesignSystem.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid email address'),
          backgroundColor: DesignSystem.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('Requesting password reset for: $email with redirect');
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.tailorsbook://login-callback/',
      );
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
        _animController.reset();
        _animController.forward();
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                          const SizedBox(height: 8),
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                          const Spacer(),
                          // Lock icon
                          Container(
                            padding: const EdgeInsets.all(DesignSystem.s16),
                            decoration: BoxDecoration(
                              color: brandOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
                              border: Border.all(color: brandOrange.withValues(alpha: 0.25)),
                            ),
                            child: Icon(Icons.lock_reset_rounded, color: brandOrange, size: 28),
                          ),
                          const SizedBox(height: DesignSystem.s20),
                          const Text(
                            'Forgot\nPassword?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: DesignSystem.s12),
                          Text(
                            'Enter your registered email and we\'ll send\na reset link straight to your inbox.',
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

            // ── Form / Success State ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(DesignSystem.s28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _emailSent ? _buildSuccessState(brandOrange) : _buildFormState(brandOrange),
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
          'Email Address',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: DesignSystem.charcoal,
          ),
        ),
        const SizedBox(height: DesignSystem.s8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendResetLink(),
          decoration: DesignSystem.inputField(
            hint: 'your@email.com',
            prefixIcon: Icons.alternate_email_rounded,
          ),
        ),
        const SizedBox(height: DesignSystem.s32),
        SizedBox(
          width: double.infinity,
          height: DesignSystem.s56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendResetLink,
            style: DesignSystem.primaryButton(brandOrange).copyWith(
              shadowColor: WidgetStatePropertyAll(brandOrange.withValues(alpha: 0.3)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'SEND RESET LINK',
                        style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: DesignSystem.s20),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '← Back to Login',
              style: GoogleFonts.manrope(
                color: DesignSystem.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(Color brandOrange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: DesignSystem.s8),
        // Success icon
        Container(
          padding: const EdgeInsets.all(DesignSystem.s28),
          decoration: BoxDecoration(
            color: DesignSystem.tertiaryContainer.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: DesignSystem.tertiaryContainer.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(Icons.mark_email_read_rounded, color: DesignSystem.tertiaryContainer, size: 48),
        ),
        const SizedBox(height: DesignSystem.s24),
        Text(
          'Check Your Inbox!',
          style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: DesignSystem.charcoal),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignSystem.s12),
        Text(
          'We\'ve sent a password reset link to\n${_emailController.text.trim()}',
          style: GoogleFonts.manrope(fontSize: 14, color: DesignSystem.muted, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignSystem.s8),
        Text(
          'Didn\'t receive it? Check your spam folder.',
          style: GoogleFonts.manrope(fontSize: 12, color: DesignSystem.muted.withValues(alpha: 0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignSystem.s36),
        SizedBox(
          width: double.infinity,
          height: DesignSystem.s56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: DesignSystem.primaryButton(brandOrange),
            child: Text(
              'BACK TO LOGIN',
              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.0),
            ),
          ),
        ),
        const SizedBox(height: DesignSystem.s16),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _emailController.clear();
            });
            _animController.reset();
            _animController.forward();
          },
          child: Text(
            'Try a different email',
            style: GoogleFonts.manrope(color: DesignSystem.muted, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
