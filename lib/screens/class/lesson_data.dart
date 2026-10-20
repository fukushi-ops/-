import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Lesson {
  String name; // 授業名
  String teacher; // 先生
  String room; // 教室
  String time; // 時間（例：9:00〜10:30）
  int startTime; // 900 のように数値化した時間

  Lesson({
    required this.name,
    required this.teacher,
    required this.room,
    required this.time,
    required this.startTime,
  });

  // ★ JSON に変換
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "teacher": teacher,
      "room": room,
      "time": time,
      "startTime": startTime,
    };
  }

  // ★ JSON から復元
  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      name: json["name"],
      teacher: json["teacher"],
      room: json["room"],
      time: json["time"],
      startTime: json["startTime"],
    );
  }
}

class LessonData {
  static Map<String, List<Lesson>> lessonsByDay = {
    "月": [],
    "火": [],
    "水": [],
    "木": [],
    "金": [],
    "土": [],
    "日": [],
  };
}

class LessonStorage {
  static const String key = "lesson_data";

  // ★ 保存
  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    // Map<String, List<Lesson>> → Map<String, List<Map>>
    final jsonMap = LessonData.lessonsByDay.map((day, list) {
      return MapEntry(day, list.map((l) => l.toJson()).toList());
    });

    prefs.setString(key, jsonEncode(jsonMap));
  }

  // ★ 読み込み（完全修正版）
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);

    if (jsonString == null) return;

    final decoded = jsonDecode(jsonString);

    // ★ decoded は Map<String, dynamic>
    decoded.forEach((day, list) {
      LessonData.lessonsByDay[day] = (list as List)
          .map((item) => Lesson.fromJson(item))
          .toList();
    });
  }
}
