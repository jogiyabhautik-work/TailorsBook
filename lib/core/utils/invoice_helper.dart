import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/order_model.dart';
import '../../../../models/customer_model.dart';
import '../../../../models/payment_model.dart';

class InvoiceHelper {
  static SupabaseClient get _supabase => Supabase.instance.client;

  static String _safeToken(String? raw, {int max = 8, String fallback = 'DRAFT'}) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return fallback;
    if (value.length <= max) return value.toUpperCase();
    return value.substring(0, max).toUpperCase();
  }

  static String _paymentStatusLabel(String status) {
    switch (status) {
      case 'paid': return 'PAID';
      case 'partial': return 'PARTIALLY PAID';
      default: return 'UNPAID';
    }
  }

  static Future<void> generateAndShareInvoice({
    required OrderModel order,
    required Customer customer,
    List<PaymentModel> payments = const [],
    List<Map<String, dynamic>> fabricInfo = const [],
    String? workerName,
  }) async {
    if (order.items.isEmpty) {
      throw Exception('Empty Order: Cannot generate invoice with no items.');
    }
    if (customer.name.trim().isEmpty) {
      throw Exception('Invalid Customer: Name is missing.');
    }
    if (order.totalPrice <= 0) {
      throw Exception('Invalid Total: Order total must be greater than zero.');
    }

    try {
      final pdf = pw.Document();
      final user = _supabase.auth.currentUser;
      final metadata = user?.userMetadata ?? {};

      final shopName = metadata['shop_name'] ?? 'TailorsBook Shop';
      final shopPhone = metadata['phone'] ?? '';
      // Support both 'address' (new key) and 'shop_address' (legacy key) for backward compatibility
      final shopAddress = metadata['address'] ?? metadata['shop_address'] ?? '';
      final gstNumber = metadata['gst_number'] ?? '';
      final welcomeMsg = metadata['pdf_welcome_msg'] ?? 'Thank you for choosing TailorsBook! Visit again.';
      final termsText = metadata['pdf_terms'] ?? '1. Goods once sold will not be taken back.\n2. Delivery dates are subject to work load.\n3. Trial is mandatory for perfect fitting.';
      final paymentInfo = metadata['pdf_payment_info'] ?? '';
      final showAddress = metadata['pdf_show_address'] ?? true;
      final showPhone = metadata['pdf_show_phone'] ?? true;
      final showGst = metadata['pdf_show_gst'] ?? true;
      final showCustomerPhone = metadata['pdf_show_customer_phone'] ?? true;
      final showItemPrices = metadata['pdf_show_item_prices'] ?? true;
      final showStatus = metadata['pdf_show_status'] ?? true;

      Uint8List? logoData;
      try {
        final shopLogoUrl = metadata['shop_logo_url'];
        if (shopLogoUrl != null && shopLogoUrl.toString().isNotEmpty) {
          final httpClient = HttpClient();
          try {
            final request = await httpClient.getUrl(Uri.parse(shopLogoUrl));
            final response = await request.close();
            if (response.statusCode == 200) {
              logoData = await consolidateHttpClientResponseBytes(response);
              debugPrint('InvoiceHelper: Using shop logo from $shopLogoUrl');
            }
          } finally {
            httpClient.close();
          }
        }
        if (logoData == null) {
          final ByteData data = await rootBundle.load('assets/images/TailorBook-square.jpg');
          logoData = data.buffer.asUint8List();
        }
      } catch (e) {
        debugPrint('InvoiceHelper: Failed to load shop logo, using default: $e');
        try {
          final ByteData data = await rootBundle.load('assets/images/TailorBook-square.jpg');
          logoData = data.buffer.asUint8List();
        } catch (_) {}
      }

      final orange = PdfColor.fromHex('#FF6B00');
      final dark = PdfColor.fromHex('#1C1C1C');
      final mid = PdfColor.fromHex('#444444');

      pw.Widget cell(String text, {pw.TextAlign align = pw.TextAlign.right, bool bold = false}) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          child: pw.Text(
            text,
            textAlign: align,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: dark,
            ),
          ),
        );
      }

      pw.Widget label(String text) {
        return pw.Text(
          text,
          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: mid, letterSpacing: 0.8),
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          header: (context) => pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(
                      shopName.toUpperCase(),
                      style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold, color: dark, letterSpacing: 0.5),
                    ),
                    pw.SizedBox(height: 4),
                    if (showAddress && shopAddress.isNotEmpty) pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.blueGrey600)),
                    if (showPhone && shopPhone.isNotEmpty) pw.Text('Phone: $shopPhone', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.blueGrey600)),
                    if (showGst && gstNumber.isNotEmpty) pw.Text('GSTIN: $gstNumber', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.blueGrey600)),
                  ]),
                  if (logoData != null)
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.orange200, width: 1.2),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Image(pw.MemoryImage(logoData), width: 54),
                    ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(height: 2.5, color: orange),
              pw.SizedBox(height: 16),
            ],
          ),
          build: (context) => [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  label('BILL TO'),
                  pw.SizedBox(height: 5),
                  pw.Text(customer.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: dark)),
                  if (showCustomerPhone && customer.phone.isNotEmpty) pw.Text('Phone: ${customer.phone}', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.blueGrey600)),
                  if (customer.address.isNotEmpty) pw.Text(customer.address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('INVOICE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: orange, letterSpacing: 2)),
                  pw.Text('#${_safeToken(order.id, max: 8)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  pw.SizedBox(height: 6),
                  pw.Text('Date :  ${DateFormat('dd MMM yyyy').format(order.createdAt)}', style: const pw.TextStyle(fontSize: 9.5)),
                  if (order.deliveryDate != null) pw.Text('Delivery :  ${DateFormat('dd MMM yyyy').format(order.deliveryDate!)}', style: const pw.TextStyle(fontSize: 9.5)),
                  if (order.trialDate != null) pw.Text('Trial :  ${DateFormat('dd MMM yyyy').format(order.trialDate!)}', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.orange900)),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: order.paymentStatus == 'paid' ? PdfColors.green50 : (order.paymentStatus == 'partial' ? PdfColors.orange50 : PdfColors.red50),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(
                        color: order.paymentStatus == 'paid' ? PdfColors.green800 : (order.paymentStatus == 'partial' ? PdfColors.orange800 : PdfColors.red800),
                        width: 0.7,
                      ),
                    ),
                    child: pw.Text(
                      _paymentStatusLabel(order.paymentStatus),
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: order.paymentStatus == 'paid' ? PdfColors.green800 : (order.paymentStatus == 'partial' ? PdfColors.orange800 : PdfColors.red800),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (showStatus) ...[
                    pw.SizedBox(height: 3),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        border: pw.Border.all(color: PdfColors.deepOrange800, width: 0.7),
                      ),
                      child: pw.Text(order.status.toUpperCase(), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: orange, letterSpacing: 1)),
                    ),
                  ],
                ]),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Worker info ──
            if (workerName != null && workerName.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'Assigned Tailor: $workerName',
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.blueGrey800),
                ),
              ),
              pw.SizedBox(height: 10),
            ],

            // ── Items Table ──
            pw.Table(
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(color: PdfColors.blueGrey100, width: 0.5),
                bottom: pw.BorderSide(color: PdfColors.blueGrey200, width: 0.5),
              ),
              columnWidths: const {0: pw.FlexColumnWidth(3.8), 1: pw.FlexColumnWidth(0.9), 2: pw.FlexColumnWidth(1.5), 3: pw.FlexColumnWidth(1.5)},
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: pw.Text('Garment / Product', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: pw.Text(showItemPrices ? 'Rate (Rs.)' : '-', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: pw.Text(showItemPrices ? 'Amount (Rs.)' : '-', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                  ],
                ),
                ...order.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: idx.isEven ? PdfColors.white : PdfColors.blueGrey50),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                        child: pw.Text(item.productName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: dark)),
                      ),
                      cell(item.quantity.toString(), align: pw.TextAlign.center),
                      cell(showItemPrices ? item.unitPrice.toStringAsFixed(0) : '-'),
                      cell(showItemPrices ? (item.quantity * item.unitPrice).toStringAsFixed(0) : '-', bold: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 8),

            // ── Fabric Usage ──
            if (fabricInfo.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    label('FABRIC USAGE'),
                    pw.SizedBox(height: 4),
                    ...fabricInfo.map((f) {
                      final name = f['fabric_name'] as String? ?? 'Fabric';
                      final meters = (f['meters'] as num?)?.toDouble() ?? 0.0;
                      final source = f['source'] as String? ?? '';
                      final itemName = f['item_name'] as String? ?? '';
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          '$itemName: $name ($source) - ${meters.toStringAsFixed(1)}m',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blueGrey700),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
            ],

            // ── Payment Summary ──
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                border: pw.Border.all(color: PdfColors.blueGrey200, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('Total Amount: Rs.${order.totalPrice.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Advance Paid: Rs.${order.advancePaid.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 9.5, color: order.advancePaid > 0 ? PdfColors.green800 : PdfColors.grey600)),
                    pw.Text('Balance Due: Rs.${order.pendingBalance.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 9.5, color: order.pendingBalance > 0 ? PdfColors.red900 : PdfColors.green900)),
                  ]),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: order.pendingBalance <= 0.01 ? PdfColors.green50 : PdfColors.red50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      order.pendingBalance <= 0.01 ? 'CLEARED' : 'DUE: Rs.${order.pendingBalance.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: order.pendingBalance <= 0.01 ? PdfColors.green800 : PdfColors.red800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // ── Payment History ──
            if (payments.isNotEmpty) ...[
              label('PAYMENT HISTORY'),
              pw.SizedBox(height: 6),
              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.blueGrey100, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.blueGrey200, width: 0.5),
                ),
                columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1.2), 2: pw.FlexColumnWidth(1.2), 3: pw.FlexColumnWidth(1.2)},
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6), child: pw.Text('Date', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6), child: pw.Text('Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6), child: pw.Text('Method', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6), child: pw.Text('Type', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                    ],
                  ),
                  ...payments.where((p) => p.refundStatus == 'none').map((p) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6), child: pw.Text(DateFormat('dd MMM yy').format(p.paymentDate), style: const pw.TextStyle(fontSize: 7.5))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6), child: pw.Text('Rs.${p.amount.toStringAsFixed(0)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6), child: pw.Text(p.paymentMethod.toUpperCase(), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey600))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6), child: pw.Text(p.isAdvance ? 'ADVANCE' : 'PAYMENT', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: p.isAdvance ? PdfColors.blue800 : PdfColors.green800))),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 10),
            ],

            // ── Order Timeline ──
            if (order.statusHistory.isNotEmpty) ...[
              label('ORDER TIMELINE'),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: order.statusHistory.map((entry) {
                    final date = DateTime.tryParse(entry['at'] ?? '') ?? DateTime.now();
                    final labelText = entry['label'] as String? ?? entry['to'] as String? ?? '';
                    final note = entry['note'] as String?;
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        children: [
                          pw.Text(DateFormat('dd MMM HH:mm').format(date), style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey600)),
                          pw.SizedBox(width: 8),
                          pw.Text(labelText.toUpperCase(), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: dark)),
                          if (note != null && note.isNotEmpty) ...[
                            pw.SizedBox(width: 4),
                            pw.Text('- $note', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              pw.SizedBox(height: 10),
            ],

            // ── Terms ──
            pw.Text(termsText, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700, lineSpacing: 2.5)),
            if (paymentInfo.toString().trim().isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text('Payment Info: $paymentInfo', style: const pw.TextStyle(fontSize: 8.2, color: PdfColors.blue900)),
            ],
            pw.SizedBox(height: 14),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: const pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(welcomeMsg, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.deepOrange800, lineSpacing: 2)),
            ),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final fileName = 'Invoice_${customer.name.replaceAll(' ', '_')}_${_safeToken(order.id, max: 5, fallback: 'TEMP')}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Invoice for ${customer.name}');
    } catch (e, stackTrace) {
      debugPrint('InvoiceHelper.generateAndShareInvoice Error: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Unable to generate invoice PDF. Please verify order and shop details.');
    }
  }

  static Future<void> generateAndShareAdvanceReceipt({
    required OrderModel order,
    required Customer customer,
    required double amount,
    String paymentMethod = 'cash',
  }) async {
    try {
      final pdf = pw.Document();
      final user = _supabase.auth.currentUser;
      final metadata = user?.userMetadata ?? {};
      final shopName = metadata['shop_name'] ?? 'TailorsBook Shop';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a6,
          build: (context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(18),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(shopName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 12),
                  pw.Text('ADVANCE RECEIPT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 12),
                  pw.Text('Customer: ${customer.name}'),
                  pw.Text('Order: ${order.orderToken.isNotEmpty ? order.orderToken : _safeToken(order.id, max: 6)}'),
                  pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
                  pw.Text('Method: ${paymentMethod.toUpperCase()}'),
                  pw.SizedBox(height: 12),
                  pw.Text('Rs. ${amount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 16),
                  pw.Text('Balance Due: Rs.${order.pendingBalance.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final fileName = 'AdvanceReceipt_${customer.name.replaceAll(' ', '_')}_${_safeToken(order.id, max: 5, fallback: 'TEMP')}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Advance receipt for ${customer.name}');
    } catch (e, stackTrace) {
      debugPrint('InvoiceHelper.generateAndShareAdvanceReceipt Error: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Unable to generate advance receipt PDF.');
    }
  }
}
