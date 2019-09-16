import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';

class DBUtil {
  static Future<String> loadConfig(BuildContext context) async {
    return await DefaultAssetBundle.of(context).loadString('assets/config.json');
  }

  loadData() {}

  saveData() {}

  updateData() {}
}
