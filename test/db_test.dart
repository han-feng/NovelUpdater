import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_updater/main.dart';
import 'package:novel_updater/db.dart';

void main() {
  testWidgets('DBUtil', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.autorenew));
    await tester.pump();
    expect(find.text("推荐参与【2、5、8】山东"), findsOneWidget);
  });
}
