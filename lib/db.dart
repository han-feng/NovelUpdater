import 'dart:async' show Future;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:quicklibs/quicklibs.dart';

class Repository {
  BuildContext context;
  Map<String, ProvinceConfig> provinces;
  Map<String, dynamic> config55128;
  List<Suggestion> _suggestions = List<Suggestion>();

  Repository(this.context) {
    _loadConfig();
//    refresh();
    _suggestions.add(Suggestion("sd", "山东", "2019010101", [2, 5, 8], 20, true));
    _suggestions
        .add(Suggestion("sd", "山东", "2018123199", [2, 3, 8], 10, false));
  }

  List<Suggestion> get suggestions {
    return _suggestions;
  }

  void refresh() async {
    print("刷新");
    provinces.forEach((key, value) => {_update(key)});
    _suggestions.sort((a, b) {
      if (a.recommended != b.recommended) {
        // 是否推荐
        return a.recommended ? -1 : 1;
      } else if (a.count != b.count) {
        // 连续次数
        return b.count.compareTo(a.count);
      } else {
        // 省份名称
        return a.provinceName.compareTo(b.provinceName);
      }
    });
  }

  _loadConfig() async {
    var configStr =
        await DefaultAssetBundle.of(context).loadString('assets/config.json');
    dynamic config = json.decode(configStr);
    Map<String, dynamic> ps = config['provinces'];
    provinces = ps.map((String key, dynamic value) {
      return MapEntry(key, ProvinceConfig.fromJson(value));
    });

    config55128 = config['55128'];
    print(provinces);
    print(config55128);
  }

// 从本地加载数据
  List<Item> _loadData(String province, String date) {
    List<Item> items = List<Item>();
    return items;
  }

// 保存数据到本地
  void _saveData(String province) async {}

// 检查网上数据源，更新本地数据
  void _update(String province) async {
    // 获取当前期次
    // 获取下一期次及时间
    // 确定更新数据范围

    // 保存数据到本地

    // 重新计算推荐建议
  }
}

class ProvinceConfig {
  final String name;
  final String url55128;

  ProvinceConfig(this.name, this.url55128);

  ProvinceConfig.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        url55128 = json['55128'];

  Map<String, dynamic> toJson() => {
        'name': name,
        '55128': url55128,
      };

  String toString() {
    return '{name:"$name","55128":"$url55128"}';
  }
}

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
    if (id1.length == 1) id1 = '0$id1';
    int id2 = num ~/ 1;
    id = Time.format(startDay.add(Duration(days: id2)), 'yyyyMMdd') + '$id1';
  }

  Item.fromString(String str) {
    List<String> d = str.split(',').map((s) => _trimLeft0(s)).toList();
    id = d[0];
    if (id.length == 8)
      id = '20' + id;
    else if (id.length < 8 || id.length == 9 || id.length > 10) {
      print('期次格式错误：$id');
    }
    data = d.sublist(1).map((s) => int.parse(s)).toSet();
  }

  static String _trimLeft0(String str) {
    str = str.trim();
    while (str.startsWith('0')) {
      str = str.substring(1);
    }
    return str;
  }

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

class Suggestion {
  String province; // 省份
  String provinceName; // 省份名称
  String period; // 期次
  List<int> numbers; // 数字组合
  int count; // 连续出现次数
  bool recommended; // 是否推荐

  Suggestion(this.province, this.provinceName, this.period, this.numbers,
      this.count, this.recommended);
}
