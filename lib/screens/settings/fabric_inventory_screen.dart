import 'package:flutter/material.dart';
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

    showResponsiveDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text(fabric == null ? 'Add Fabric' : 'Edit Fabric', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: KeyboardSafeDialogScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Fabric Name', hintText: 'e.g. Premium Linen'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'Fabric Type', hintText: 'e.g. Cotton, Linen'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'Color', hintText: 'e.g. Navy Blue'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: qtyController,
                  decoration: const InputDecoration(labelText: 'Quantity (Meters)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    if (double.parse(v) < 0) return 'Cannot be negative';
                    return null;
                  },
                ),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price per Meter (₹)'),
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
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

                Navigator.pop(ctx);
                
                bool success;
                if (fabric == null) {
                  success = await provider.addShopFabric(newFabric);
                } else {
                  success = await provider.updateShopFabric(newFabric);
                }

                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fabric saved successfully')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Error saving fabric')));
                  }
                }
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
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
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fabric deleted')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Error deleting fabric')));
                }
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
