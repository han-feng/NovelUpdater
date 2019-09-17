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

  test("Item功能测试", () async {
    Item i = new Item.fromString('19010101,1,2,3,4,5');
    expect('2019010101,1,2,3,4,5', i.toString());

    i = new Item.fromString('19010101,01,02,3,04,5');
    expect('2019010101,1,2,3,4,5', i.toString());
    expect(74754079, i.toInt());
    expect('Hw', i.base64Data);

    i = new Item.fromInt(31);
    expect('2018010100,1,2,3,4,5', i.toString());
    expect(31, i.toInt());
    expect('Hw', i.base64Data);

    expect(true, i.contains(2));
    expect(true, i.contains('2'));
    expect(true, i.contains('02'));

    expect(1, i.difference(new Set.from([5, 6, 7])));
    expect(2, i.difference(new Set.from(['4', '05', '06'])));
    expect(3, i.difference(new Set.from([1, '2', '03'])));

    expect(2, 1 << 1);
    expect(4, 1 << 2);
    expect(1024, 1 << 10);

    i = new Item.fromInt(2047);
    expect('2018010100,1,2,3,4,5,6,7,8,9,10,11', i.toString());
  });
}
