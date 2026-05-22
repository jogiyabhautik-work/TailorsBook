import 'package:flutter/material.dart';
import '../../core/utils/design_system.dart';

class UpdateTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String version;
  final VoidCallback onCheck;
  final bool loading;
  final String? status;
  final Widget? trailing;

  const UpdateTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.version,
    required this.onCheck,
    this.loading = false,
    this.status,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: DesignSystem.card.copyWith(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.s16, vertical: DesignSystem.s12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DesignSystem.cardTitle.copyWith(fontSize: 15)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: DesignSystem.muted, fontSize: 12)),
                const SizedBox(height: 8),
                Text('Current Version: $version', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w700)),
                if (status != null && status!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(status!, style: TextStyle(color: brandOrange, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: loading ? null : onCheck,
            style: ElevatedButton.styleFrom(backgroundColor: brandOrange),
            child: loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Check for Updates'),
          ),
        ],
      ),
    );
  }
}
