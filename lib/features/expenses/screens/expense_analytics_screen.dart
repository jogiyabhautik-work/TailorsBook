import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/design_system.dart';
import '../../../providers/expense_provider.dart';
import '../../../widgets/common/provider_wrappers.dart';
import '../../../models/shop_expense.dart';
// PDF Generation imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExpenseAnalyticsScreen extends StatefulWidget {
  const ExpenseAnalyticsScreen({super.key});

  @override
  State<ExpenseAnalyticsScreen> createState() => _ExpenseAnalyticsScreenState();
}

class _ExpenseAnalyticsScreenState extends State<ExpenseAnalyticsScreen> {
  int _touchedIndex = -1;

  Map<String, double> _calculateCategoryTotals(List<ShopExpense> expenses) {
    final Map<String, double> totals = {};
    for (var e in expenses) {
      final cat = e.category ?? 'Other';
      totals[cat] = (totals[cat] ?? 0) + e.amount;
    }
    return totals;
  }

  Future<void> _exportToPdf(BuildContext context, List<ShopExpense> expenses) async {
    final pdf = pw.Document();
    
    final totalAmount = expenses.fold(0.0, (sum, item) => sum + item.amount);
    final categoryTotals = _calculateCategoryTotals(expenses);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Expense Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Total Expenses: INR ${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 20),
            pw.Text('Expenses by Category:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...categoryTotals.entries.map((e) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(e.key),
                pw.Text('INR ${e.value.toStringAsFixed(2)}'),
              ]
            )),
            pw.SizedBox(height: 30),
            pw.Text('Detailed Transactions:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              context: context,
              headers: ['Date', 'Title', 'Category', 'Amount'],
              data: expenses.map((e) => [
                DateFormat('dd MMM yyyy').format(e.expenseDate),
                e.title,
                e.category ?? 'Other',
                'INR ${e.amount.toStringAsFixed(2)}',
              ]).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppColors.primary,
      Colors.amber,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final provider = ExpenseProviderWrapper.of(context);
    final expenses = provider.expenses;
    final totals = _calculateCategoryTotals(expenses);

    if (expenses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const Center(child: Text('No data to analyze.')),
      );
    }

    final chartSections = totals.entries.toList().asMap().entries.map((entry) {
      final isTouched = entry.key == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value.value,
        title: '${((entry.value.value / expenses.fold(0.0, (s, e) => s + e.amount)) * 100).toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Analytics',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportToPdf(context, expenses),
            tooltip: 'Export as PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
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
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: chartSections,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Category Breakdown',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...totals.entries.toList().asMap().entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value.key,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '₹${NumberFormat('#,##0').format(entry.value.value)}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
