import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailorsbook/widgets/bottom_sheets/whats_new_sheet.dart';

void main() {
  testWidgets('shows title, version, description and GOT IT button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => WhatsNewSheet.show(context,
              title: 'New Features',
              description: 'Bug fixes and improvements.',
              latestVersion: '1.2.0',
            ),
            child: const Text('Show'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text("What's New"), findsOneWidget);
    expect(find.text('Version 1.2.0'), findsOneWidget);
    expect(find.text('New Features'), findsOneWidget);
    expect(find.text('Bug fixes and improvements.'), findsOneWidget);
    expect(find.text('GOT IT'), findsOneWidget);
  });

  testWidgets('tapping GOT IT dismisses the sheet', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => WhatsNewSheet.show(context,
              title: 'New Features',
              description: 'Bug fixes and improvements.',
              latestVersion: '1.2.0',
            ),
            child: const Text('Show'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('GOT IT'));
    await tester.pumpAndSettle();

    expect(find.text("What's New"), findsNothing);
  });
}
