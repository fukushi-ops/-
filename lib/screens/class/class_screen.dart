import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repository/lesson_repository.dart';
import '../../data/repository/subject_repository.dart';
import '../../services/home_widget_service.dart';
import '../../widgets/subject_dropdown_field.dart';
import 'lesson_data.dart';
import '../../widgets/active_term_action.dart';
import 'timetable_import_review_screen.dart';
import 'timetable_ocr_service.dart';

class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key, required this.onTermSelected});

  final Future<void> Function(int termId) onTermSelected;

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  static const _days = ["月", "火", "水", "木", "金", "土", "日"];
  String selectedDay = "月";
  final Map<String, int> _visiblePeriodCounts = {};

  int get _visiblePeriodCount {
    final lessons = LessonData.lessonsByDay[selectedDay]!;
    final savedMax = lessons.fold<int>(
      0,
      (max, lesson) => lesson.periodNumber > max ? lesson.periodNumber : max,
    );
    final visibleCount = _visiblePeriodCounts[selectedDay] ?? 0;
    return savedMax > visibleCount ? savedMax : visibleCount;
  }

  void _addPeriodBox() {
    setState(() {
      _visiblePeriodCounts[selectedDay] = _visiblePeriodCount + 1;
    });
  }

  Future<void> _importTimetable() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    try {
      final recognized = await TimetableOcrService.recognize(image.path);
      if (!mounted) return;
      final lessons = await Navigator.push<List<LessonImport>>(
        context,
        MaterialPageRoute(
          builder: (_) => TimetableImportReviewScreen(lessons: recognized),
        ),
      );
      if (lessons == null || lessons.isEmpty || !mounted) return;

      await SubjectRepository.ensureRegistered(
        termId: LessonRepository.activeTermId,
        names: lessons.map((item) => item.lesson.name),
      );
      final saved = await LessonRepository.addLessons(
        termId: LessonRepository.activeTermId,
        lessons: lessons,
      );
      if (!mounted) return;
      setState(() {
        for (final item in saved) {
          LessonData.lessonsByDay[item.weekday]!.add(item.lesson);
        }
      });
      HomeWidgetService.refreshInBackground();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${saved.length}件の授業を時間割に追加しました')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('時間割の画像取り込みに失敗しました: $error')));
    }
  }

  Future<void> _editLesson(Lesson lesson) {
    return _showLessonDialog(lesson.periodNumber, lesson: lesson);
  }

  void _replaceLessons(String weekday, List<Lesson> replacements) {
    final lessons = LessonData.lessonsByDay[weekday]!;
    for (final replacement in replacements) {
      final lessonIndex = lessons.indexWhere(
        (lesson) =>
            replacement.lessonId != null &&
            lesson.lessonId == replacement.lessonId,
      );
      if (lessonIndex != -1) {
        lessons[lessonIndex] = replacement;
      }
    }
  }

  Future<void> _reorderPeriods({
    required int oldIndex,
    required int newIndex,
    required List<Lesson?> periods,
  }) async {
    if (oldIndex == newIndex) return;

    final weekday = selectedDay;
    final reorderedPeriods = List<Lesson?>.of(periods);
    final movedPeriod = reorderedPeriods.removeAt(oldIndex);
    reorderedPeriods.insert(newIndex, movedPeriod);

    final updatedLessons = <Lesson>[];
    for (var index = 0; index < reorderedPeriods.length; index++) {
      final lesson = reorderedPeriods[index];
      if (lesson == null) continue;

      updatedLessons.add(
        Lesson(
          name: lesson.name,
          room: lesson.room,
          periodNumber: index + 1,
          courseId: lesson.courseId,
          lessonId: lesson.lessonId,
        ),
      );
    }

    final originalLessons = List<Lesson>.of(LessonData.lessonsByDay[weekday]!);
    setState(() {
      _replaceLessons(weekday, updatedLessons);
    });

    try {
      await LessonRepository.updateLessonPeriods(
        weekday: weekday,
        lessons: updatedLessons,
      );
      if (!mounted) return;

      HomeWidgetService.refreshInBackground();
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _replaceLessons(weekday, originalLessons);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('授業の順序変更に失敗しました: $error')));
    }
  }

  Future<void> _deleteEmptyPeriod({
    required int periodNumber,
    required List<Lesson?> periods,
  }) async {
    final weekday = selectedDay;
    final previousCount = _visiblePeriodCount;
    final remainingPeriods = List<Lesson?>.of(periods)
      ..removeAt(periodNumber - 1);
    final updatedLessons = <Lesson>[];

    for (var index = 0; index < remainingPeriods.length; index++) {
      final lesson = remainingPeriods[index];
      if (lesson == null) continue;

      updatedLessons.add(
        Lesson(
          name: lesson.name,
          room: lesson.room,
          periodNumber: index + 1,
          courseId: lesson.courseId,
          lessonId: lesson.lessonId,
        ),
      );
    }

    final originalLessons = List<Lesson>.of(LessonData.lessonsByDay[weekday]!);
    setState(() {
      _visiblePeriodCounts[weekday] = previousCount - 1;
      _replaceLessons(weekday, updatedLessons);
    });

    try {
      await LessonRepository.updateLessonPeriods(
        weekday: weekday,
        lessons: updatedLessons,
      );
      if (!mounted) return;

      HomeWidgetService.refreshInBackground();
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _visiblePeriodCounts[weekday] = previousCount;
        _replaceLessons(weekday, originalLessons);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('空欄の限目を削除できませんでした: $error')));
    }
  }

  Future<void> _showLessonDialog(int periodNumber, {Lesson? lesson}) async {
    final result = await showDialog<Lesson>(
      context: context,
      builder: (_) =>
          _EditLessonDialog(periodNumber: periodNumber, lesson: lesson),
    );

    if (result == null) return;

    try {
      if (lesson == null) {
        final saved = await LessonRepository.addLesson(
          termId: LessonRepository.activeTermId,
          weekday: selectedDay,
          lesson: result,
        );

        if (!mounted) return;
        setState(() {
          LessonData.lessonsByDay[selectedDay]!.add(saved);
        });
      } else {
        await LessonRepository.updateLesson(
          weekday: selectedDay,
          lesson: result,
        );

        if (!mounted) return;
        setState(() {
          final lessons = LessonData.lessonsByDay[selectedDay]!;
          final lessonIndex = lessons.indexOf(lesson);
          if (lessonIndex != -1) {
            lessons[lessonIndex] = result;
          }
        });
      }

      HomeWidgetService.refreshInBackground();
    } on Exception catch (error) {
      if (!mounted) return;
      final action = lesson == null ? '登録' : '更新';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('授業の$actionに失敗しました: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessons = LessonData.lessonsByDay[selectedDay]!;
    final sortedLessons = List.of(lessons)
      ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));
    final lessonByPeriod = {
      for (final lesson in sortedLessons) lesson.periodNumber: lesson,
    };
    final visiblePeriodCount = _visiblePeriodCount;
    final periods = List<Lesson?>.generate(
      visiblePeriodCount,
      (index) => lessonByPeriod[index + 1],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('授業一覧'),
        centerTitle: true,
        actions: [
          ActiveTermAction(onTermSelected: widget.onTermSelected),
          if (Platform.isAndroid)
            IconButton(
              onPressed: _importTimetable,
              tooltip: '画像から時間割を取り込む',
              icon: const Icon(Icons.image_search_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = _days[index];
                return ChoiceChip(
                  label: Text('$day曜日'),
                  selected: selectedDay == day,
                  onSelected: (_) {
                    setState(() {
                      selectedDay = day;
                    });
                  },
                );
              },
            ),
          ),
          Expanded(
            child: visiblePeriodCount == 0
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$selectedDay曜日の授業はありません',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text('＋ボタンから授業を登録できます'),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: visiblePeriodCount,
                    buildDefaultDragHandles: false,
                    onReorderItem: (oldIndex, newIndex) => _reorderPeriods(
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                      periods: periods,
                    ),
                    itemBuilder: (context, index) {
                      final periodNumber = index + 1;
                      final lesson = periods[index];
                      if (lesson == null) {
                        return Dismissible(
                          key: ValueKey('empty-period-$periodNumber'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _deleteEmptyPeriod(
                            periodNumber: periodNumber,
                            periods: periods,
                          ),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 60,
                                child: Text(
                                  '$periodNumber\n限目',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              title: const Text('授業を登録'),
                              trailing: ReorderableDragStartListener(
                                index: index,
                                child: const Tooltip(
                                  message: 'ドラッグして順序を変更',
                                  child: Icon(Icons.drag_handle),
                                ),
                              ),
                              onTap: () => _showLessonDialog(periodNumber),
                            ),
                          ),
                        );
                      }

                      return Dismissible(
                        key: ObjectKey(lesson),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) async {
                          final index = lessons.indexOf(lesson);
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          setState(() {
                            _visiblePeriodCounts[selectedDay] =
                                _visiblePeriodCount;
                            lessons.remove(lesson);
                          });

                          try {
                            await LessonRepository.deleteLesson(lesson: lesson);
                            HomeWidgetService.refreshInBackground();
                          } on Exception catch (error) {
                            if (!mounted) return;

                            setState(() {
                              lessons.insert(
                                index.clamp(0, lessons.length).toInt(),
                                lesson,
                              );
                            });
                            messenger?.showSnackBar(
                              SnackBar(content: Text('授業の削除に失敗しました: $error')),
                            );
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: CircleAvatar(
                              radius: 60,
                              child: Text(
                                '$periodNumber\n限目',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            title: Text(
                              lesson.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _LessonDetail(
                                    icon: Icons.meeting_room_outlined,
                                    text: '${lesson.room}教室',
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                            trailing: ReorderableDragStartListener(
                              index: index,
                              child: const Tooltip(
                                message: 'ドラッグして順序を変更',
                                child: Icon(Icons.drag_handle),
                              ),
                            ),
                            onTap: () => _editLesson(lesson),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addLessonFab',
        onPressed: _addPeriodBox,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LessonDetail extends StatelessWidget {
  const _LessonDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 6),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _EditLessonDialog extends StatefulWidget {
  const _EditLessonDialog({required this.periodNumber, this.lesson});

  final int periodNumber;
  final Lesson? lesson;

  @override
  State<_EditLessonDialog> createState() => _EditLessonDialogState();
}

class _EditLessonDialogState extends State<_EditLessonDialog> {
  late String? _selectedSubject = widget.lesson?.name;
  late final TextEditingController _roomController = TextEditingController(
    text: widget.lesson?.room ?? '',
  );

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.periodNumber}限目を編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SubjectDropdownField(
              termId: LessonRepository.activeTermId,
              initialValue: _selectedSubject,
              onChanged: (subject) {
                setState(() {
                  _selectedSubject = subject;
                });
              },
            ),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(labelText: '教室'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            final subject = _selectedSubject;
            if (subject == null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('科目を選択してください')));
              return;
            }

            Navigator.pop(
              context,
              Lesson(
                name: subject,
                room: _roomController.text.trim(),
                periodNumber: widget.periodNumber,
                courseId: widget.lesson?.courseId,
                lessonId: widget.lesson?.lessonId,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
