import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../widgets/common/update_tile.dart';
import '../auth/login_screen.dart';
import '../measurements/template_management_screen.dart';
import '../settings/app_guide_screen.dart';
import '../profile_tab/edit_profile_screen.dart';
import '../profile_tab/shop_configuration_screen.dart';
import '../profile_tab/invoice_customization_screen.dart';
import '../profile_tab/backup_restore_screen.dart';
import '../../core/utils/design_system.dart';
import '../settings/fabric_inventory_screen.dart';
import '../../core/services/update_service.dart';
import '../../models/app_update_info.dart';
import '../../core/utils/version_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart' hide AppUpdateInfo;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  User? _user;
  Map<String, dynamic>? _metadata;
  UpdateService? _updateService;
  String _currentVersion = '0.0.0';
  String _buildNumber = '';
  DateTime? _lastUpdateCheck;
  bool _checking = false;
  String _updateStatus = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateService = UpdateService();
    _loadPackageInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      _user = supabase.auth.currentUser;
      _metadata = _user?.userMetadata;
    });
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!context.mounted) return;
      setState(() {
        _currentVersion = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (e) {
      // ignore - package info is optional
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _checkForUpdates() async {
    if (_updateService == null) return;
    setState(() {
      _checking = true;
      _updateStatus = '';
    });
    try {
      final info = await _updateService!.fetchUpdateInfo();
      if (!context.mounted) return;
      _lastUpdateCheck = info.fetchedAt ?? DateTime.now();

      final cmp = VersionUtils.compare(_currentVersion, info.latestVersion);
      if (cmp >= 0) {
        setState(() {
          _updateStatus = 'You are using the latest version';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are using the latest version')));
      } else {
        // Update available - show dialog with details
        setState(() {
          _updateStatus = 'Update available: ${info.latestVersion}';
        });
        showResponsiveDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(info.title, style: const TextStyle(fontWeight: FontWeight.w900)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current: $_currentVersion'),
                const SizedBox(height: 6),
                Text('Latest: ${info.latestVersion}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(info.description),
                if (info.sizeBytes != null) ...[
                  const SizedBox(height: 8),
                  Text('Size: ${(info.sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB'),
                ]
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // For Android, delegate to in_app_update or open apk_url
                  _startUpdateFlow(info);
                },
                child: const Text('UPDATE NOW'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _updateStatus = 'Update check failed';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to check updates: $e')));
    } finally {
      if (context.mounted) setState(() => _checking = false);
    }
  }

  void _startUpdateFlow(AppUpdateInfo info) {
    final apk = info.apkUrl;
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        _performAndroidUpdateFlow(info);
        return;
      }
    } catch (_) {
    }

    if (apk != null && apk.isNotEmpty) {
      final uri = Uri.parse(apk);
      launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open update link')));
        return true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update flow not configured for this platform')));
    }
  }

  Future<void> _performAndroidUpdateFlow(AppUpdateInfo info) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        final immediateAllowed = updateInfo.immediateUpdateAllowed;
        final flexibleAllowed = updateInfo.flexibleUpdateAllowed;

        if (info.updateRequired && immediateAllowed) {
          await InAppUpdate.performImmediateUpdate();
          return;
        }

        if (flexibleAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          if (!context.mounted) return;
          showResponsiveDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Update Downloading'),
              content: const Text('The update is downloading in background. Install when ready.'),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await InAppUpdate.completeFlexibleUpdate();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to install update: $e')));
                    }
                  },
                  child: const Text('INSTALL NOW'),
                ),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('LATER')),
              ],
            ),
          );
          return;
        }

        if (immediateAllowed) {
          await InAppUpdate.performImmediateUpdate();
          return;
        }
      }

      final apk = info.apkUrl;
      if (apk != null && apk.isNotEmpty) {
        final uri = Uri.parse(apk);
        launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open update link')));
          return true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No Play Store update available and no apk link provided')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update check failed: $e')));
    }
  }

  Future<void> _handleLogout() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final confirmed = await showResponsiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.logoutTitle ?? 'Logout'),
        content: Text(l10n?.logoutMsg ?? 'Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n?.cancelBtn ?? 'CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n?.logoutBtn ?? 'LOGOUT', style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      // Clear all provider states to prevent data leakage
      WorkerProviderWrapper.of(context, listen: false).clearState();
      OrderProviderWrapper.of(context, listen: false).clearState();
      CustomerProviderWrapper.of(context, listen: false).clearState();
      TemplateProviderWrapper.of(context, listen: false).clearState();
      FabricProviderWrapper.of(context, listen: false).clearState();
      DashboardProviderWrapper.of(context, listen: false).clearState();
      
      await supabase.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    final brandBlack = const Color(0xFF1C1C1C);
    final orderProvider = OrderProviderWrapper.of(context);

    final String fullName = _metadata?['full_name'] ?? 'Master Tailor';
    final String shopName = _metadata?['shop_name'] ?? 'TailorsBook Shop';
    final String address = _metadata?['address'] ?? 'No Address';
    final String city = _metadata?['city'] ?? '';
    final String location = "$address${city.isNotEmpty ? ', $city' : ''}";

    final int activeOrdersCount = orderProvider.activeOrdersCount;
    final double totalEarnings = orderProvider.totalEarnings;
    final String formattedEarnings = "₹${totalEarnings > 1000 ? '${(totalEarnings / 1000).toStringAsFixed(1)}k' : totalEarnings.toStringAsFixed(0)}";    return Scaffold(
      backgroundColor: DesignSystem.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Premium Profile Identity Section
              Container(
                padding: const EdgeInsets.fromLTRB(DesignSystem.s24, DesignSystem.s24, DesignSystem.s24, DesignSystem.s32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(DesignSystem.radiusXxl),
                  bottomRight: Radius.circular(DesignSystem.radiusXxl),
                ),
                boxShadow: DesignSystem.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      Text('MASTER PROFILE', style: GoogleFonts.manrope(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5, color: DesignSystem.muted)),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                        onPressed: _handleLogout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(initialData: _metadata ?? {})));
                      if (!context.mounted) return;
                      _loadUserData();
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: brandOrange.withValues(alpha: 0.12), width: 3)),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: brandOrange.withValues(alpha: 0.08),
                            backgroundImage: (_metadata?['shop_logo_url'] as String? ?? '').isNotEmpty
                                ? NetworkImage(_metadata!['shop_logo_url'] as String) as ImageProvider
                                : null,
                            child: (_metadata?['shop_logo_url'] as String? ?? '').isNotEmpty
                                ? null
                                : Text(fullName[0].toUpperCase(), style: TextStyle(color: brandOrange, fontSize: 36, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: brandOrange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: brandBlack, letterSpacing: -1.0),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: brandOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      shopName.toUpperCase(),
                      style: TextStyle(fontSize: 10, color: brandOrange, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded, color: DesignSystem.muted, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          location,
                          style: GoogleFonts.manrope(color: DesignSystem.muted, fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Performance Bento Card
                  _buildSectionTitle('Business Snapshot'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildBentoStat('Active Orders', activeOrdersCount.toString(), Icons.shopping_bag_rounded, DesignSystem.primaryContainer)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBentoStat('Total Revenue', formattedEarnings, Icons.account_balance_wallet_rounded, DesignSystem.tertiaryContainer)),
                    ],
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Shop Management'),
                  const SizedBox(height: 16),
                  
                  // Shop Settings Bento Box
                  Container(
                    decoration: DesignSystem.card.copyWith(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          Icons.settings_suggest_rounded, 
                          'Shop Configuration', 
                          'Category, GST & Operating Hours',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopConfigurationScreen()))
                        ),
                        const Divider(height: 1, indent: 64),
                        _buildSettingsTile(
                          Icons.picture_as_pdf_rounded, 
                          'Personalize Invoice', 
                          'Choose what to show on your bill',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceCustomizationScreen()))
                        ),
                        const Divider(height: 1, indent: 64),
                        _buildSettingsTile(
                          Icons.dashboard_customize_rounded, 
                          'Measurement Templates', 
                          'Setup Ladies & Gents formats',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplateManagementScreen()))
                        ),
                        const Divider(height: 1, indent: 64),
                        _buildSettingsTile(
                          Icons.checkroom_rounded, 
                          'Fabric Inventory', 
                          'Manage your shop fabrics',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FabricInventoryScreen()))
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Data & Security'),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: DesignSystem.card.copyWith(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          Icons.backup_rounded,
                          'Backup & Restore',
                          'Export all data or restore from backup',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupRestoreScreen()))
                        ),
                        const Divider(height: 1, indent: 64),
                        _buildSettingsTile(
                          Icons.security_rounded, 
                          'Privacy & Security', 
                          'Your data is cloud-encrypted',
                          onTap: () => _showSecurityInfo(context)
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Personal & Help'),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: DesignSystem.card.copyWith(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                    ),
                    child: Column(
                      children: [
                        // Language support is postponed for next update.
                        // Do not enable until translations are completed and tested.
                        _buildSettingsTile(
                          Icons.translate_rounded,
                          'Language',
                          'Coming soon in next update',
                          onTap: () => _showLanguageComingSoon(context),
                        ),
                        const Divider(height: 1, indent: 64),
                        // App Update tile (minimal, professional)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: DesignSystem.s8, vertical: DesignSystem.s8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UpdateTile(
                                title: 'App Updates',
                                subtitle: 'Check and install the latest version',
                                version: _currentVersion,
                                loading: _checking,
                                status: _updateStatus,
                                onCheck: _checkForUpdates,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Build: ${_buildNumber.isNotEmpty ? _buildNumber : '-'}', style: GoogleFonts.manrope(fontSize: 12, color: DesignSystem.muted)),
                                  Text('Last check: ${_lastUpdateCheck != null ? _formatDateTime(_lastUpdateCheck!) : '-'}', style: GoogleFonts.manrope(fontSize: 12, color: DesignSystem.muted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, indent: 64),
                        _buildSettingsTile(
                          Icons.help_center_rounded,
                          'Help Guide',
                          'Learn how to use TailorsBook',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppGuideScreen())),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenBottomPadding(context)),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: DesignSystem.cardTitle.copyWith(fontSize: 15, letterSpacing: 0.3));
  }

  Widget _buildBentoStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.s20),
      decoration: DesignSystem.card.copyWith(
        border: Border.all(color: DesignSystem.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1.0)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: GoogleFonts.manrope(color: DesignSystem.muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: DesignSystem.s20, vertical: DesignSystem.s10),
      leading: Container(
        padding: const EdgeInsets.all(DesignSystem.s12),
        decoration: BoxDecoration(
          color: DesignSystem.surface,
          borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
          border: Border.all(color: DesignSystem.border),
        ),
        child: Icon(icon, color: DesignSystem.charcoal, size: 20),
      ),
      title: Text(title, style: DesignSystem.cardTitle.copyWith(letterSpacing: -0.2)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: DesignSystem.s2),
        child: Text(subtitle, style: TextStyle(color: DesignSystem.muted, fontSize: 12, fontWeight: FontWeight.w500)),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(DesignSystem.s8),
        decoration: BoxDecoration(color: DesignSystem.creamBg, shape: BoxShape.circle),
        child: Icon(Icons.arrow_forward_ios_rounded, size: 10, color: DesignSystem.muted),
      ),
    );
  }

  void _showSecurityInfo(BuildContext context) {
    showResponsiveDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Vault Security', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Your Shop Data is securely stored in Supabase with End-to-End Encryption. Only you can access your customer and measurement details.', style: TextStyle(height: 1.5, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('UNDERSTOOD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0))
          )
        ],
      ),
    );
  }

  void _showLanguageComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Language support is coming in the next update.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
