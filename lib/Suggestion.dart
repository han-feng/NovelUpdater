class Suggestion {
  String province; // 省份
  String period; // 期次
  List<int> numbers; // 数字组合
  int count; // 连续出现次数

  Suggestion(this.province, this.period, this.numbers, this.count);

  bool get recommended {
    return (count >= 14 && count <= 21);
  }

  String toString() {
    return "$province-$period: $numbers [$count]";
  }
}
