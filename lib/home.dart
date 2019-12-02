import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:novel_updater/ProvinceConfig.dart';
import 'spider.dart' as spider;
import 'Repository.dart';
import 'Suggestion.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  Repository repository;
  String period = "";
  List<Suggestion> suggestions;
  Timer timer;

  @override
  void initState() {
    // 初始化，当前widget被插入到树中时调用
    super.initState();
    repository = Repository(this.context, () {
      setState(() {});
    });
    repository.refresh();
    suggestions = repository.suggestions;
    if (timer == null) {
      timer = Timer.periodic(Duration(seconds: 30), (as) {
        print(">>> timer run");
        setState(() {});
      });
    }
  }

  Future<void> _handleRefresh() async {
    await repository.refresh();
  }

  Widget buildListView(BuildContext context) {
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        Suggestion item = suggestions[index];
        Icon icon;
        Text title;
        ProvinceConfig province = repository.provinces[item.province];
        if (item.recommended) {
          icon =
              Icon(AntDesign.like1, color: Colors.yellow, semanticLabel: "推荐");
          title = Text("推荐参与 ${item.numbers} ${province.name}");
        } else {
          icon = Icon(Icons.block, semanticLabel: "不推荐");
          title = Text("${item.numbers} ${province.name}");
        }
        int diff = province.nextTime
            .add(new Duration(seconds: province.duration))
            .difference(DateTime.now())
            .inSeconds;
        diff = diff < 0 ? 0 : diff;

        return Card(
          child: ListTile(
            leading: icon,
            title: title,
            subtitle: Text("截止到 ${item.period} 期已连续出现 ${item.count} 次"),
            trailing: CircularProgressIndicator(
              backgroundColor: Colors.black12,
              value: diff >= 1200 ? 0.0 : 1.0 - diff / 1200, // 进度显示100%为20分钟
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: RefreshIndicator(
          // 刷新函数
          onRefresh: _handleRefresh,
          color: Colors.green,
          child: buildListView(context),
        ),
      ),
    );
  }
}
