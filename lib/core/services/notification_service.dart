import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../widgets/common/responsive_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

enum NotificationEventType {
  orderCreated,
  stitchingStarted,
  trialReady,
  orderReady,
  delivered,
  paymentReminder,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  String _phoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('91') && digits.length == 12) return digits;
    if (digits.length == 10) return '91$digits';
    if (digits.length == 11) {
      final withoutPrefix = digits.startsWith('0') ? digits.substring(1) : digits;
      if (withoutPrefix.length == 10) return '91$withoutPrefix';
    }
    return digits;
  }

  bool isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 12;
  }

  String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) return '******';
    return '${digits.substring(0, 3)}****${digits.substring(digits.length - 3)}';
  }

  // Template definitions
  static final Map<NotificationEventType, String> _templates = {
    NotificationEventType.orderCreated:
        'Hello {customer_name}, your order #{order_id} for {garment_type} has been created at {shop_name}. Delivery by {delivery_date}.',
    NotificationEventType.stitchingStarted:
        'Hello {customer_name}, stitching has started on your #{order_id} ({garment_type}) at {shop_name}. Will update you soon.',
    NotificationEventType.trialReady:
        'Hello {customer_name}, your {garment_type} (#{order_id}) is ready for trial fitting at {shop_name}. Please visit for a trial.',
    NotificationEventType.orderReady:
        'Hello {customer_name}, your {garment_type} (#{order_id}) is ready for delivery at {shop_name}. Please collect at your earliest.',
    NotificationEventType.delivered:
        'Hello {customer_name}, your {garment_type} (#{order_id}) has been delivered. Thank you for choosing {shop_name}!',
    NotificationEventType.paymentReminder:
        'Hello {customer_name}, this is a reminder for pending balance of ₹{balance_amount} on order #{order_id} ({garment_type}) at {shop_name}. Please clear at your earliest.',
  };

  String generateMessage(NotificationEventType type, Map<String, String> variables) {
    String template = _templates[type] ?? '';
    for (final entry in variables.entries) {
      template = template.replaceAll('{${entry.key}}', entry.value);
    }
    return template;
  }

  Map<String, String> _buildVariables({
    required String customerName,
    required String orderId,
    required String garmentType,
    String trialDate = '',
    String deliveryDate = '',
    String balanceAmount = '',
    String shopName = 'TailorsBook',
    String shopPhone = '',
  }) {
    return {
      'customer_name': customerName,
      'order_id': orderId,
      'garment_type': garmentType,
      'trial_date': trialDate,
      'delivery_date': deliveryDate,
      'balance_amount': balanceAmount,
      'shop_name': shopName,
      'shop_phone': shopPhone,
    };
  }

  Future<bool> sendWhatsApp({
    required BuildContext context,
    required String phone,
    required NotificationEventType eventType,
    required String customerName,
    required String orderId,
    required String garmentType,
    String trialDate = '',
    String deliveryDate = '',
    String balanceAmount = '',
    String shopName = 'TailorsBook',
    String shopPhone = '',
    String? customerId,
    String? orderUuid,
  }) async {
    if (!isValidPhone(phone)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid phone number. Cannot send WhatsApp message.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    final message = generateMessage(eventType, _buildVariables(
      customerName: customerName,
      orderId: orderId,
      garmentType: garmentType,
      trialDate: trialDate,
      deliveryDate: deliveryDate,
      balanceAmount: balanceAmount,
      shopName: shopName,
      shopPhone: shopPhone,
    ));

    final messagePreview = message.length > 100
        ? '${message.substring(0, 100)}...'
        : message;

    if (!context.mounted) return false;

    final confirmed = await showResponsiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Send via WhatsApp?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.chat_rounded, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      messagePreview,
                      style: TextStyle(fontSize: 12, color: Colors.green.shade900, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'WhatsApp will open. Tap Send to send the message.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('OPEN WHATSAPP'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    final encoded = Uri.encodeComponent(message);
    final formattedPhone = _phoneNumber(phone);
    final uri = Uri.parse('https://wa.me/$formattedPhone?text=$encoded');

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) {
        _logNotification(
          customerId: customerId,
          orderId: orderUuid,
          eventType: eventType,
          phoneMasked: _maskPhone(phone),
          messagePreview: messagePreview,
          status: 'opened',
        );
      } else {
        _logNotification(
          customerId: customerId,
          orderId: orderUuid,
          eventType: eventType,
          phoneMasked: _maskPhone(phone),
          messagePreview: messagePreview,
          status: 'failed',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp. Is it installed?'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
      return launched;
    } catch (e) {
      _logNotification(
        customerId: customerId,
        orderId: orderUuid,
        eventType: eventType,
        phoneMasked: _maskPhone(phone),
        messagePreview: messagePreview,
        status: 'failed',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _logNotification({
    String? customerId,
    String? orderId,
    NotificationEventType? eventType,
    String phoneMasked = '',
    String messagePreview = '',
    String status = 'opened',
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('notification_logs').insert({
        'id': const Uuid().v4(),
        'user_id': userId,
        'customer_id': ?customerId,
        'order_id': ?orderId,
        'channel': 'whatsapp_manual',
        'event_type': eventType?.name ?? 'unknown',
        'phone_masked': phoneMasked,
        'message_preview': messagePreview,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[NotificationService] Failed to log notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotificationHistory({
    String? orderId,
    String? customerId,
    int limit = 20,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final orderFilter = _supabase
          .from('notification_logs')
          .select()
          .eq('user_id', userId);

      var query = orderFilter;
      if (orderId != null) {
        query = query.eq('order_id', orderId) as dynamic;
      }
      if (customerId != null) {
        query = query.eq('customer_id', customerId) as dynamic;
      }

      final response = await query.order('created_at', ascending: false).limit(limit);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[NotificationService] Failed to fetch notification history: $e');
      return [];
    }
  }
}
