import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';

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

  Future<String> _loadString(String assetKey) async {
    AssetBundle bundle;
    if (context != null) {
      bundle = DefaultAssetBundle.of(context);
    } else {
      bundle = rootBundle;
    }
    return await bundle.loadString(assetKey);
  }

  _loadConfig() async {
    var configStr = await _loadString('assets/config.json');

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

  /// 保存历史数据到本地
  _savePastData(String province, DateTime date, List<Item> data) async {
    // 保存数据
    // 更新缓存
  }

//  /// 获取在线数据
//  Future<dynamic> _getOnLineData(String province) async {
//    String baseUrl = configYdniu['baseUrl'];
//    baseUrl = baseUrl.replaceAll("\$province", province);
////    print(">>>" + baseUrl);
//
//    var response = await dio.get(baseUrl);
//    if (response.statusCode != 200) {
//      return null;
//    }
////    print(cookieJar.loadForRequest(Uri.parse(baseUrl)));
//
//    var result = {};
//
//    dom.Document document = parse(response.data);
//    // 解析最新数据
//    List<dom.Element> trs = document.querySelectorAll("#tabtrend>tbody>tr");
//    //  List<ItemEntity> data = [];
//    String data = "";
//    if (trs.isNotEmpty) {
//      for (int i = 0; i < trs.length; i++) {
//        List<dom.Element> tds = trs[i].querySelectorAll("td");
//        for (int j = 0; j < min(tds.length, 6); j++) {
//          data += tds[j].text + ", ";
//        }
//        data += "\n";
////    data = List.generate(images.length, (i){
////      return ItemEntity(
////          title: images[i].attributes['alt'],
////          imgUrl: images[i].attributes['data-original']);
////    });
//      }
//    }
//    return result;
//  }

  /// 更新在线数据
  _updateOnLineData(String province, [int fetchCount = 25]) async {
    // AJAX 方式
    String baseUrl = configYdniu['mobileBaseUrl'];
    baseUrl = baseUrl.replaceAll("\$province", province);

    var response = await dio.post(baseUrl,
        data: FormData.fromMap(
            {"method": "CheckUpdate", "qs": "$fetchCount"})); // index : 0
    if (response.statusCode == 200) {
      dynamic responseData = json.decode(response.data);
      if (responseData["success"] == true) {
        var resp = responseData["result"];
//        print(resp["body"]);
        // 解析期次列表
        dom.Document document = parse("<table>" + resp["issue"] + "<\/table>");
        List<dom.Element> trs = document.querySelectorAll("td");
        final int max = int.parse(trs.last.text);
        print(">>>>>> $max");
        // 初始化缓存对象
        List<Item> items = onlineCached.putIfAbsent(province, () {
          var list = List<Item>();
          list.length = max;
          return list;
        });
        if (items.length < max) {
          items.length = max;
        }
        // 解析数据内容
        document = parse("<table>" + resp["body"] + "<\/table>");
        List<dom.Element> bodys = document.querySelectorAll("td.td_c_blue");
        bodys = bodys.reversed.toList();
        // 加载数据到缓存
        final String prefix = Time.format(DateTime.now(), "yyyyMMdd");
        var i = max, v;
        for (var element in trs.reversed) {
          if (i <= 0) break;
          v = int.parse(element.text);
          if (v != i) {
            print("ERROR: >>>>>>>> $v != $i");
          }
          if (items[i - 1] == null) {
            // 仅处理缺失数据，不更新已有数据
            var id = i.toString().padLeft(2, "0");
            var data = bodys[max - i].text;
            items[i - 1] = Item.fromString("$prefix$id $data");
          } else {
            // 数据校验，逻辑稳定后去掉
            var id = i.toString().padLeft(2, "0");
            var data = bodys[max - i].text;
            var i1 = items[i - 1].toString();
            var i2 = Item.fromString("$prefix$id $data").toString();
            if (i1 != i2) {
              print("ERROR: >>>>>>>> $i1 != $i2");
            }
          }
          i--;
        }
//        ProvinceConfig provinceConfig = provinces[province];
//        provinceConfig.lastNo = "$prefix${max.toString().padLeft(2, '0')}";
//        provinceConfig.lastTime = DateTime.now();
      }
    }
  }

  /// 更新下一期次信息
  _updateNextData(String province) async {
    String baseUrl = configYdniu['baseUrl'];
    baseUrl = baseUrl.replaceAll(r"$province", province);

    // 获取下一期次及时间
    DateTime now1 = DateTime.now();
    var response = await dio.post(baseUrl,
        data: FormData.fromMap({"method": "GetCurrIsuse"}));
    DateTime now2 = DateTime.now();

    if (response.statusCode == 200) {
      print(response.data);
      dynamic responseData = json.decode(response.data);
      if (responseData["success"] == true) {
        var resp = responseData["result"];
        ProvinceConfig provinceConfig = provinces[province];
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

  Future<Map<String, List<String>>> _loadMap(String input) async {
    var lines = input.split(RegExp(r"(\r|\n)+"));
    Map<String, List<String>> output;
    if (lines.length > 0) {
      output = Map<String, List<String>>();
      for (var line in lines) {
        var data = line.split(RegExp(r"(,|\s)+"));
        output[data[0]] = data.sublist(1);
      }
    }
    return output;
  }

  /// 获取本地存储的最后更新数据编号
  Future<String> _getLocalUpdateNo(String province) async {
    // 获取本地存储的最后更新期次编号
    // 先获取本地资源最后更新日期
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("[Prefs] >>> ${prefs.getKeys()}");
    var lastUpdatedDate = prefs.getString("$province.lastupdated");
    var lastUpdateNo;
    if (lastUpdatedDate != null) {
      List<String> datas = prefs.getStringList("$province-$lastUpdatedDate");
      // TODO 加载数据到缓存中
      lastUpdateNo = datas.last.split(RegExp(r"(,|\s)+"))[0];
    } else {
      // 如果找不到本地存储信息，改为获取内嵌资源最后更新期次编号
      // 先获取内嵌资源最后更新日期
      var lastUpdatedStr = await _loadString('assets/data/lastupdated.dat');
      var map = await _loadMap(lastUpdatedStr);
      var list = map[province];
      lastUpdatedDate = list[0];
      print(lastUpdatedDate);
      lastUpdatedStr = await _loadString(
          'assets/data/$province${lastUpdatedDate.substring(0, 6)}.txt');
      List<String> datas = lastUpdatedStr.trim().split(RegExp(r"(\r|\n)+"));
      // TODO 加载数据到缓存中
      print(datas.last);
      lastUpdateNo = datas.last.split(RegExp(r"(,|\s)+"))[0];
    }
    return lastUpdateNo;
  }

  /// 获取历史数据
  Future<List<Item>> _getPastData(String province, DateTime date) async {
    var baseUrl = config55128["baseUrl"] +
        provinces[province].url55128 +
        "?searchTime=" +
        Time.format(date, "yyyy-MM-dd");
    print("[PastUrl] $baseUrl");
    var response = await dio.get(baseUrl);
    List<Item> datas = List<Item>();
    if (response.statusCode == 200) {
      dom.Document document = parse(response.data);
      var trs = document.querySelectorAll("#chartData>tr");
      for (var element in trs) {
        var tds = element.querySelectorAll("td");
        if (tds.length < 6) {
          continue;
        }
        String value = "";
        for (var i = 0; i < 6; i++) {
          value += tds[i].text + " ";
        }
        datas.add(Item.fromString(value.trim()));
      }
    }
    return datas;
  }

  /// 检查网上数据源，更新本地数据
  Future<List<Suggestion>> _update(String province) async {
    // 更新下一期次信息
    await _updateNextData(province);
    // 确定更新数据范围
    // 存在一种可能，当前期次正在开奖，暂时没有数据，下一期次已经开始投注
    // 更新在线数据，获取最新期次编号
    await _updateOnLineData(province);
    // 获取本地最后更新期次编号
    var lastNo = await _getLocalUpdateNo(province);
    print("lastNo = $lastNo ; now = ${Time.format(DateTime.now(), 'yyMMdd')}");
    var lastDate = "20" + lastNo.substring(0, 6);
    var now = DateTime.now();
    if (lastDate != Time.format(now, "yyyyMMdd")) {
      // 补充历史数据
      var startDate = DateTime.parse(lastDate);
      var days = now.difference(startDate).inDays;
      for (var i = 0; i < days; i++) {
        var date = startDate.add(Duration(days: i));
        var datas = await _getPastData(province, date);
        print("[$province.pastData] $datas");
        // 保存历史数据到本地
        await _savePastData(province, date, datas);
        // TODO 设置本地数据最后更新记录
      }
    }
    var onlineData = onlineCached[province];
    if (onlineData.any((element) => (element == null))) {
      // 补充在线数据（Ydniu）
      var len = onlineData.length;
      if (len < 25)
        len = 25;
      else if (len < 50)
        len = 50;
      else if (len < 100)
        len = 100;
      else
        len = 200;
      await _updateOnLineData(province, len);
    }
    // 保存在线数据到本地
    // TODO 未完成
    // 重新计算推荐建议
    List<Suggestion> result = new List<Suggestion>();
    result.add(Suggestion(province, "2019010101", [2, 5, 8], 14));
    result.add(Suggestion(province, "2018123199", [2, 3, 8], 10));
    return result;
  }
}
