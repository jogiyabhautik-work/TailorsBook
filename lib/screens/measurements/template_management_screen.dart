import 'package:flutter/material.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../models/measurement_template.dart';
import '../../main.dart';
import 'package:tailorsbook/core/utils/design_system.dart';

class TemplateManagementScreen extends StatefulWidget {
  const TemplateManagementScreen({super.key});

  @override
  State<TemplateManagementScreen> createState() => _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends State<TemplateManagementScreen> {
  String _tailorType = 'Both';
  bool _isLoadingMetadata = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = TemplateProviderWrapper.of(context, listen: false);
      tp.fetchMeasurements();
    });
  }

  void _loadMetadata() {
    final user = supabase.auth.currentUser;
    setState(() {
      _tailorType = user?.userMetadata?['tailor_type'] ?? 'Both';
      _isLoadingMetadata = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMetadata) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final templateProvider = TemplateProviderWrapper.of(context);
    final brandOrange = Theme.of(context).colorScheme.primary;
    final archivedIds = templateProvider.archivedTemplateIds;

    final isLadies = _tailorType == 'Ladies';
    final isGents = _tailorType == 'Gents';

    bool filterCategory(ProductTemplate t) {
      if (isLadies) return t.category == TemplateCategory.ladies || t.category == TemplateCategory.both;
      if (isGents) return t.category == TemplateCategory.gents || t.category == TemplateCategory.both;
      return true;
    }

    final filteredMyTemplates = templateProvider.myTemplates
        .where((t) => filterCategory(t))
        .toList();

    final filteredSystemTemplates = systemTemplates
        .where((t) => filterCategory(t))
        .toList();

    final archivedTemplates = templateProvider.allTemplatesWithArchived
        .where((t) => archivedIds.contains(t.id) && filterCategory(t))
        .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Measure Templates', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
        backgroundColor: DesignSystem.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: DesignSystem.charcoal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('MY CUSTOM TEMPLATES'),
            const SizedBox(height: 16),
            if (filteredMyTemplates.isEmpty)
              _buildEmptyState('No custom templates yet.\nCreate one or duplicate from system.')
            else
              ...filteredMyTemplates.map((t) => _buildTemplateCard(t, isSystem: false)),
            
            const SizedBox(height: 32),
            _buildSectionHeader('SYSTEM TEMPLATES'),
            const SizedBox(height: 16),
            if (filteredSystemTemplates.isEmpty)
              _buildEmptyState('No system templates match your category.')
            else
              ...filteredSystemTemplates.map((t) => _buildTemplateCard(t, isSystem: true)),

            if (archivedTemplates.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildSectionHeader('ARCHIVED'),
              const SizedBox(height: 16),
              ...archivedTemplates.map((t) => _buildTemplateCard(t, isSystem: systemTemplates.any((s) => s.id == t.id))),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTemplateDialog(context),
        backgroundColor: brandOrange,
        icon: const Icon(Icons.add, color: DesignSystem.white),
        label: const Text('CUSTOM TEMPLATE', style: TextStyle(color: DesignSystem.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showCreateTemplateDialog(BuildContext ctx) {
    final nameController = TextEditingController();
    TemplateCategory selectedCategory = TemplateCategory.ladies;

    showResponsiveDialog(
      context: ctx,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: const Text('Create Template', style: TextStyle(fontWeight: FontWeight.w900)),
          content: KeyboardSafeDialogScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Template Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: DesignSystem.surface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: DesignSystem.muted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TemplateCategory.values
                        .where((c) => c != TemplateCategory.both)
                        .map((c) => _buildCategoryOption(
                              c,
                              selectedCategory,
                              (val) => setDialogState(() => selectedCategory = val),
                              Theme.of(context).colorScheme.primary,
                              c.name.toUpperCase(),
                            ))
                        .toList(),
                  ),
                ],
              ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final template = ProductTemplate(
                  id: '',
                  name: nameController.text.trim(),
                  category: selectedCategory,
                  fields: [],
                );
                await TemplateProviderWrapper.of(context).addTemplate(template);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: DesignSystem.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('CREATE', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    ).whenComplete(nameController.dispose);
  }

  void _showDeleteDialog(ProductTemplate template) {
    showResponsiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Template?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          'Are you sure you want to delete "${template.name}"?\n\nThis action cannot be undone.',
          style: TextStyle(fontSize: 13, color: DesignSystem.charcoal, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              await TemplateProviderWrapper.of(context).deleteTemplate(template.id);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.error,
              foregroundColor: DesignSystem.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: DesignSystem.muted, letterSpacing: 1.2),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(color: DesignSystem.charcoal.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.dashboard_customize_outlined, size: 56, color: DesignSystem.outlineVariant),
          const SizedBox(height: 16),
          Text(msg, textAlign: TextAlign.center, style: TextStyle(color: DesignSystem.muted, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(ProductTemplate template, {required bool isSystem}) {
    final brandBlack = const Color(0xFF1C1C1C);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F1F1)),
        boxShadow: [
          BoxShadow(color: DesignSystem.charcoal.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _categoryColor(template.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _categoryColor(template.category).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      template.category.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.w900, 
                        color: _categoryColor(template.category),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      template.name,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: brandBlack, letterSpacing: -0.5),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              _buildPopupMenu(template, isSystem),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.straighten_rounded, size: 16, color: DesignSystem.muted),
              const SizedBox(width: 8),
              Text(
                '${template.fields.length} measurement fields',
                style: TextStyle(color: DesignSystem.muted, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(ProductTemplate template, bool isSystem) {
    final isArchived = TemplateProviderWrapper.of(context).isTemplateArchived(template.id);
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'clone') _showCloneDialog(template);
        if (val == 'delete') _showDeleteDialog(template);
        if (val == 'edit') _navigateToEdit(template);
        if (val == 'archive') _showArchiveDialog(template);
        if (val == 'unarchive') _showUnarchiveDialog(template);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'clone',
          child: Row(
            children: [
              Icon(Icons.content_copy_rounded, size: 20, color: DesignSystem.muted),
              const SizedBox(width: 12),
              const Text('Duplicate Template', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (!isSystem) PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 20, color: DesignSystem.muted),
              const SizedBox(width: 12),
              const Text('Edit Fields', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (!isSystem && !isArchived) PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive_rounded, size: 20, color: DesignSystem.muted),
              const SizedBox(width: 12),
              const Text('Archive Template', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (!isSystem && isArchived) PopupMenuItem(
          value: 'unarchive',
          child: Row(
            children: [
              Icon(Icons.unarchive_rounded, size: 20, color: DesignSystem.muted),
              const SizedBox(width: 12),
              const Text('Restore Template', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (!isSystem) PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 20, color: DesignSystem.error),
              const SizedBox(width: 12),
              const Text('Delete Template', style: TextStyle(fontWeight: FontWeight.w600, color: DesignSystem.error)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(Icons.more_horiz_rounded, color: DesignSystem.muted),
      ),
    );
  }

  void _showCloneDialog(ProductTemplate template) {
    final controller = TextEditingController(text: '${template.name} (Copy)');
    final brandOrange = Theme.of(context).colorScheme.primary;
    showResponsiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('Duplicate Template', style: TextStyle(fontWeight: FontWeight.w900)),
        content: KeyboardSafeDialogScrollView(
          child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'New Template Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
              ),
            ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              await TemplateProviderWrapper.of(context).cloneTemplate(template, controller.text);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brandOrange,
              foregroundColor: DesignSystem.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('CREATE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Widget _buildCategoryOption(TemplateCategory category, TemplateCategory selected, Function(TemplateCategory) onSelect, Color brandOrange, String label) {
    final isSelected = selected == category;
    return GestureDetector(
      onTap: () => onSelect(category),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? brandOrange.withValues(alpha: 0.1) : DesignSystem.muted.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? brandOrange : DesignSystem.muted.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 10,
            color: isSelected ? brandOrange : DesignSystem.muted,
          ),
        ),
      ),
    );
  }

  Color _categoryColor(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.ladies:
        return DesignSystem.primary;
      case TemplateCategory.gents:
        return DesignSystem.primary;
      case TemplateCategory.both:
        return DesignSystem.muted;
      case TemplateCategory.custom:
        return DesignSystem.success;
    }
  }

  void _showArchiveDialog(ProductTemplate template) {
    showResponsiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Archive Template?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          '${template.name} will be hidden from selection screens.\n\n'
          'Historical measurements linked to this template will remain fully readable.\n\n'
          'You can restore it anytime from the Archived section.',
          style: TextStyle(fontSize: 13, color: DesignSystem.charcoal, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              await TemplateProviderWrapper.of(context).archiveTemplate(template.id);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.charcoal,
              foregroundColor: DesignSystem.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('ARCHIVE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showUnarchiveDialog(ProductTemplate template) {
    showResponsiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Restore Template?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          '${template.name} will reappear in selection screens and measurement forms.',
          style: TextStyle(fontSize: 13, color: DesignSystem.charcoal, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              await TemplateProviderWrapper.of(context).unarchiveTemplate(template.id);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: DesignSystem.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('RESTORE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(ProductTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TemplateEditorScreen(template: template)),
    );
  }
}

class TemplateEditorScreen extends StatefulWidget {
  final ProductTemplate template;
  const TemplateEditorScreen({super.key, required this.template});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  late ProductTemplate _editingTemplate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editingTemplate = widget.template;
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Editing: ${_editingTemplate.name}', style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : () async {
              if (_editingTemplate.fields.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Cannot save empty template! Add at least one measurement field.'), backgroundColor: DesignSystem.error),
                 );
                 return;
              }
              setState(() => _isSaving = true);
              final success = await TemplateProviderWrapper.of(context).updateTemplate(_editingTemplate);
              if (!context.mounted) return;
              setState(() => _isSaving = false);
              if (success) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not save template changes.'), backgroundColor: DesignSystem.error),
                );
              }
            },
            icon: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle_rounded, color: DesignSystem.success, size: 28),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _editingTemplate.fields.length,
        itemBuilder: (context, index) {
          final field = _editingTemplate.fields[index];
          return ListTile(
            title: Text(field.label),
            subtitle: Text('Type: ${field.type.name}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: DesignSystem.error),
              onPressed: () {
                setState(() {
                  final newFields = List<MeasurementField>.from(_editingTemplate.fields)..removeAt(index);
                  _editingTemplate = _editingTemplate.copyWith(fields: newFields);
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFieldDialog,
        backgroundColor: brandOrange,
        child: const Icon(Icons.add, color: DesignSystem.white),
      ),
    );
  }

  void _showAddFieldDialog() {
    final labelController = TextEditingController();
    FieldType selectedType = FieldType.number;

    showResponsiveDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: const Text('Add Field'),
          content: KeyboardSafeDialogScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Field Label')),
                  DropdownButton<FieldType>(
                    value: selectedType,
                    items: FieldType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                    onChanged: (val) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      setDialogState(() => selectedType = val!);
                    },
                  ),
                ],
              ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            TextButton(
              onPressed: () {
                setState(() {
                  final newFields = List<MeasurementField>.from(_editingTemplate.fields)
                    ..add(MeasurementField(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      label: labelController.text,
                      type: selectedType,
                    ));
                  _editingTemplate = _editingTemplate.copyWith(fields: newFields);
                });
                Navigator.pop(context);
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    ).whenComplete(labelController.dispose);
  }
}
