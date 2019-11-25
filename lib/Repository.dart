import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/services.dart';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

//import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;

import 'package:quicklibs/quicklibs.dart';

import 'Item.dart';
import 'Suggestion.dart';
import 'ProvinceConfig.dart';

class Repository {
  final Dio dio = Dio();
  final CookieJar cookieJar = CookieJar();
  final List<Suggestion> suggestions = List<Suggestion>();
  final header = {
    "user-agent":
        "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36"
  };
  bool _inited = false;
  bool refreshing = false; //防止并发刷新

  BuildContext context;
  Map<String, ProvinceConfig> provinces;
  Map<String, dynamic> config55128;
  Map<String, dynamic> configYdniu;
  Map<String, List<Item>> onlineCached =
      Map<String, List<Item>>(); // 在线数据缓存，只保存当天数据
  VoidCallback onChange;

  Repository(this.context, this.onChange) {
    dio.interceptors.add(CookieManager(cookieJar));
//    _loadConfig().then((config) => refresh());
  }

  _init() async {
    if (_inited) return;
    await _loadConfig();
    _inited = true;
  }

  refresh() async {
    if (!_inited) {
      await _init();
    }
    if (refreshing) return; //防止并发刷新

    print("刷新");
    refreshing = true;
    try {
      List<Suggestion> results = List<Suggestion>();
      for (var key in provinces.keys) {
        var result = await _update(key);
        print(">>> $result");
        results.addAll(result);
        sleep(Duration(seconds: 1));
      }

      results.sort((a, b) {
        if (a.recommended != b.recommended) {
          // 是否推荐
          return a.recommended ? -1 : 1;
        } else if (a.count != b.count) {
          // 连续次数，倒序
          return b.count.compareTo(a.count);
        } else if (a.period != b.period) {
          // 期次，倒序
          return b.period.compareTo(a.period);
        } else {
          // 省份
          return a.province.compareTo(b.province);
        }
      });

      suggestions.clear();
      suggestions.addAll(results);

      onChange();
    } finally {
      refreshing = false;
    }
  }

  _loadConfig() async {
    AssetBundle bundle;
    if (context != null) {
      bundle = DefaultAssetBundle.of(context);
    } else {
      bundle = rootBundle;
    }
    var configStr = await bundle.loadString('assets/config.json');

    dynamic config = json.decode(configStr);
    Map<String, dynamic> ps = config['provinces'];
    provinces = ps.map((String key, dynamic value) {
      return MapEntry(key, ProvinceConfig.fromJson(value));
    });

    config55128 = config['55128'];
    configYdniu = config['ydniu'];
  }

  /// 从本地加载数据
  List<Item> _loadData(String province, String date) {
    List<Item> items = List<Item>();
    // 加载 assets 数据
    // 加载 本地存储数据
    return items;
  }

  /// 保存数据到本地
  _saveData(String province, List<Item> data) async {}

  /// 获取在线数据
  Future<dynamic> _getOnLineData(String province) async {
    String baseUrl = configYdniu['baseUrl'];
    baseUrl = baseUrl.replaceAll("\$province", province);
//    print(">>>" + baseUrl);

    var response = await dio.get(baseUrl);
    if (response.statusCode != 200) {
      return null;
    }
//    print(cookieJar.loadForRequest(Uri.parse(baseUrl)));

    var result = {};

    dom.Document document = parse(response.data);
    // 解析最新数据
    List<dom.Element> trs = document.querySelectorAll("#tabtrend>tbody>tr");
    //  List<ItemEntity> data = [];
    String data = "";
    if (trs.isNotEmpty) {
      for (int i = 0; i < trs.length; i++) {
        List<dom.Element> tds = trs[i].querySelectorAll("td");
        for (int j = 0; j < min(tds.length, 6); j++) {
          data += tds[j].text + ", ";
        }
        data += "\n";
//    data = List.generate(images.length, (i){
//      return ItemEntity(
//          title: images[i].attributes['alt'],
//          imgUrl: images[i].attributes['data-original']);
//    });
      }
    }
    return result;
  }

  /// 获取在线数据
  Future<dynamic> _getOnLineData2(String province) async {
    // AJAX 方式
    String baseUrl = configYdniu['mobileBaseUrl'];
    baseUrl = baseUrl.replaceAll("\$province", province);

    var response = await dio.post(baseUrl,
        data: FormData.fromMap(
            {"method": "CheckUpdate", "qs": "25"})); // index : 0
    if (response.statusCode == 200) {
//      print(response.data);
      dynamic responseData = json.decode(response.data);
      if (responseData["success"] == true) {
        var resp = responseData["result"];
        print(resp["issue"]);
        dom.Document document = parse("<table>" + resp["issue"] + "<\/table>");
        // 解析最新数据
        List<dom.Element> trs = document.querySelectorAll("td");
        int max = int.parse(trs.last.text);
        print(">>>>>> $max");
        var i = max, v;
        // TODO 完成onlineCached填充逻辑
        List<Item> items = onlineCached.putIfAbsent(province, () {
          return List<Item>(max);
        });
        if (items.length < max) {
          items.length = max;
        }
        final String prefix = Time.format(DateTime.now(), "yyyyMMdd");
        for (var element in trs.reversed) {
          if (i <= 0) break;
          v = int.parse(element.text);
          if (v != i) {
            print("ERROR: >>>>>>>> $v != $i");
          }
          if (items[i - 1] == null) {
            var id = i.toString().padLeft(2, "0");
            items[i - 1] = Item("$prefix$id", {1, 2, 3});
          }
          i--;
        }
      }
    }
  }

  /// 更新下一期次信息
  _updateNextData(String province) async {
    String baseUrl = configYdniu['baseUrl'];
    baseUrl = baseUrl.replaceAll("\$province", province);
//    print(">>>" + baseUrl);

    // 获取下一期次及时间
    DateTime now1 = DateTime.now();
    var response = await dio.post(baseUrl,
        data: FormData.fromMap({"method": "GetCurrIsuse"}));
    DateTime now2 = DateTime.now();

    if (response.statusCode == 200) {
//      print(response.data);
      dynamic responseData = json.decode(response.data);
      if (responseData["success"] == true) {
        var resp = responseData["result"];
        ProvinceConfig provinceConfig = provinces[province];
//        provinceConfig.lastNo = lastNo;
        provinceConfig.nextNo = resp["name"];
        // 计算本地与服务端时间差
        DateTime serverTime = DateTime.parse((resp["time"]));
        var d1 = now1.difference(serverTime).inSeconds;
        var d2 = now2.difference(serverTime).inSeconds;
        provinceConfig.duration = (d1 + d2) ~/ 2;
        // 转换为本地时间
        provinceConfig.nextTime = DateTime.parse(resp["end"])
            .add(Duration(seconds: provinceConfig.duration));
        print(provinceConfig);
      }
    }
  }

  /// 检查网上数据源，更新本地数据
  Future<List<Suggestion>> _update(String province) async {
    // 更新下一期次信息
    await _updateNextData(province);
    // 确定更新数据范围
    // 存在一种可能，当前期次正在开奖，暂时没有数据，下一期次已经开始投注
    // 1) 获取最新期次编号
    await _getOnLineData2(province);
    // 2) 获取本地最后更新期次编号
    // 3) 补充在线数据（Ydniu）
    // 4) 补充历史数据

    // 保存数据到本地

    // 重新计算推荐建议
    List<Suggestion> result = new List<Suggestion>();
    result.add(Suggestion(province, "2019010101", [2, 5, 8], 14));
    result.add(Suggestion(province, "2018123199", [2, 3, 8], 10));
    return result;
  }
}
