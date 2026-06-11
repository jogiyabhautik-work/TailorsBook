import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/design_system.dart';

class FabricReferenceScreen extends StatelessWidget {
  const FabricReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.surface,
      appBar: AppBar(
        title: Text('Fabric Estimator', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: DesignSystem.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCategory('Men\'s Wear', [
              _FabricItem('Shirt (Full Sleeves)', '2.25 - 2.50 Meters', 'Standard 36" width'),
              _FabricItem('Shirt (Half Sleeves)', '2.00 Meters', 'Standard 36" width'),
              _FabricItem('Trousers / Pant', '1.20 - 1.30 Meters', 'Based on 58" width'),
              _FabricItem('Kurta', '3.00 Meters', 'Standard 36" width'),
              _FabricItem('Pyjama', '2.50 Meters', 'Standard 36" width'),
              _FabricItem('Suit (2-Piece)', '3.25 Meters', 'Based on 58" width'),
              _FabricItem('Waistcoat', '0.80 - 1.00 Meters', 'Based on 58" width'),
            ]),
            const SizedBox(height: 24),
            _buildCategory('Women\'s Wear', [
              _FabricItem('Kurti / Top', '2.50 Meters', 'Standard 44" width'),
              _FabricItem('Salwar Kameez (Set)', '4.50 - 5.00 Meters', 'Standard 44" width'),
              _FabricItem('Patiala Salwar', '3.50 Meters', 'Standard 44" width'),
              _FabricItem('Blouse', '0.80 - 1.00 Meters', 'Standard 44" width'),
              _FabricItem('Skirt (Long)', '3.00 - 4.00 Meters', 'Standard 44" width'),
              _FabricItem('Lehenga', '4.00 - 6.00 Meters', 'Varies by flare'),
            ]),
            const SizedBox(height: 32),
            _buildNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignSystem.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignSystem.primaryContainer.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.straighten_rounded, color: DesignSystem.primaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Estimated fabric requirements based on standard sizes and fabric widths.',
              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: DesignSystem.primaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(String title, List<_FabricItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w900, color: DesignSystem.muted, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: DesignSystem.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(item.width, style: TextStyle(color: DesignSystem.muted, fontSize: 11)),
                trailing: Text(item.meters, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: DesignSystem.primaryContainer)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNote() {
    return Center(
      child: Text(
        '* Requirements may vary based on person\'s height, build, and specific design requests (e.g., extra flare, pockets, or patterns).',
        textAlign: TextAlign.center,
        style: GoogleFonts.manrope(fontSize: 11, fontStyle: FontStyle.italic, color: DesignSystem.muted),
      ),
    );
  }
}

class _FabricItem {
  final String name;
  final String meters;
  final String width;

  _FabricItem(this.name, this.meters, this.width);
}
