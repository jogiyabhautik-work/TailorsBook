import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/design_system.dart';
import '../models/template_model.dart';
import '../../../models/measurement_template.dart';
import '../../../widgets/common/provider_wrappers.dart';
import '../../../main.dart';

class TemplateDetailScreen extends StatefulWidget {
  final TemplateModel template;

  const TemplateDetailScreen({super.key, required this.template});

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  bool _isDownloading = false;

  Future<void> _downloadTemplate() async {
    setState(() => _isDownloading = true);

    try {
      final templateProvider = TemplateProviderWrapper.of(context, listen: false);
      
      // Convert Marketplace TemplateModel to Local ProductTemplate
      final localTemplate = ProductTemplate(
        id: '', // Empty ID means new local template
        name: '${widget.template.name} (Marketplace)',
        category: TemplateCategory.values.firstWhere(
          (e) => e.name == widget.template.category.toLowerCase(),
          orElse: () => TemplateCategory.custom,
        ),
        fields: widget.template.measurements.keys.map((key) {
          return MeasurementField(
            id: DateTime.now().millisecondsSinceEpoch.toString() + key,
            label: key,
          );
        }).toList(),
      );

      final success = await templateProvider.addTemplate(localTemplate);
      
      if (success != null && mounted) {
        showGlobalSnackBar('Template downloaded and saved to My Templates!');
        Navigator.pop(context);
      } else if (mounted) {
        showGlobalSnackBar('Failed to download template', isError: true);
      }
    } catch (e) {
      debugPrint('Error downloading template: $e');
      if (mounted) showGlobalSnackBar('An error occurred', isError: true);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Template Details',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.style, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.template.name,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.template.category,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn('Downloads', widget.template.downloadCount.toString(), Icons.download),
                      _buildStatColumn('Fields', widget.template.measurements.length.toString(), Icons.format_list_numbered),
                      _buildStatColumn('Added', DateFormat('MMM dd, yyyy').format(widget.template.createdAt), Icons.calendar_today),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (widget.template.fittingStyle != null && widget.template.fittingStyle!.isNotEmpty) ...[
              Text(
                'Fitting Style',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.template.fittingStyle!,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (widget.template.stitchingNotes != null && widget.template.stitchingNotes!.isNotEmpty) ...[
              Text(
                'Stitching Notes',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.template.stitchingNotes!,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Measurements Included',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.template.measurements.keys.map((key) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.straighten, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Text(
                      key,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 48), // Padding for bottom button
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isDownloading ? null : _downloadTemplate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isDownloading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Save to My Templates',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
