import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../models/fabric_model.dart';
import '../../core/utils/design_system.dart';

class FabricInventoryScreen extends StatefulWidget {
  const FabricInventoryScreen({super.key});

  @override
  State<FabricInventoryScreen> createState() => _FabricInventoryScreenState();
}

class _FabricInventoryScreenState extends State<FabricInventoryScreen> {
  void _showFabricDialog([ShopFabricModel? fabric]) {
    final nameController = TextEditingController(text: fabric?.name ?? '');
    final typeController = TextEditingController(text: fabric?.fabricType ?? 'Cotton');
    final colorController = TextEditingController(text: fabric?.color ?? '');
    final qtyController = TextEditingController(text: fabric != null ? fabric.quantityMeters.toString() : '');
    final priceController = TextEditingController(text: fabric != null ? fabric.unitPricePerMeter.toString() : '');
    
    final formKey = GlobalKey<FormState>();
    final brandOrange = Theme.of(context).colorScheme.primary;

    showResponsiveDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              backgroundColor: DesignSystem.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusXl),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              title: Text(
                fabric == null ? 'Add Fabric' : 'Edit Fabric',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: DesignSystem.charcoal,
                ),
              ),
              content: KeyboardSafeDialogScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        enabled: !isSaving,
                        decoration: DesignSystem.inputField(
                          label: 'Fabric Name',
                          hint: 'e.g. Premium Linen',
                          prefixIcon: Icons.shopping_bag_outlined,
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: typeController,
                        enabled: !isSaving,
                        decoration: DesignSystem.inputField(
                          label: 'Fabric Type',
                          hint: 'e.g. Cotton, Linen',
                          prefixIcon: Icons.category_outlined,
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: colorController,
                        enabled: !isSaving,
                        decoration: DesignSystem.inputField(
                          label: 'Color',
                          hint: 'e.g. Navy Blue',
                          prefixIcon: Icons.color_lens_outlined,
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: qtyController,
                        enabled: !isSaving,
                        decoration: DesignSystem.inputField(
                          label: 'Quantity (Meters)',
                          hint: '0.0',
                          prefixIcon: Icons.linear_scale_rounded,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v!.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid number';
                          if (double.parse(v) < 0) return 'Cannot be negative';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: priceController,
                        enabled: !isSaving,
                        decoration: DesignSystem.inputField(
                          label: 'Price per Meter (₹)',
                          hint: '0.0',
                          prefixIcon: Icons.currency_rupee_rounded,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v!.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid number';
                          if (double.parse(v) < 0) return 'Cannot be negative';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              actions: [
                OutlinedButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DesignSystem.charcoal,
                    side: const BorderSide(color: DesignSystem.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusBtn),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isSaving = true;
                            });

                            final provider = FabricProviderWrapper.of(context, listen: false);
                            final newFabric = ShopFabricModel(
                              id: fabric?.id ?? '',
                              shopId: fabric?.shopId ?? '',
                              name: nameController.text.trim(),
                              fabricType: typeController.text.trim(),
                              color: colorController.text.trim(),
                              quantityMeters: double.parse(qtyController.text.trim()),
                              unitPricePerMeter: double.parse(priceController.text.trim()),
                              createdAt: fabric?.createdAt ?? DateTime.now(),
                              updatedAt: DateTime.now(),
                            );

                            bool success;
                            if (fabric == null) {
                              success = await provider.addShopFabric(newFabric);
                            } else {
                              success = await provider.updateShopFabric(newFabric);
                            }

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }

                            if (!mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fabric saved successfully')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(provider.errorMessage ?? 'Error saving fabric')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    foregroundColor: DesignSystem.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignSystem.radiusBtn),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(DesignSystem.white),
                          ),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      typeController.dispose();
      colorController.dispose();
      qtyController.dispose();
      priceController.dispose();
    });
  }

  void _confirmDelete(ShopFabricModel fabric) {
    showResponsiveDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Fabric'),
        content: Text('Are you sure you want to delete ${fabric.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = FabricProviderWrapper.of(context, listen: false);
              final success = await provider.deleteShopFabric(fabric.id);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fabric deleted')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Error deleting fabric')));
              }
            },
            child: const Text('DELETE', style: TextStyle(color: DesignSystem.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = FabricProviderWrapper.of(context);
    final brandOrange = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: DesignSystem.surface,
      appBar: AppBar(
        title: const Text('Fabric Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: DesignSystem.white,
        foregroundColor: DesignSystem.charcoal,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.shopFabrics.isEmpty
              ? const EmptyStateWidget(
                  title: 'No fabrics in inventory',
                  subtitle: 'Add shop fabrics to track materials.',
                  icon: Icons.checkroom_rounded,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.shopFabrics.length,
                  itemBuilder: (context, index) {
                    final fabric = provider.shopFabrics[index];
                    final isLowStock = fabric.quantityMeters <= 5.0;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        onTap: () => _showFabricDialog(fabric),
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: brandOrange.withValues(alpha: 0.1),
                          child: Icon(Icons.texture_rounded, color: brandOrange),
                        ),
                        title: Text(fabric.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${fabric.color} • ${fabric.fabricType}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLowStock ? DesignSystem.error.withValues(alpha: 0.1) : DesignSystem.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${fabric.quantityMeters}m left',
                                    style: TextStyle(
                                      color: isLowStock ? DesignSystem.error : DesignSystem.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('₹${fabric.unitPricePerMeter}/m', style: TextStyle(color: DesignSystem.muted, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') _showFabricDialog(fabric);
                            if (val == 'delete') _confirmDelete(fabric);
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: DesignSystem.error))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFabricDialog(),
        backgroundColor: brandOrange,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Fabric'),
      ),
    );
  }
}
