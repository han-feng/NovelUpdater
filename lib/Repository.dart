import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

//import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;

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

  BuildContext context;
  Map<String, ProvinceConfig> provinces;
  Map<String, dynamic> config55128;
  Map<String, dynamic> configYdniu;

  Repository(this.context) {
    dio.interceptors.add(CookieManager(cookieJar));
    _loadConfig().then((config) => refresh());
  }

  refresh() async {
    print("刷新");

    for (var key in provinces.keys) {
      var result = await _update(key);
      print(">>> $result");
      sleep(Duration(seconds: 1));
    }

    suggestions.sort((a, b) {
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

  /// 获取当前期次信息
  Future<dynamic> _getLastData(province) async {
    String baseUrl = configYdniu['baseUrl'];
    baseUrl = baseUrl.replaceAll("\$province", province);
    print(">>>" + baseUrl);

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
    result["datas"] = data;

    // 获取下一期次及时间
    response = await dio.post(baseUrl,
        data: FormData.fromMap({"method": "GetCurrIsuse"}));
    if (response.statusCode != 200) {
      return null;
    }
    result["last"] = response.data;

    return result;
  }

  /// 检查网上数据源，更新本地数据
  _update(String province) async {
    // 获取当前期次
    var peroidInfo = await _getLastData(province);
    print(peroidInfo);
    // 获取下一期次及时间
    // 确定更新数据范围

    // 保存数据到本地

    // 重新计算推荐建议
    suggestions.removeWhere((e) => e.province == province);

    suggestions.add(Suggestion(province, "2019010101", [2, 5, 8], 14));
    suggestions.add(Suggestion(province, "2018123199", [2, 3, 8], 10));
  }
}
