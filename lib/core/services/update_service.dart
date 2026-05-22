import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/app_update_info.dart';

/// Service responsible for fetching remote update config.
/// Default implementation uses Supabase REST endpoint or a provided URL.
class UpdateService {
  final String? remoteConfigUrl; // optional override

  UpdateService({this.remoteConfigUrl});

  /// Fetch update info from remote. Expects JSON body matching AppUpdateInfo keys.
  Future<AppUpdateInfo> fetchUpdateInfo() async {
    // Prefer Supabase client when available, fallback to HTTP URL if provided
    try {
      // Try Supabase table read using PostgREST via anon key endpoint if remoteConfigUrl isn't provided
      final client = Supabase.instance.client;
      try {
        // Try to read the latest config row. Order by updated_at to prefer newest.
        final res = await client.from('app_update').select().order('updated_at', ascending: false).limit(1).maybeSingle();
        if (res != null) {
          return AppUpdateInfo.fromMap(Map<String, dynamic>.from(res));
        }
      } catch (_) {
        // ignore and fall back to HTTP if provided
      }

      if (remoteConfigUrl != null && remoteConfigUrl!.isNotEmpty) {
        final resp = await http.get(Uri.parse(remoteConfigUrl!));
        if (resp.statusCode == 200) {
          final body = json.decode(resp.body);
          final map = (body is List && body.isNotEmpty) ? body[0] as Map<String, dynamic> : body as Map<String, dynamic>;
          return AppUpdateInfo.fromMap(Map<String, dynamic>.from(map));
        }
        throw Exception('Failed to fetch update info via HTTP: ${resp.statusCode}');
      }

      // No config found via Supabase and no HTTP fallback configured
      throw Exception('No update config found');
    } catch (e) {
      if (kDebugMode) debugPrint('UpdateService.fetchUpdateInfo error: $e');
      rethrow;
    }
  }
}
