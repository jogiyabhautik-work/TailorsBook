import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../models/customer_model.dart';
import '../../providers/template_provider.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../widgets/common/measurement_entry_view.dart';
import '../../widgets/common/app_widgets.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/common/empty_state_widget.dart';

class MeasurementTab extends StatefulWidget {
  const MeasurementTab({super.key});

  @override
  State<MeasurementTab> createState() => _MeasurementTabState();
}

class _MeasurementTabState extends State<MeasurementTab> {
  String _searchQuery = "";
  DateTime _lastTapTime = DateTime.now();
  bool _isLoading = false;
  bool _formDirty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = TemplateProviderWrapper.of(context, listen: false);
      tp.fetchMeasurements();
    });
  }

  bool _isDoubleTap() {
    final now = DateTime.now();
    final difference = now.difference(_lastTapTime);
    final isDoubleTap = difference.inMilliseconds < 500;
    _lastTapTime = now;
    return isDoubleTap;
  }

  Future<void> _setCustomerWithLoading(Customer? customer) async {
    if (_isDoubleTap()) return;

    if (_formDirty) {
      final discard = await showResponsiveDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.radiusXl)),
          title: Text('Unsaved Changes', style: DesignSystem.cardTitle),
          content: const Text('Discard current measurements?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('CONTINUE', style: DesignSystem.bodyText),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: DesignSystem.error),
              child: const Text('DISCARD', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (discard != true || !context.mounted) return;
    }

    setState(() => _isLoading = true);
    try {
      final templateProvider = TemplateProviderWrapper.of(context);
      if (!context.mounted) return;
      templateProvider.setSelectedCustomer(customer);
    } finally {
      if (context.mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildHeader(Customer? customer, TemplateProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(DesignSystem.gridMargin, DesignSystem.s16, DesignSystem.gridMargin, DesignSystem.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MEASUREMENTS', style: DesignSystem.pageTitle),
              if (customer != null)
                GestureDetector(
                  onTap: _isLoading ? null : () => _setCustomerWithLoading(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: DesignSystem.s12, vertical: DesignSystem.s8),
                    decoration: BoxDecoration(
                      color: DesignSystem.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                      border: Border.all(color: DesignSystem.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_horiz_rounded, size: 16, color: DesignSystem.muted),
                        const SizedBox(width: DesignSystem.s4),
                        Text('Change', style: GoogleFonts.manrope(color: DesignSystem.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (customer != null) ...[
            const SizedBox(height: DesignSystem.md),
            Container(
              padding: const EdgeInsets.all(DesignSystem.s14),
              decoration: DesignSystem.card,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: DesignSystem.primaryContainer.withValues(alpha: 0.1),
                    child: Text(customer.name[0].toUpperCase(),
                        style: GoogleFonts.manrope(color: DesignSystem.primaryContainer, fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                  const SizedBox(width: DesignSystem.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name, style: DesignSystem.cardTitle),
                        Text(customer.phone, style: DesignSystem.caption),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_rounded, color: DesignSystem.primaryContainer, size: 20),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSelectCustomerSlivers(TemplateProvider provider) {
    final customerProvider = CustomerProviderWrapper.of(context);
    final filtered = customerProvider.customers
        .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    final recentCustomers = customerProvider.customers.take(5).toList();

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.gridMargin),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            AppSearchBar(
              onChanged: (val) => setState(() => _searchQuery = val),
              hintText: 'Search clients',
            ),

            if (_searchQuery.isEmpty && recentCustomers.isNotEmpty) ...[
              const SizedBox(height: DesignSystem.lg),
              Text('QUICK ACCESS', style: DesignSystem.sectionTitle),
              const SizedBox(height: DesignSystem.sm),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentCustomers.length,
                  itemBuilder: (context, index) {
                    final c = recentCustomers[index];

                    return GestureDetector(
                      onTap: _isLoading ? null : () => _setCustomerWithLoading(c),
                      child: Container(
                        width: 96,
                        margin: const EdgeInsets.only(right: DesignSystem.gridGutter),
                        decoration: BoxDecoration(
                          color: DesignSystem.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(DesignSystem.radiusXl),
                          border: Border.all(color: DesignSystem.outlineVariant, width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: DesignSystem.primaryContainer.withValues(alpha: 0.1),
                              child: Text(c.name[0],
                                  style: GoogleFonts.manrope(fontWeight: FontWeight.w900, color: DesignSystem.primaryContainer, fontSize: 16)),
                            ),
                            const SizedBox(height: DesignSystem.s8),
                            Padding(
                              padding: const EdgeInsets.all(DesignSystem.s4),
                              child: Text(c.name, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: DesignSystem.lg),
            Text('ALL CLIENTS', style: DesignSystem.sectionTitle),
            const SizedBox(height: DesignSystem.sm),
          ]),
        ),
      ),
      if (filtered.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            title: _searchQuery.isEmpty ? 'Start Recording Specs' : 'No Clients Found',
            subtitle: _searchQuery.isEmpty ? 'Select a client to record measurements' : 'Try a different search term',
            icon: Icons.straighten_rounded,
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSystem.gridMargin),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final c = filtered[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: DesignSystem.s8),
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => _setCustomerWithLoading(c),
                    child: Container(
                      padding: const EdgeInsets.all(DesignSystem.s14),
                      decoration: DesignSystem.card,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: DesignSystem.primaryContainer.withValues(alpha: 0.1),
                            child: Text(c.name[0],
                                style: GoogleFonts.manrope(color: DesignSystem.primaryContainer, fontWeight: FontWeight.w900, fontSize: 16)),
                          ),
                          const SizedBox(width: DesignSystem.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: DesignSystem.cardTitle),
                                Text(c.phone, style: DesignSystem.caption),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(DesignSystem.s8),
                            decoration: BoxDecoration(
                              color: DesignSystem.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: DesignSystem.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: filtered.length,
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = TemplateProviderWrapper.of(context);
    final selectedCustomer = provider.selectedCustomer;

    return Scaffold(
      backgroundColor: DesignSystem.surface,
      resizeToAvoidBottomInset: false,
      body: selectedCustomer != null
          ? Column(
              children: [
                SizedBox(height: topSafePadding(context)),
                _buildHeader(selectedCustomer, provider),
                Expanded(
                  child: MeasurementEntryView(
                    customer: selectedCustomer,
                    onSave: () => provider.setSelectedCustomer(null),
                    onDirtyChanged: (dirty) => _formDirty = dirty,
                  ),
                ),
              ],
            )
          : CustomScrollView(
               slivers: [
                 SliverToBoxAdapter(child: SizedBox(height: topSafePadding(context))),
                 SliverToBoxAdapter(child: _buildHeader(selectedCustomer, provider)),
                SliverToBoxAdapter(child: SizedBox(height: DesignSystem.s16)),
                ..._buildSelectCustomerSlivers(provider),
                SliverToBoxAdapter(
                  child: SizedBox(height: effectiveBottomPadding(context) + 16),
                ),
              ],
            ),
    );
  }
}
