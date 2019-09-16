import 'dart:async' show Future;
import 'dart:convert' show json;
import 'package:flutter/material.dart';

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
  Map<String, List<String>> loadData(String province) {}

  // 保存数据到本地
  saveData(String province) async {}

  // 检查网上数据源，更新本地数据
  update(String province) {
    // 获取当前期次
    // 获取下一期次及时间
    // 确定更新数据范围

    // 保存数据到本地

    // 重新计算推荐建议
  }

  // 全部更新
  updateAll() {
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
  String id;
  Set<String> data;

  Item(this.id, this.data);

  Item.fromString(String str) {
    List<String> d = str.split(',').map((s) => _trimLeft0(s)).toList();
    id = d[0];
    data = d.sublist(1).toSet();
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
      i = _trimLeft0(i);
    }
    return data.contains('$i');
  }

  int difference(Set set) {
    int count = 0;
    set.forEach((i) => {if (contains(i)) count++});
    return count;
  }

  String toString() {
    return data.fold('$id', (current, next) => current += ',$next');
  }
}
