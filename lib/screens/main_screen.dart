import 'package:flutter/material.dart';

import 'class/class_screen.dart';
import 'class_otherscreen.dart';
import 'home_screen.dart';
import 'task/assignment_screen.dart';
import 'otherscreen/attendance_screen.dart';

class MainScreen extends StatefulWidget {
  final String userName;

  const MainScreen({super.key, required this.userName});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(userName: widget.userName),
      const ClassScreen(),
      const AssignmentScreen(),
      const MemoScreen(),
      const OtherScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '時間割',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: '課題'),
          BottomNavigationBarItem(icon: Icon(Icons.sticky_note_2), label: 'メモ'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: '設定'),
        ],
      ),
    );
  }
}
