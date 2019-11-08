class ProvinceConfig {
  final String name;
  final String url55128;

  String lastNo = '';
  String nextNo = '';
  DateTime nextTime;

  int duration; // 本地与服务器时间差，单位：秒，=本地时间-服务器时间

  ProvinceConfig(this.name, this.url55128);

  ProvinceConfig.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        url55128 = json['55128'];

  Map<String, dynamic> toJson() => {
        'name': name,
        '55128': url55128,
      };

  String toString() {
    return '{name:"$name",55128:"$url55128",lastNo:"$lastNo",'
        'nextNo:"$nextNo",nextTime:"$nextTime",duration:"$duration"}';
  }
}
