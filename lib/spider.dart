import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';

// 数据实体
class ItemEntity{
  final String title;
  final String imgUrl;

  ItemEntity({this.title,this.imgUrl});

  Map<String, dynamic> toJson(){
    return {
      'title': title,
      'imgUrl': imgUrl,
    };
  }
}

// 构造请求头
var header = {
  'user-agent' : 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) '+
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36',
};

// 数据的请求
request_data() async{
  var url = "https://www.55128.cn/zs/80_467.htm";

  var response = await http.get(url,headers: header);
  if (response.statusCode == 200) {
    return response.body;
  }
  return '<html>error! status:${response.statusCode}</html>';
}

// 数据的解析
html_parse() async{
  var html = await request_data();
  Document document = parse(html);
  // 这里使用css选择器语法提取数据
  List<Element> trs = document.querySelectorAll('#chartData > tr');
//  List<ItemEntity> data = [];
  String data = "";
  if(trs.isNotEmpty){
    for(int i=0; i< min(trs.length, 10);i++) {
      List<Element> tds = trs[i].querySelectorAll("td");
      for(int j=0;j<min(tds.length, 6);j++) {
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
  return data;
}

// 数据的储存
void save_data() async{
  var data = await html_parse();

  var json_str = json.encode({'items':data});
  // 将json写入文件中
  await File('data.json').writeAsString(json_str,flush: true);
}
