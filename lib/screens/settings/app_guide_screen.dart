import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tailorsbook/core/utils/design_system.dart';

class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    final brandBlack = const Color(0xFF1C1C1C);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "TailorsBook Guide",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        backgroundColor: DesignSystem.white,
        elevation: 0,
        foregroundColor: brandBlack,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header with progress indicators (visual only)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: const BoxDecoration(
                color: DesignSystem.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                   Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: brandOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.menu_book_rounded, color: brandOrange, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Mastering Your Digital Shop",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "TailorsBook is built to handle everything from your first customer measurement to the final custom invoice.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DesignSystem.muted, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Core Features", Icons.star_rounded, DesignSystem.primary),
                  const SizedBox(height: 16),
                  _buildGuideStep(
                    "1. Client Boutique",
                    "Add customer details and search easily by name or phone. All their data and measurements stay safely linked to their profile.",
                    Icons.people_alt_rounded,
                    brandOrange
                  ),
                  _buildGuideStep(
                    "2. Custom Measurement Templates",
                    "Go beyond standard shirts and pants. Create your own custom formats (like Lehengas or Sherwanis) in the Profile tab.",
                    Icons.straighten_rounded,
                    DesignSystem.primary
                  ),
                  _buildGuideStep(
                    "3. Order Tracking Lifecycle",
                    "Convert measurements into orders. Track items through Pending, Stitching, and Ready statuses. Set exact delivery dates.",
                    Icons.local_shipping_rounded,
                    DesignSystem.success
                  ),
                  _buildGuideStep(
                    "4. Worker & Salary Management",
                    "Assign work to your team, automatically calculate piece-rate salaries, and track advances/payouts with ease.",
                    Icons.engineering_rounded,
                    DesignSystem.muted
                  ),
                  
                  const SizedBox(height: 40),
                  _buildSectionTitle("Power Tools", Icons.bolt_rounded, DesignSystem.primary),
                  const SizedBox(height: 16),
                  _buildGuideStep(
                    "Smart Dashboard",
                    "Track your active orders, today's deliveries, and total revenue directly from the Home screen.",
                    Icons.dashboard_rounded,
                    DesignSystem.success
                  ),
                  _buildGuideStep(
                    "Multi-Language Support",
                    "Switch the app seamlessly between English, Hindi, and Gujarati from your Profile settings.",
                    Icons.translate_rounded,
                    DesignSystem.primary
                  ),
                  _buildGuideStep(
                    "Customized Invoices",
                    "Generate beautiful PDF bills. Toggle shop address, GST details, or customer phone numbers directly from Invoice Settings.",
                    Icons.receipt_long_rounded,
                    DesignSystem.error
                  ),

                  const SizedBox(height: 40),
                  _buildSectionTitle("Pro Tips", Icons.tips_and_updates_rounded, brandOrange),
                  const SizedBox(height: 16),
                  _buildProTip(
                    "Cloud Sync & Security",
                    "Even if you lose your phone, your data is safe. Just log in on a new device to instantly restore your shop.",
                    Icons.cloud_done_rounded
                  ),
                  _buildProTip(
                    "Direct WhatsApp Sharing",
                    "Share invoices and measurements directly to your customers' WhatsApp with a single tap.",
                    Icons.share_rounded
                  ),

                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: brandBlack,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Need More Help?",
                          style: TextStyle(color: DesignSystem.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Our support team is available to help you digitize your shop.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: DesignSystem.white.withValues(alpha: 0.6), fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                             launchUrl(Uri.parse('mailto:support@tailorsbook.com'));
                          },
                          icon: const Icon(Icons.email_rounded, size: 18),
                          label: const Text("Email Support", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandOrange,
                            foregroundColor: DesignSystem.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildGuideStep(String title, String desc, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: DesignSystem.charcoal.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: DesignSystem.muted, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProTip(String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignSystem.outlineVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: DesignSystem.muted, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: DesignSystem.muted, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
