class AppUpdateInfo {
  final String latestVersion;
  final String minimumSupportedVersion;
  final bool updateRequired; // immediate
  final bool flexibleAllowed;
  final String title;
  final String description;
  final String? apkUrl;
  final int? sizeBytes;
  final DateTime? fetchedAt;

  AppUpdateInfo({
    required this.latestVersion,
    required this.minimumSupportedVersion,
    required this.updateRequired,
    required this.flexibleAllowed,
    required this.title,
    required this.description,
    this.apkUrl,
    this.sizeBytes,
    this.fetchedAt,
  });

  factory AppUpdateInfo.fromMap(Map<String, dynamic> m) {
    return AppUpdateInfo(
      latestVersion: (m['latest_version'] as String?) ?? '0.0.0',
      minimumSupportedVersion: (m['minimum_supported_version'] as String?) ?? '0.0.0',
      updateRequired: (m['update_required'] as bool?) ?? false,
      flexibleAllowed: (m['flexible_allowed'] as bool?) ?? true,
      title: (m['update_title'] as String?) ?? 'Update Available',
      description: (m['update_description'] as String?) ?? '',
      apkUrl: m['apk_url'] as String?,
      sizeBytes: m['apk_size_bytes'] is int ? m['apk_size_bytes'] as int : null,
      fetchedAt: DateTime.now(),
    );
  }
}
