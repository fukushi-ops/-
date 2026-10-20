import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/lesson_data.dart';
import 'screens/task_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LessonStorage.load(); // 授業ロード
  await TaskStorage.load(); //  課題ロード

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(userName: '結菜さん'),
    );
  }
}
