// Smoke test for the LIVO app: builds the root widget and verifies the app
// shell renders without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livo/main.dart';

void main() {
  testWidgets('LIVO app builds and renders its MaterialApp', (
    WidgetTester tester,
  ) async {
    // Build the app (unauthenticated by default) and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();

    // The root MaterialApp is present and titled "LIVO".
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'LIVO');
  });
}
