import 'package:flutter/material.dart';
import 'add_assignment_screen.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  // 現在選択されているタブ
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 左上：戻るボタン
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        // 中央：タイトル
        title: const Text(
          '課題一覧',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        centerTitle: true,

        // 右上：＋ボタン
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAssignmentScreen()),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 8),

          // 「すべて・未提出・提出済み」
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton('すべて', 0),
              _buildTabButton('未提出', 1),
              _buildTabButton('提出済み', 2),
            ],
          ),

          // 課題一覧
          const Expanded(
            child: Center(
              child: Text('課題はありません', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),

      // 右下：黒い＋ボタン
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAssignmentScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // タブボタンを作る
  Widget _buildTabButton(String text, int index) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        width: 80,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan : Colors.white,
          border: Border.all(color: Colors.blue),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
