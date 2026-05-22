import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';


class BackupData {
  final String version;
  final DateTime exportedAt;
  final String userId;
  final Map<String, List<Map<String, dynamic>>> tables;

  BackupData({
    required this.version,
    required this.exportedAt,
    required this.userId,
    required this.tables,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'exported_at': exportedAt.toIso8601String(),
    'user_id': userId,
    'tables': tables,
  };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    final rawTables = json['tables'] as Map<String, dynamic>? ?? {};
    final tables = rawTables.map((key, value) {
      return MapEntry(key, List<Map<String, dynamic>>.from(value as List));
    });
    return BackupData(
      version: json['version'] as String? ?? '1.0',
      exportedAt: DateTime.tryParse(json['exported_at']?.toString() ?? '') ?? DateTime.now(),
      userId: json['user_id']?.toString() ?? '',
      tables: tables,
    );
  }
}

class BackupHelper {
  static SupabaseClient get _supabase => Supabase.instance.client;

  static void _log(String msg) {
    debugPrint('[BackupHelper] $msg');
  }

  // ── Export ALL user data ──

  static Future<BackupData> exportAllData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    _log('Starting full export for user $userId');

    final tables = <String, List<Map<String, dynamic>>>{};

    // Define export order: parent tables first
    final tableConfig = [
      {'name': 'customers', 'filter': 'tailor_id', 'order': 'name'},
      {'name': 'workers', 'filter': 'tailor_id', 'order': 'name'},
      {'name': 'fabrics', 'filter': 'shop_id'},
      {'name': 'measurement_templates', 'filter': 'tailor_id', 'order': 'name'},
      {'name': 'measurement_records', 'filter': 'tailor_id', 'order': 'created_at'},
      {'name': 'measurement_versions', 'filter': 'tailor_id', 'order': 'versioned_at'},
      {'name': 'orders', 'filter': 'user_id', 'order': 'created_at'},
      {'name': 'order_items', 'via': 'orders'},
      {'name': 'payments', 'filter': 'user_id', 'order': 'payment_date'},
      {'name': 'worker_assignments'},
      {'name': 'worker_work_log'},
      {'name': 'worker_payments'},
      {'name': 'worker_earnings', 'filter': 'worker_id'},
      {'name': 'shop_expenses', 'filter': 'tailor_id', 'order': 'expense_date'},
      {'name': 'order_item_fabrics'},
    ];

    for (final config in tableConfig) {
      try {
        final tableName = config['name'] as String;

        if (tableName == 'order_items') {
          final ordersResponse = await _supabase
              .from('orders')
              .select('id')
              .eq('user_id', userId);
          final orderIds = (ordersResponse as List)
              .map((o) => o['id'] as String)
              .toList();

          if (orderIds.isNotEmpty) {
            final itemsResponse = await _supabase
                .from('order_items')
                .select()
                .inFilter('order_id', orderIds);
            final itemIds = (itemsResponse as List)
                .map((i) => i['id'] as String)
                .toList();

            tables[tableName] = List<Map<String, dynamic>>.from(itemsResponse as List);

            if (itemIds.isNotEmpty) {
              final fabricsResponse = await _supabase
                  .from('order_item_fabrics')
                  .select()
                  .inFilter('order_item_id', itemIds);
              tables['order_item_fabrics'] = List<Map<String, dynamic>>.from(fabricsResponse as List);
            }
          }
        } else if (tableName == 'order_item_fabrics') {
          // Already handled in order_items block
          continue;
        } else {
          final filterField = config['filter']?.toString();
          final orderField = config['order']?.toString();

          dynamic query = _supabase.from(tableName).select();
          if (filterField != null) {
            query = query.eq(filterField, userId);
          }
          if (orderField != null) {
            query = query.order(orderField, ascending: false);
          }

          final response = await query;
          tables[tableName] = List<Map<String, dynamic>>.from(response as List);
        }

        _log('Exported ${tables[tableName]?.length ?? 0} records from $tableName');
      } catch (e) {
        _log('Skipping table ${config['name']}: $e');
        tables[config['name'] as String] = [];
      }
    }

