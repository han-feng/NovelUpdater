import 'dart:convert';
import 'package:quicklibs/quicklibs.dart';

class Item {
  static final DateTime startDay = DateTime(2018, 1, 1);

  // TODO 将 id 分解为 date 和 no，有利于按行列存储
  String id;
  Set<int> data;

  Item(this.id, this.data);

  Item.fromInt(int num) {
    data = Set<int>();
    for (int i = 0; i < 11; i++) {
      if (1 & num > 0) {
        data.add(i + 1);
      }
      num >>= 1;
    }
    String id1 = (num % 100).toString();
    id1 = id1.padLeft(2, "0");
    int id2 = num ~/ 1;
    id = Time.format(startDay.add(Duration(days: id2)), 'yyyyMMdd') + '$id1';
  }

  Item.fromString(String str) {
    List<String> d = str.split(',');
    id = d[0];
    if (id.length == 8)
      id = '20' + id;
    else if (id.length < 8 || id.length == 9 || id.length > 10) {
      print('期次格式错误：$id');
    }
    data = d.sublist(1).map((s) => int.parse(s)).toSet();
  }

//  static String _trimLeft0(String str) {
//    str = str.trim();
//    while (str.startsWith('0')) {
//      str = str.substring(1);
//    }
//    return str;
//  }

  bool contains(var i) {
    if (i is String) {
      i = int.parse(i);
    }
    return data.contains(i);
  }

  int difference(Set set) {
    int count = 0;
    set.forEach((i) => {if (contains(i)) count++});
    return count;
  }

  int toInt() {
    int id1 = int.parse(id.substring(8));
    String id0 = id.substring(0, 8);
    int d = Time.parse(id0, 'yyyyMMdd');
    DateTime day = DateTime.fromMicrosecondsSinceEpoch(d * 1000);
    int id2 = day.difference(startDay).inDays;
    id1 = id2 * 100 + id1;
    return (id1 << 11) + intData;
  }

  String toString() {
    return data.fold('$id', (current, next) => current + ',$next');
  }

  int get intData =>
      data.reduce((current, next) => current + (1 << (next - 1)));

  set intData(int num) {
    Set<int> d = Set<int>();
    for (int i = 0; i < 11; i++) {
      if (1 & num > 0) {
        d.add(i + 1);
      }
      num >>= 1;
    }
    data = d;
  }

  String get base64Data => base64UrlEncode([intData]).replaceAll('=', '');
}
