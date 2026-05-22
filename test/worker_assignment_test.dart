import 'package:flutter_test/flutter_test.dart';
import 'package:tailorsbook/models/worker_model.dart';

void main() {
  group('Worker Assignment and Logging Regression Tests', () {
    test('WorkLog.fromMap handles missing/null data safely', () {
      final malformedData = <String, dynamic>{
        'id': null,
        'worker_id': null,
        'item_name': null,
        'quantity': null,
        'rate_per_piece': null,
        'total_amount': null,
        'work_date': null,
      };

      final log = WorkLog.fromMap(malformedData);

      expect(log.id, '');
      expect(log.workerId, '');
      expect(log.itemName, '');
      expect(log.quantity, 0);
      expect(log.ratePerPiece, 0.0);
      expect(log.totalAmount, 0.0);
      // It should default to current time
      expect(log.workDate.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
    });

    test('WorkerPayment.fromMap handles missing/null data safely', () {
      final malformedData = <String, dynamic>{
        'id': null,
        'worker_id': null,
        'amount': null,
        'payment_type': null,
        'payment_date': null,
        'notes': null,
      };

      final payment = WorkerPayment.fromMap(malformedData);

      expect(payment.id, '');
      expect(payment.workerId, '');
      expect(payment.amount, 0.0);
      expect(payment.paymentType, 'salary');
      expect(payment.notes, isNull);
    });
    
    test('WorkLog.fromMap parses valid data correctly', () {
      final validData = <String, dynamic>{
        'id': 'log-123',
        'worker_id': 'worker-456',
        'item_name': 'Shirt',
        'quantity': 5,
        'rate_per_piece': 150.0,
        'total_amount': 750.0,
        'work_date': '2024-05-20T10:00:00Z',
      };

      final log = WorkLog.fromMap(validData);

      expect(log.id, 'log-123');
      expect(log.workerId, 'worker-456');
      expect(log.itemName, 'Shirt');
      expect(log.quantity, 5);
      expect(log.ratePerPiece, 150.0);
      expect(log.totalAmount, 750.0);
      expect(log.workDate.year, 2024);
    });
  });
}
