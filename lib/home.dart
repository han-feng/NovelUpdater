import 'package:flutter/material.dart';
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

  @override
  void initState() {
    // 初始化，当前widget被插入到树中时调用
    super.initState();
    repository = Repository(context);
    suggestions = repository.suggestions;
  }

  Future<void> _handleRefresh() async {
    setState(() {
      repository.refresh();
    });
  }

  Widget buildListView(BuildContext context) {
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        Suggestion item = suggestions[index];
        Icon icon;
        Text title;
        if (item.recommended) {
          icon = Icon(Icons.grade,
              size: 32, color: Colors.red, semanticLabel: "推荐");
          title = Text(
              "推荐参与 ${item.numbers} ${repository.provinces[item.province].name}");
        } else {
          icon = Icon(Icons.block, size: 32, semanticLabel: "不推荐");
          title = Text(
              "${item.numbers} ${repository.provinces[item.province].name}");
        }
        return ListTile(
          leading: icon,
          title: title,
          subtitle: Text("截止到 ${item.period} 期已连续出现 ${item.count} 次"),
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
