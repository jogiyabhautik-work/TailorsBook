import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailorsbook/widgets/common/update_tile.dart';

void main() {
  testWidgets('shows version, subtitle and Check button', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: UpdateTile(
          title: 'App Updates',
          subtitle: 'Check for updates',
          version: '1.0.0',
          onCheck: () => tapped = true,
        ),
      ),
    ));

    expect(find.text('App Updates'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
    expect(find.text('Current Version: 1.0.0'), findsOneWidget);
    expect(find.text('Check for Updates'), findsOneWidget);

    await tester.tap(find.text('Check for Updates'));
    expect(tapped, true);
  });

  testWidgets('shows loading spinner instead of button text when loading=true', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: UpdateTile(
          title: 'App Updates',
          subtitle: 'Check',
          version: '1.0.0',
          loading: true,
          onCheck: () {},
        ),
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Check for Updates'), findsNothing);
  });

  testWidgets('shows status text when provided', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: UpdateTile(
          title: 'App Updates',
          subtitle: 'Check',
          version: '1.0.0',
          status: 'Update available: 1.2.0',
          onCheck: () {},
        ),
      ),
    ));

    expect(find.text('Update available: 1.2.0'), findsOneWidget);
  });

  testWidgets('button is disabled when loading', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: UpdateTile(
          title: 'App Updates',
          subtitle: 'Check',
          version: '1.0.0',
          loading: true,
          onCheck: () {},
        ),
      ),
    ));

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
