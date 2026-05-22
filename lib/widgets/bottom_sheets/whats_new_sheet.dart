import 'package:flutter/material.dart';
import '../../core/utils/design_system.dart';

class WhatsNewSheet extends StatelessWidget {
  final String title;
  final String description;
  final String latestVersion;

  const WhatsNewSheet({
    super.key,
    required this.title,
    required this.description,
    required this.latestVersion,
  });

  static Future<void> show(BuildContext context, {
    required String title,
    required String description,
    required String latestVersion,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => WhatsNewSheet(
        title: title,
        description: description,
        latestVersion: latestVersion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: AnimatedPadding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + (keyboardHeight > 0 ? keyboardHeight : 0)),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.new_releases_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What\'s New', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 2),
                      Text('Version $latestVersion', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: DesignSystem.cardTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('GOT IT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
