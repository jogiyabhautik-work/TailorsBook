import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_update_info.dart';
import '../../core/utils/design_system.dart';

class UpdateRequiredScreen extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const UpdateRequiredScreen({super.key, required this.updateInfo});

  Future<void> _launchUpdateUrl(BuildContext context) async {
    final apkUrl = updateInfo.apkUrl;
    if (apkUrl != null && apkUrl.isNotEmpty) {
      final uri = Uri.parse(apkUrl);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open update link')),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update link not available')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.system_update_rounded,
                size: 80,
                color: DesignSystem.primaryContainer,
              ),
              const SizedBox(height: 32),
              Text(
                updateInfo.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: DesignSystem.charcoal,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                updateInfo.description.isNotEmpty 
                  ? updateInfo.description 
                  : 'A required update is available. Please update the app to continue using it.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: DesignSystem.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => _launchUpdateUrl(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primaryContainer,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'UPDATE NOW',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              if (!updateInfo.updateRequired) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Optional update: allow skipping if it's not a breakage.
                    // But if this screen is shown for breakage, this block might not execute.
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'LATER',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: DesignSystem.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
