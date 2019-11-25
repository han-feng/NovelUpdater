import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_updater/main.dart';
import 'package:novel_updater/Repository.dart';
import 'package:novel_updater/Item.dart';

void main() {
  test("Repository功能测试", () async {
    Repository repository = Repository(null, () {
      print("onchanged!");
    });
    await repository.refresh();
    print(repository.onlineCached);
  });
}
