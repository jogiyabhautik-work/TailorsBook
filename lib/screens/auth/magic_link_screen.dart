import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../core/utils/design_system.dart';
import '../home/home_page.dart';
import 'package:google_fonts/google_fonts.dart';

class MagicLinkScreen extends StatefulWidget {
  const MagicLinkScreen({super.key});

  @override
  State<MagicLinkScreen> createState() => _MagicLinkScreenState();
}

class _MagicLinkScreenState extends State<MagicLinkScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _otpSent = false;
  int _resendCountdown = 0;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email address');
      return;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      if (mounted) {
        setState(() {
          _otpSent = true;
          _isLoading = false;
          _resendCountdown = 60;
        });
        _animController.reset();
        _animController.forward();
        _startResendCountdown();
        // Auto-focus first OTP box
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _otpFocusNodes[0].requestFocus();
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Something went wrong. Please try again.');
      }
    }
  }

  void _startResendCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown--);
      return _resendCountdown > 0;
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      _showError('Please enter the full 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: otp,
        type: OtpType.email,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (response.user != null) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MyHomePage(title: 'TailorsBook'),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 600),
            ),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.message);
        // Clear OTP fields on error
        for (final c in _otpControllers) {
          c.clear();
        }
        _otpFocusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Invalid code. Please check and try again.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignSystem.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                          Container(
                            padding: const EdgeInsets.all(DesignSystem.s16),
                            decoration: BoxDecoration(
                              color: brandOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
                              border: Border.all(color: brandOrange.withValues(alpha: 0.25)),
                            ),
                            child: Icon(Icons.auto_awesome_rounded, color: brandOrange, size: 28),
                          ),
                          const SizedBox(height: DesignSystem.s20),
                          Text(
                            _otpSent ? 'Enter the\nOTP Code' : 'Magic\nLink Login',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: DesignSystem.s12),
                          Text(
                            _otpSent
                                ? 'We sent a 6-digit code to\n${_emailController.text.trim()}'
                                : 'Login instantly — no password needed.\nWe\'ll send you a one-time code.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: DesignSystem.s24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body Form ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(DesignSystem.s28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _otpSent
                      ? _buildOtpStep(brandOrange)
                      : _buildEmailStep(brandOrange),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailStep(Color brandOrange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: DesignSystem.s8),
        Text(
          'Email Address',
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: DesignSystem.charcoal),
        ),
        const SizedBox(height: DesignSystem.s8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendMagicLink(),
          decoration: DesignSystem.inputField(
            hint: 'your@email.com',
            prefixIcon: Icons.alternate_email_rounded,
          ),
        ),
        const SizedBox(height: DesignSystem.s12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: DesignSystem.s16, vertical: DesignSystem.s12),
          decoration: BoxDecoration(
            color: brandOrange.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
            border: Border.all(color: brandOrange.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: brandOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A 6-digit OTP will be sent to your email. Use it to login instantly.',
                  style: GoogleFonts.manrope(fontSize: 12, color: brandOrange.withValues(alpha: 0.8), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignSystem.s32),
        SizedBox(
          width: double.infinity,
          height: DesignSystem.s56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendMagicLink,
            style: DesignSystem.primaryButton(brandOrange).copyWith(
              shadowColor: WidgetStatePropertyAll(brandOrange.withValues(alpha: 0.3)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'SEND OTP CODE',
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
              style: GoogleFonts.manrope(color: DesignSystem.muted, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(Color brandOrange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: DesignSystem.s8),
        Text(
          'Enter 6-Digit Code',
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: DesignSystem.charcoal),
        ),
        const SizedBox(height: DesignSystem.s16),
        // OTP 6-box input
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => _buildOtpBox(index, brandOrange)),
        ),
        const SizedBox(height: DesignSystem.s20),
        // Resend row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive it? ",
              style: GoogleFonts.manrope(fontSize: 13, color: DesignSystem.muted),
            ),
            _resendCountdown > 0
                ? Text(
                    'Resend in ${_resendCountdown}s',
                    style: GoogleFonts.manrope(fontSize: 13, color: DesignSystem.muted, fontWeight: FontWeight.w600),
                  )
                : GestureDetector(
                    onTap: _isLoading ? null : _sendMagicLink,
                    child: Text(
                      'Resend Code',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: brandOrange,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
          ],
        ),
        const SizedBox(height: DesignSystem.s32),
        SizedBox(
          width: double.infinity,
          height: DesignSystem.s56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: DesignSystem.primaryButton(brandOrange).copyWith(
              shadowColor: WidgetStatePropertyAll(brandOrange.withValues(alpha: 0.3)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'VERIFY & LOGIN',
                        style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: DesignSystem.s16),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _otpSent = false;
                for (final c in _otpControllers) {
                  c.clear();
                }
              });
              _animController.reset();
              _animController.forward();
            },
            child: Text(
              'Change email address',
              style: GoogleFonts.manrope(color: DesignSystem.muted, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index, Color brandOrange) {
    return SizedBox(
      width: 46,
      height: 58,
      child: ListenableBuilder(
        listenable: _otpFocusNodes[index],
        builder: (context, _) {
          final hasFocus = _otpFocusNodes[index].hasFocus;
          return TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: DesignSystem.charcoal,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: hasFocus ? brandOrange.withValues(alpha: 0.04) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                borderSide: BorderSide(color: hasFocus ? brandOrange : DesignSystem.outlineVariant, width: hasFocus ? 2 : 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                borderSide: BorderSide(color: DesignSystem.outlineVariant, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                borderSide: BorderSide(color: brandOrange, width: 2),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _otpFocusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
              }
              // Auto-verify when all 6 digits entered
              if (index == 5 && value.isNotEmpty) {
                final otp = _otpControllers.map((c) => c.text).join();
                if (otp.length == 6) {
                  Future.delayed(const Duration(milliseconds: 100), _verifyOtp);
                }
              }
            },
          );
        },
      ),
    );
  }
}