    return BackupData(
      version: '1.0',
      exportedAt: DateTime.now(),
      userId: userId,
      tables: tables,
    );
  }

  // ── Pre-migration backup (lightweight, just metadata + critical tables) ──

  static Future<BackupData> exportPreMigrationBackup() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    _log('Starting pre-migration backup for user $userId');

    final tables = <String, List<Map<String, dynamic>>>{};
    final criticalTables = [
      {'name': 'customers', 'filter': 'tailor_id'},
      {'name': 'orders', 'filter': 'user_id'},
      {'name': 'payments', 'filter': 'user_id'},
      {'name': 'order_items'},
      {'name': 'shop_expenses', 'filter': 'tailor_id'},
    ];

    for (final config in criticalTables) {
      final tableName = config['name'] as String;
      try {
        final filterField = config['filter']?.toString();

        dynamic query = _supabase.from(tableName).select();
        if (filterField != null) {
          query = query.eq(filterField, userId);
        }

        final response = await query;
        tables[tableName] = List<Map<String, dynamic>>.from(response as List);
        _log('Pre-migration: exported ${tables[tableName]!.length} records from $tableName');
      } catch (e) {
        _log('Pre-migration: skipping $tableName: $e');
        tables[tableName] = [];
      }
    }

    return BackupData(
      version: '1.0',
      exportedAt: DateTime.now(),
      userId: userId,
      tables: tables,
    );
  }

  // ── Save backup to file ──

  static Future<File> saveBackupToFile(BackupData backup) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(backup.exportedAt);
    final file = File('${dir.path}/tailorsbook_backup_$timestamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup.toJson()),
    );
    return file;
  }

  // ── Save backup to a specific path (for pre-migration safety) ──

  static Future<File> saveBackupToPath(BackupData backup, String directory) async {
    final dir = Directory(directory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(backup.exportedAt);
    final file = File('${dir.path}/pre_migration_backup_$timestamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup.toJson()),
    );
    return file;
  }

  // ── Share backup file ──

  static Future<void> shareBackup(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'TailorsBook Backup - ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
    );
  }

  // ── Load backup from file ──

  static Future<BackupData> loadBackupFromFile(File file) async {
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return BackupData.fromJson(json);
  }

  // ── Validate backup integrity ──

  static String? validateBackup(BackupData backup) {
    if (backup.version != '1.0') {
      return 'Unsupported backup version: ${backup.version}';
    }
    if (backup.userId.isEmpty) {
      return 'Backup has no user ID';
    }
    if (backup.tables.isEmpty) {
      return 'Backup contains no data';
    }
    final requiredTables = ['customers', 'orders', 'payments'];
    for (final table in requiredTables) {
      if (!backup.tables.containsKey(table)) {
        return 'Missing critical table: $table';
      }
    }
    return null;
  }

  // ── Restore data from backup (overwrite current user data) ──

  static Future<Map<String, int>> restoreFromBackup(BackupData backup) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    if (backup.userId != userId) {
      throw Exception('Backup belongs to a different user account');
    }

    final validationError = validateBackup(backup);
    if (validationError != null) {
      throw Exception('Backup validation failed: $validationError');
    }

    _log('Starting restore for user $userId');
    final restored = <String, int>{};

    final restoreId = const Uuid().v4();
    await _supabase.from('restore_log').insert({
      'id': restoreId,
      'user_id': userId,
      'tables_restored': backup.tables.keys.toList(),
      'status': 'running',
    });

    try {
      final restoreOrder = [
        'order_item_fabrics',
        'worker_earnings',
        'worker_payments',
        'worker_work_log',
        'worker_assignments',
        'order_items',
        'payments',
        'orders',
        'measurement_versions',
        'measurement_records',
        'shop_expenses',
        'customers',
        'workers',
        'fabrics',
        'measurement_templates',
      ];

      for (final tableName in restoreOrder) {
        final records = backup.tables[tableName];
        if (records == null || records.isEmpty) continue;

        int inserted = 0;
        for (final record in records) {
          try {
            await _supabase.from(tableName).upsert(record);
            inserted++;
          } catch (e) {
            _log('Skipping record in $tableName: $e');
          }
        }
        restored[tableName] = inserted;
        _log('Restored $inserted records to $tableName');
      }

      await _supabase
          .from('restore_log')
          .update({
            'status': 'completed',
            'rows_affected': restored.values.fold(0, (a, b) => a + b),
          })
          .eq('id', restoreId);

      _log('Restore completed successfully');
      return restored;
    } catch (e) {
      await _supabase
          .from('restore_log')
          .update({
            'status': 'failed',
            'error_message': e.toString(),
          })
          .eq('id', restoreId);
      rethrow;
    }
  }

  // ── Verify restore by comparing record counts ──

  static Future<Map<String, dynamic>> verifyRestore(BackupData backup) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final results = <String, dynamic>{};
    results['verified'] = true;
    results['checks'] = [];

    for (final entry in backup.tables.entries) {
      final tableName = entry.key;
      final expectedCount = entry.value.length;
      if (expectedCount == 0) continue;

      try {
        final response = await _supabase
            .from(tableName)
            .select('id')
            .filter('deleted_at', 'is', 'null');

        final actualCount = (response as List).length;
        final match = actualCount >= expectedCount;

        results['checks'].add({
          'table': tableName,
          'expected': expectedCount,
          'actual': actualCount,
          'match': match,
        });

        if (!match) {
          results['verified'] = false;
        }
      } catch (e) {
        _log('Verify: could not check $tableName: $e');
        results['checks'].add({
          'table': tableName,
          'expected': expectedCount,
          'actual': -1,
          'match': false,
          'error': e.toString(),
        });
        results['verified'] = false;
      }
    }

    return results;
  }

  // ── Record backup metadata ──

  static Future<void> recordBackupMetadata({
    required String backupType,
    int recordCount = 0,
    int sizeBytes = 0,
    String? errorMessage,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('backup_metadata').insert({
        'id': const Uuid().v4(),
        'user_id': userId,
        'backup_type': backupType,
        'record_count': recordCount,
        'size_bytes': sizeBytes,
        'status': errorMessage != null ? 'failed' : 'completed',
        'error_message': ?errorMessage,
      });
    } catch (e) {
      _log('Failed to record backup metadata: $e');
    }
  }

  // ── Fetch backup history ──

  static Future<List<Map<String, dynamic>>> fetchBackupHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('backup_metadata')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      _log('Failed to fetch backup history: $e');
      return [];
    }
  }

  // ── Fetch restore history ──

  static Future<List<Map<String, dynamic>>> fetchRestoreHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('restore_log')
          .select()
          .eq('user_id', userId)
          .order('restored_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      _log('Failed to fetch restore history: $e');
      return [];
    }
  }

  // ── Fetch deleted records archive ──

  static Future<List<Map<String, dynamic>>> fetchDeletedRecords({
    String? tableName,
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .rpc('get_deleted_records', params: {
            'p_user_id': userId,
            'p_table_name': tableName,
            'p_limit': limit,
            'p_offset': offset,
          });
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      _log('Failed to fetch deleted records: $e');
      return [];
    }
  }

  // ── Restore a single deleted record from archive ──

  static Future<String> restoreDeletedRecord(String archiveId) async {
    try {
      final response = await _supabase
          .rpc('restore_deleted_record', params: {'p_archive_id': archiveId});
      return response as String;
    } catch (e) {
      _log('Failed to restore deleted record: $e');
      return 'ERROR: $e';
    }
  }

  // ── Check backup health ──

  static Future<Map<String, dynamic>> checkBackupHealth() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {'health_status': 'unauthenticated'};

    try {
      final response = await _supabase
          .rpc('check_backup_health', params: {'p_user_id': userId});
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      _log('Failed to check backup health: $e');
      return {'health_status': 'error', 'error': e.toString()};
    }
  }

  // ── Create pre-migration backup marker in DB ──

  static Future<String?> createPreMigrationBackupMarker() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .rpc('create_pre_migration_backup', params: {'p_user_id': userId});
      return response as String;
    } catch (e) {
      _log('Failed to create pre-migration marker: $e');
      return null;
    }
  }
}
