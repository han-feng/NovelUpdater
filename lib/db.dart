import 'dart:async' show Future;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:quicklibs/quicklibs.dart';

class Repository {
  BuildContext context;
  Map<String, ProvinceConfig> provinces;
  Map<String, dynamic> config55128;

  Repository(this.context) {
    _loadConfig();
  }

  _loadConfig() async {
    var configStr =
        await DefaultAssetBundle.of(context).loadString('assets/config.json');
    dynamic config = json.decode(configStr);
    Map<String, dynamic> ps = config['provinces'];
    provinces = ps.map((String key, dynamic value) {
      return new MapEntry(key, new ProvinceConfig.fromJson(value));
    });

    config55128 = config['55128'];
    print(provinces);
    print(config55128);
  }

  // 从本地加载数据
  List<Item> loadData(String province, String date) {
    List<Item> items = new List<Item>();
    return items;
  }

  // 保存数据到本地
  void saveData(String province) async {}

  // 检查网上数据源，更新本地数据
  void update(String province) async {
    // 获取当前期次
    // 获取下一期次及时间
    // 确定更新数据范围

    // 保存数据到本地

    // 重新计算推荐建议
  }

  // 全部更新
  void updateAll() async {
    provinces.forEach((key, value) => {update(key)});
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
  static final DateTime startDay = new DateTime(2018, 1, 1);

  // TODO 将 id 分解为 date 和 no，有利于按行列存储
  String id;
  Set<int> data;

  Item(this.id, this.data);

  Item.fromInt(int num) {
    data = new Set<int>();
    for (int i = 0; i < 11; i++) {
      if (1 & num > 0) {
        data.add(i + 1);
      }
      num >>= 1;
    }
    String id1 = (num % 100).toString();
    if (id1.length == 1) id1 = '0$id1';
    int id2 = num ~/ 1;
    id =
        Time.format(startDay.add(new Duration(days: id2)), 'yyyyMMdd') + '$id1';
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
    DateTime day = new DateTime.fromMicrosecondsSinceEpoch(d * 1000);
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
    Set<int> d = new Set<int>();
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
