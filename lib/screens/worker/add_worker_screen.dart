import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../../models/worker_model.dart';
import '../../main.dart';
import '../../core/utils/design_system.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/validation.dart';

class AddWorkerScreen extends StatefulWidget {
  final WorkerModel? workerToEdit;
  const AddWorkerScreen({super.key, this.workerToEdit});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  SalaryType _salaryType = SalaryType.piece_rate;
  DateTime _joiningDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.workerToEdit != null) {
      _nameController.text = widget.workerToEdit!.name;
      _phoneController.text = widget.workerToEdit!.phone ?? '';
      _salaryController.text = widget.workerToEdit!.monthlyRate.toString();
      _salaryType = widget.workerToEdit!.salaryType;
      _joiningDate = widget.workerToEdit!.joiningDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _saveWorker() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final workerProvider = WorkerProviderWrapper.of(context);
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      if (context.mounted) setState(() => _isSaving = false);
      return;
    }

    final worker = WorkerModel(
      id: widget.workerToEdit?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      tailorId: userId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      salaryType: _salaryType,
      monthlyRate: double.tryParse(_salaryController.text) ?? 0.0,
      joiningDate: _joiningDate,
      createdAt: widget.workerToEdit?.createdAt ?? DateTime.now(),
    );

    try {
      final workerData = {
        'tailor_id': userId,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'salary_type': _salaryType == SalaryType.monthly ? 'monthly' : 'piece_rate',
        'monthly_rate': double.tryParse(_salaryController.text) ?? 0.0,
        'joining_date': _joiningDate.toIso8601String().split('T')[0],
      };

      bool success = false;
      if (widget.workerToEdit == null) {
        success = await workerProvider.addWorker(worker);
      } else {
        success = await workerProvider.updateWorker(widget.workerToEdit!.id, workerData);
      }
      if (success && context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving worker: $e'), backgroundColor: DesignSystem.error),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isSaving = false);
    }
  }

  bool _isChanged() {
    final initialName = widget.workerToEdit?.name ?? '';
    final initialPhone = widget.workerToEdit?.phone ?? '';
    final initialSalary = widget.workerToEdit?.monthlyRate.toString() ?? '';

    return _nameController.text.trim() != initialName.trim() ||
        _phoneController.text.trim() != initialPhone.trim() ||
        (_salaryType == SalaryType.monthly && _salaryController.text.trim() != initialSalary.trim());
  }

  Future<bool> _onWillPop() async {
    if (!_isChanged()) return true;
    final shouldDiscard = await showResponsiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard Changes?', style: TextStyle(fontWeight: FontWeight.w900, color: DesignSystem.charcoal)),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CONTINUE EDITING', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DISCARD', style: TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.error)),
          ),
        ],
      ),
    );
    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    final brandBlack = DesignSystem.charcoal;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final willPop = await _onWillPop();
          if (willPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: DesignSystem.white,
      appBar: AppBar(
        title: Text(widget.workerToEdit == null ? 'Add New Worker' : 'Edit Worker', 
          style: const TextStyle(fontWeight: FontWeight.w800, color: DesignSystem.charcoal)),
        centerTitle: true,
        backgroundColor: DesignSystem.white,
        elevation: 0,
        foregroundColor: brandBlack,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: EdgeInsets.all(R.value(context, regular: 24, smallPhone: 16)),
        child: ConstrainedContent(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Basic Information'),
                SizedBox(height: R.value(context, regular: 16, smallPhone: 12)),
                _buildTextField(_nameController, 'Worker Name', Icons.person_rounded, validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Worker Name is required';
                  if (v.trim().length < 2) return 'Name must be at least 2 characters';
                  return null;
                }),
                SizedBox(height: R.gap(context)),
                _buildTextField(_phoneController, 'Phone Number', Icons.phone_rounded, keyboardType: TextInputType.phone, validator: (v) => Validation.validatePhone(v)),
                SizedBox(height: R.value(context, regular: 32, smallPhone: 24)),

                _buildSectionTitle('Salary Details'),
                SizedBox(height: R.value(context, regular: 16, smallPhone: 12)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: DesignSystem.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Wrap(
                  children: [
                    _buildSalaryTypeButton(SalaryType.piece_rate, 'Piece Rate', brandOrange),
                    _buildSalaryTypeButton(SalaryType.monthly, 'Monthly Salary', brandOrange),
                  ],
                ),
              ),
              if (_salaryType == SalaryType.monthly) ...[
                SizedBox(height: R.gap(context)),
                _buildTextField(_salaryController, 'Monthly Salary Amount', Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
              ],
              SizedBox(height: R.value(context, regular: 32, smallPhone: 24)),

              _buildSectionTitle('Joining Date'),
              SizedBox(height: R.value(context, regular: 16, smallPhone: 12)),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _joiningDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (!context.mounted) return;
                  if (picked != null) setState(() => _joiningDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignSystem.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: DesignSystem.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: brandOrange),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMMM dd, yyyy').format(_joiningDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_rounded, size: 18, color: DesignSystem.muted),
                    ],
                  ),
                ),
              ),
              SizedBox(height: R.value(context, regular: 48, smallPhone: 32)),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveWorker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    foregroundColor: DesignSystem.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: DesignSystem.white, strokeWidth: 2))
                      : Text(widget.workerToEdit == null ? 'Add Worker' : 'Update Worker',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              if (widget.workerToEdit != null) ...[
                SizedBox(height: R.gap(context)),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      showResponsiveDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Worker?'),
                          content: const Text('Are you sure you want to remove this worker and all their records?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () async {
                                final orderProvider = OrderProviderWrapper.of(context);
                                final activeOrders = orderProvider.activeOrderCountForWorker(widget.workerToEdit!.id);
                                
                                if (activeOrders > 0) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Cannot delete worker! They have $activeOrders active orders assigned. Please reassign them first.'),
                                      backgroundColor: DesignSystem.error,
                                    ),
                                  );
                                  return;
                                }

                                Navigator.pop(ctx); // Close confirmation dialog

                                // Show loading dialog
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (loadingCtx) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                try {
                                  final success = await WorkerProviderWrapper.of(context, listen: false).deleteWorker(widget.workerToEdit!.id);
                                  if (context.mounted) {
                                    Navigator.pop(context); // Close loading dialog
                                    if (success) {
                                      await WorkerProviderWrapper.of(context, listen: false).fetchWorkers();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Worker deleted successfully.'), backgroundColor: DesignSystem.success),
                                        );
                                        Navigator.pop(context); // Close edit/add screen
                                      }
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    Navigator.pop(context); // Close loading dialog
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: DesignSystem.error),
                                    );
                                  }
                                }
                              },
                              child: const Text('Delete', style: TextStyle(color: DesignSystem.error)),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignSystem.error,
                      side: const BorderSide(color: DesignSystem.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Delete Worker', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            SizedBox(height: R.value(context, regular: 100, smallPhone: 90)),
          ],
        ),
      ),
    ),
    ),
    ),
    ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DesignSystem.muted, letterSpacing: 0.5),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: DesignSystem.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: DesignSystem.surface)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5))),
      ),
      validator: validator ?? (value) => value == null || value.isEmpty ? 'Field required' : null,
    );
  }

  Widget _buildSalaryTypeButton(SalaryType type, String label, Color orange) {
    final isSelected = _salaryType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _salaryType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? DesignSystem.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: DesignSystem.charcoal.withValues(alpha: 0.05), blurRadius: 10)] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? orange : DesignSystem.muted,
            ),
          ),
        ),
      ),
    );
  }
}
