import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/responsive_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/backup_helper.dart';
import '../../main.dart';
import 'package:tailorsbook/core/utils/design_system.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isExporting = false;
  bool _isImporting = false;
  bool _isPreMigration = false;

  List<Map<String, dynamic>> _backupHistory = [];
  List<Map<String, dynamic>> _restoreHistory = [];
  bool _isLoadingHistory = true;

  List<Map<String, dynamic>> _deletedRecords = [];
  bool _isLoadingDeleted = false;
  String? _deletedTableFilter;

  Map<String, dynamic>? _healthStatus;
  bool _isLoadingHealth = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final results = await Future.wait([
      BackupHelper.fetchBackupHistory(),
      BackupHelper.fetchRestoreHistory(),
    ]);
    if (context.mounted) {
      setState(() {
        _backupHistory = results[0];
        _restoreHistory = results[1];
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadDeletedRecords() async {
    setState(() => _isLoadingDeleted = true);
    final records = await BackupHelper.fetchDeletedRecords(
      tableName: _deletedTableFilter,
    );
    if (context.mounted) {
      setState(() {
        _deletedRecords = records;
        _isLoadingDeleted = false;
      });
    }
  }

  Future<void> _loadHealthStatus() async {
    setState(() => _isLoadingHealth = true);
    final health = await BackupHelper.checkBackupHealth();
    if (context.mounted) {
      setState(() {
        _healthStatus = health;
        _isLoadingHealth = false;
      });
    }
  }

  Future<void> _exportBackup() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      showGlobalSnackBar('Exporting your data...', isError: false);
      final backup = await BackupHelper.exportAllData();
      final file = await BackupHelper.saveBackupToFile(backup);
      final fileSize = await file.length();

      await BackupHelper.recordBackupMetadata(
        backupType: 'manual',
        recordCount: backup.tables.values.fold(0, (sum, records) => sum + records.length),
        sizeBytes: fileSize,
      );

      await BackupHelper.shareBackup(file);
      if (context.mounted) {
        showGlobalSnackBar('Backup exported successfully!');
        _loadHistory();
      }
    } catch (e) {
      if (context.mounted) {
        showGlobalSnackBar('Export failed: $e', isError: true);
        await BackupHelper.recordBackupMetadata(
          backupType: 'manual',
          errorMessage: e.toString(),
        );
        _loadHistory();
      }
    } finally {
      if (context.mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPreMigrationBackup() async {
    if (_isPreMigration) return;
    setState(() => _isPreMigration = true);

    try {
      showGlobalSnackBar('Creating pre-migration safety backup...', isError: false);
      final backup = await BackupHelper.exportPreMigrationBackup();
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/tailorsbook_migration_backups');
      final file = await BackupHelper.saveBackupToPath(backup, dir.path);
      final fileSize = await file.length();

      await BackupHelper.createPreMigrationBackupMarker();
      await BackupHelper.recordBackupMetadata(
        backupType: 'pre_migration',
        recordCount: backup.tables.values.fold(0, (sum, records) => sum + records.length),
        sizeBytes: fileSize,
      );

      if (context.mounted) {
        showGlobalSnackBar('Pre-migration backup saved to device');
        _loadHistory();
      }
    } catch (e) {
      if (context.mounted) {
        showGlobalSnackBar('Pre-migration backup failed: $e', isError: true);
      }
    } finally {
      if (context.mounted) setState(() => _isPreMigration = false);
    }
  }

  Future<void> _importBackup() async {
    if (_isImporting) return;

    final confirmed = await showResponsiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Restore Backup?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will OVERWRITE your current data with the backup data.', style: TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.error)),
            SizedBox(height: 12),
            Text('Make sure you have a recent backup of your current data before proceeding.'),
            SizedBox(height: 8),
            Text('This action cannot be undone.', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: DesignSystem.error, foregroundColor: DesignSystem.white),
            child: const Text('RESTORE BACKUP'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;
      if (!context.mounted) return;

      setState(() => _isImporting = true);
      showGlobalSnackBar('Restoring data...', isError: false);

      final file = File(result.files.single.path!);
      final backup = await BackupHelper.loadBackupFromFile(file);
      final restored = await BackupHelper.restoreFromBackup(backup);

      final verifyResult = await BackupHelper.verifyRestore(backup);

      if (context.mounted) {
        final totalRows = restored.values.fold(0, (a, b) => a + b);
        if (verifyResult['verified'] == true) {
          showGlobalSnackBar('Restored $totalRows records across ${restored.length} tables!');
        } else {
          showGlobalSnackBar('Restored $totalRows records (some tables may have mismatches - check history)', isError: true);
        }
        _loadHistory();
      }
    } catch (e) {
      if (context.mounted) {
        showGlobalSnackBar('Restore failed: $e', isError: true);
      }
    } finally {
      if (context.mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _restoreDeletedRecord(String archiveId) async {
    final result = await BackupHelper.restoreDeletedRecord(archiveId);
    if (context.mounted) {
      if (result.startsWith('OK:')) {
        showGlobalSnackBar('Record restored successfully!');
        _loadDeletedRecords();
      } else {
        showGlobalSnackBar(result, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Backup & Restore', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: DesignSystem.white,
        foregroundColor: DesignSystem.charcoal,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: DesignSystem.muted,
          tabs: const [
            Tab(icon: Icon(Icons.backup_rounded, size: 20), text: 'Backup'),
            Tab(icon: Icon(Icons.delete_sweep_rounded, size: 20), text: 'Recovery'),
            Tab(icon: Icon(Icons.health_and_safety_rounded, size: 20), text: 'Health'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBackupTab(),
          _buildRecoveryTab(),
          _buildHealthTab(),
        ],
      ),
    );
  }

  // â”€â”€ TAB 1: Backup â”€â”€

  Widget _buildBackupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_backupHistory.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignSystem.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DesignSystem.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_done_rounded, color: DesignSystem.success, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Last Backup', style: TextStyle(color: DesignSystem.success, fontWeight: FontWeight.w900, fontSize: 12)),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(
                            DateTime.tryParse(_backupHistory.first['created_at']?.toString() ?? '') ?? DateTime.now(),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.backup_rounded,
                  label: 'EXPORT BACKUP',
                  subtitle: 'Save all data to file',
                  color: DesignSystem.primary,
                  isLoading: _isExporting,
                  onTap: _exportBackup,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.restore_rounded,
                  label: 'RESTORE',
                  subtitle: 'Import from backup file',
                  color: DesignSystem.primary,
                  isLoading: _isImporting,
                  onTap: _importBackup,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isPreMigration ? null : _exportPreMigrationBackup,
              icon: _isPreMigration
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.shield_rounded, size: 18),
              label: Text(_isPreMigration ? 'Creating...' : 'Pre-Migration Safety Backup'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: DesignSystem.muted),
                foregroundColor: DesignSystem.charcoal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 28),
          Text('BACKUP HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: DesignSystem.muted, letterSpacing: 1)),
          const SizedBox(height: 12),
          if (_isLoadingHistory)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_backupHistory.isEmpty)
            _buildEmptyState('No backups yet', 'Create your first backup above')
          else
            ..._backupHistory.map((b) => _buildHistoryTile(
              icon: Icons.backup_rounded,
              title: '${b['backup_type']?.toString().toUpperCase() ?? ''} Backup',
              subtitle: '${b['record_count'] ?? 0} records  ${_formatBytes(b['size_bytes'])}',
              date: b['created_at']?.toString(),
              status: b['status']?.toString() ?? '',
            )),

          const SizedBox(height: 28),
          Text('RESTORE HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: DesignSystem.muted, letterSpacing: 1)),
          const SizedBox(height: 12),
          if (_restoreHistory.isEmpty)
            _buildEmptyState('No restores yet', 'Restores will appear here')
          else
            ..._restoreHistory.map((r) => _buildHistoryTile(
              icon: r['status'] == 'completed' ? Icons.check_circle_rounded : Icons.error_rounded,
              iconColor: r['status'] == 'completed' ? DesignSystem.success : DesignSystem.error,
              title: 'Restore  ${r['rows_affected'] ?? 0} rows',
              subtitle: (r['tables_restored'] as List?)?.join(', ') ?? '',
              date: r['restored_at']?.toString(),
              status: r['status']?.toString() ?? '',
            )),

          const SizedBox(height: 32),
          _buildInfoBox(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // â”€â”€ TAB 2: Recovery (Deleted Records) â”€â”€

  Widget _buildRecoveryTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: DesignSystem.primaryLight,
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: DesignSystem.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Soft-deleted records are archived automatically. Browse and restore them here.',
                  style: TextStyle(color: DesignSystem.primary, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: AppDropdown<String?>(
                  value: _deletedTableFilter,
                  label: 'Filter by table',
                  hint: 'All tables',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All tables')),
                    ...['orders', 'customers', 'payments', 'shop_expenses', 'order_items', 'fabrics', 'workers']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t))),
                  ],
                  onChanged: (val) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _deletedTableFilter = val);
                    _loadDeletedRecords();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadDeletedRecords,
                style: IconButton.styleFrom(backgroundColor: DesignSystem.surface),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingDeleted
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _deletedRecords.isEmpty
                  ? _buildEmptyState('No deleted records found', 'Deleted records from orders, customers, and payments appear here')
                  : RefreshIndicator(
                      onRefresh: _loadDeletedRecords,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _deletedRecords.length,
                        itemBuilder: (ctx, i) {
                          final r = _deletedRecords[i];
                          return _buildDeletedRecordTile(r);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildDeletedRecordTile(Map<String, dynamic> record) {
    final archiveId = record['archive_id']?.toString() ?? '';
    final tableName = record['table_name']?.toString() ?? '?';
    final deletedAt = record['deleted_at']?.toString();

    IconData tableIcon;
    Color tableColor;
    switch (tableName) {
      case 'orders': tableIcon = Icons.shopping_bag_rounded; tableColor = DesignSystem.primary; break;
      case 'customers': tableIcon = Icons.people_rounded; tableColor = DesignSystem.success; break;
      case 'payments': tableIcon = Icons.payments_rounded; tableColor = DesignSystem.success; break;
      case 'shop_expenses': tableIcon = Icons.receipt_rounded; tableColor = DesignSystem.primary; break;
      default: tableIcon = Icons.delete_rounded; tableColor = DesignSystem.muted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: tableColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(tableIcon, size: 18, color: tableColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tableName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                if (deletedAt != null)
                      Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(deletedAt) ?? DateTime.now()),
                    style: TextStyle(fontSize: 10, color: DesignSystem.muted)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _confirmRestoreDeleted(archiveId),
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: const Text('RESTORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            style: TextButton.styleFrom(foregroundColor: DesignSystem.success, padding: const EdgeInsets.symmetric(horizontal: 10)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestoreDeleted(String archiveId) async {
    final confirmed = await showResponsiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Restore Deleted Record?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('This will restore the deleted record back to its original table. The record will no longer be marked as deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: DesignSystem.success, foregroundColor: DesignSystem.white),
            child: const Text('RESTORE'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _restoreDeletedRecord(archiveId);
    }
  }

  // â”€â”€ TAB 3: Health â”€â”€

  Widget _buildHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadHealthStatus,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Check Backup Health'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_isLoadingHealth)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_healthStatus == null)
            _buildEmptyState('Tap to check health', 'Monitors backup frequency and integrity')
          else ...[
            _buildHealthCard(_healthStatus!),
            const SizedBox(height: 24),
            _buildRecoverySteps(),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthCard(Map<String, dynamic> health) {
    final status = health['health_status']?.toString() ?? 'unknown';
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'healthy':
        statusColor = DesignSystem.success;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Backup System Healthy';
        break;
      case 'warning':
        statusColor = DesignSystem.primary;
        statusIcon = Icons.warning_rounded;
        statusText = 'Backup Due Soon';
        break;
      case 'critical':
        statusColor = DesignSystem.error;
        statusIcon = Icons.error_rounded;
        statusText = 'No Recent Backup';
        break;
      case 'never_backed_up':
        statusColor = DesignSystem.error;
        statusIcon = Icons.cloud_off_rounded;
        statusText = 'Never Backed Up';
        break;
      default:
        statusColor = DesignSystem.muted;
        statusIcon = Icons.help_rounded;
        statusText = 'Status Unknown';
    }

    final daysSince = health['days_since_last_backup'];
    final totalBackups = health['total_backups'];
    final failed = health['failed_backups'];
    final archived = health['archived_deleted_records'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusText, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: DesignSystem.charcoal)),
                    const SizedBox(height: 2),
                    if (daysSince != null)
                      Text('$daysSince days since last backup', style: TextStyle(fontSize: 12, color: DesignSystem.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _healthStat('Total Backups', totalBackups?.toString() ?? '0'),
              const SizedBox(width: 16),
              _healthStat('Failed', failed?.toString() ?? '0'),
              const SizedBox(width: 16),
              _healthStat('Archived', archived?.toString() ?? '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _healthStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: DesignSystem.charcoal)),
          Text(label, style: TextStyle(fontSize: 10, color: DesignSystem.muted)),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignSystem.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DesignSystem.outlineVariant),
        ),
        child: Column(
          children: [
            if (isLoading)
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 28),
              ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 10, color: DesignSystem.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoverySteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('RECOVERY STEPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: DesignSystem.muted, letterSpacing: 1)),
        const SizedBox(height: 12),
        _stepTile('1', 'Check Backup Health', 'Run a health check to see backup status'),
        _stepTile('2', 'Export Backup', 'Save your data to a JSON file'),
        _stepTile('3', 'Restore if Needed', 'Import a backup file to restore data'),
      ],
    );
  }

  Widget _stepTile(String number, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: DesignSystem.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(number, style: TextStyle(fontWeight: FontWeight.w900, color: DesignSystem.primary, fontSize: 14))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DesignSystem.charcoal)),
                Text(desc, style: TextStyle(fontSize: 11, color: DesignSystem.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    String? date,
    String status = '',
  }) {
    final isError = status == 'failed';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isError ? DesignSystem.error.withValues(alpha: 0.2) : const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? DesignSystem.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? DesignSystem.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
                    if (isError)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: DesignSystem.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('FAILED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: DesignSystem.error)),
                      ),
                  ],
                ),
                Text(subtitle, style: TextStyle(fontSize: 11, color: DesignSystem.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (date != null)
                  Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(date) ?? DateTime.now()),
                    style: TextStyle(fontSize: 10, color: DesignSystem.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 36, color: DesignSystem.outlineVariant),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: DesignSystem.muted, fontWeight: FontWeight.w600)),
          Text(subtitle, style: TextStyle(color: DesignSystem.muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignSystem.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignSystem.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: DesignSystem.primary, size: 18),
              const SizedBox(width: 8),
              Text('About Backups', style: TextStyle(color: DesignSystem.primary, fontWeight: FontWeight.w900, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ' Backups contain all your data: customers, orders, payments, workers, fabrics, measurements\n'
            ' Backup files are in JSON format and can be stored anywhere\n'
            ' Restore overwrites existing data with backup data\n'
            ' Always create a fresh backup before restoring\n'
            ' Use Pre-Migration Backup before running database migrations\n'
            ' Regular backups protect against accidental data loss',
            style: TextStyle(color: DesignSystem.primary, fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }

  String _formatBytes(dynamic bytes) {
    if (bytes == null) return '0 B';
    final size = (bytes as num).toInt();
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
