import 'package:flutter/material.dart';
import '../../core/utils/design_system.dart';

class AlterationNotesScreen extends StatefulWidget {
  final String title;
  final String initialNote;

  const AlterationNotesScreen({
    super.key,
    required this.title,
    this.initialNote = '',
  });

  @override
  State<AlterationNotesScreen> createState() => _AlterationNotesScreenState();
}

class _AlterationNotesScreenState extends State<AlterationNotesScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: DesignSystem.white,
        foregroundColor: DesignSystem.charcoal,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Write alteration notes here...',
                  filled: true,
                  fillColor: DesignSystem.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _controller.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SAVE NOTES', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, '__SKIP_ALTERATION__'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DesignSystem.secondary,
                    side: BorderSide(color: DesignSystem.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SKIP ALTERATION (MARK READY)', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}
