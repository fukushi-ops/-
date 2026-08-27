import 'package:flutter/material.dart';
import 'add_class_screen.dart';

class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key});

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  // 授業を保存するリスト
  List<String> classList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('授業一覧')),

      // 保存した授業を表示
      body: ListView.builder(
        itemCount: classList.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(classList[index]));
        },
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),

        onPressed: () async {
          // 授業追加画面へ移動
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClassScreen()),
          );

          // 入力された授業名を保存
          if (result != null && result != '') {
            setState(() {
              classList.add(result);
            });
          }
        },
      ),
    );
  }
}
