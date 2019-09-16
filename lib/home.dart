import 'package:flutter/material.dart';
import 'spider.dart' as spider;
import 'db.dart';

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
  String _text = "";
  AnimationController controller; //动画控制器

  @override
  void initState() {
    //初始化，当当前widget被插入到树中时调用
    super.initState();
    repository = new Repository(context);
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5));
//    controller.forward(); //放在这里开启动画 ，打开页面就播放动画
  }

  void _runSpider() async {
    var data = await spider.html_parse();
    setState(() {
      _text = data; // json.encode({'items':data});
    });
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
        child: Card(
          child: ListTile(
            leading: Icon(Icons.grade, size: 48, color: Colors.yellow),
            title: Text('推荐参与【2、5、8】山东'),
            subtitle: Text('截止到 2019010101 期已连续出现 20 次'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _runSpider,
        tooltip: '更新',
        child: RotationTransition(
          //旋转动画
          alignment: Alignment.center,
          turns: controller,
          child: Icon(Icons.autorenew),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
