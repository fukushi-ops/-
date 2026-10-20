# `lib` 内のファイル案内

このファイルは、アプリのソースファイルが何を担当しているかをまとめた案内です。

## 起動と設定

| ファイル | 役割 |
|---|---|
| [`main.dart`](main.dart) | アプリの起動処理。授業・課題データを読み込んでから、最初に表示するホーム画面を設定する。 |
| [`firebase_options.dart`](firebase_options.dart) | FlutterFire CLI が生成した Firebase のプラットフォーム別設定。 |

## 画面

| ファイル | 役割 |
|---|---|
| [`screens/home_screen.dart`](screens/home_screen.dart) | ホーム画面。今日の授業、今日が締切の課題、今週の課題の進捗、出席率などを表示し、他の画面へ移動する。 |
| [`screens/class_screen.dart`](screens/class_screen.dart) | 曜日ごとの授業一覧を表示し、授業の編集・削除へつなぐ。 |
| [`screens/add_class_screen.dart`](screens/add_class_screen.dart) | 授業名・先生・教室・時間を入力して、新しい授業を追加する画面。 |
| [`screens/edit_class_screen.dart`](screens/edit_class_screen.dart) | 登録済みの授業情報を編集する画面。 |
| [`screens/assignment_screen.dart`](screens/assignment_screen.dart) | 課題一覧を表示し、未提出・提出済みの絞り込み、提出状態の変更、削除を行う。 |
| [`screens/add_assignment_screen.dart`](screens/add_assignment_screen.dart) | 課題名・科目名・締切を入力して、新しい課題を追加する画面。 |
| [`screens/sub/attendance_screen.dart`](screens/sub/attendance_screen.dart) | 日付ごと・授業ごとに出席、欠席、遅刻、公欠を記録する画面。 |
| [`screens/karender/calender_screen.dart`](screens/karender/calender_screen.dart) | カレンダー画面。予定を表示し、予定追加画面を開く。 |
| [`screens/karender/add_schedule_screen.dart`](screens/karender/add_schedule_screen.dart) | 予定名・開始日・終了日・色を指定して、カレンダーに予定を追加する画面。 |
| [`screens/sub/attendance_screen.dart`](screens/sub/attendance_screen.dart) | メモ用の簡易画面 `MemoScreen` も定義されている（既存の下部メニュー用）。 |
| [`screens/sub/class_otherscreen.dart`](screens/sub/class_otherscreen.dart) | その他画面。現在は「その他画面」という案内を表示する簡易画面。 |

## データと保存

| ファイル | 役割 |
|---|---|
| [`screens/lesson_data.dart`](screens/lesson_data.dart) | 授業データの形式（`Lesson`）、曜日ごとの授業リスト、および `SharedPreferences` への保存・読み込みを定義する。 |
| [`screens/task_data.dart`](screens/task_data.dart) | 課題データの形式（`Task`）、課題リスト、および `SharedPreferences` への保存・読み込みを定義する。 |
| [`screens/sub/attendance_data.dart`](screens/sub/attendance_data.dart) | 授業ごとの出席状況と `SharedPreferences` への保存・読み込みを定義する。 |
| [`screens/karender/schedule.dart`](screens/karender/schedule.dart) | カレンダー予定のデータ形式（予定名、開始日、終了日、色）を定義する。 |

## おおまかなデータの流れ

- アプリ起動時に [`main.dart`](main.dart) が授業と課題を読み込む。
- 授業の表示・追加・編集には、授業画面と [`screens/lesson_data.dart`](screens/lesson_data.dart) を使う。
- 課題の表示・追加・提出状態変更には、課題画面と [`screens/task_data.dart`](screens/task_data.dart) を使う。
- 出席状況の入力には [`screens/sub/attendance_screen.dart`](screens/sub/attendance_screen.dart)、記録の保存には [`screens/sub/attendance_data.dart`](screens/sub/attendance_data.dart) を使う。
- ホーム画面は読み込み済みの授業・課題データを参照して表示する。
- カレンダーの予定は、現状では画面内のリストで管理されており、授業・課題のような永続保存処理はこのファイル群にはない。

## ファイルを探すときの目安

- 画面の見た目やボタンの動きを変える：該当する `*_screen.dart`
- 保存する項目や読み書き方法を変える：対応する `*_data.dart` または `schedule.dart`
- アプリ起動時の処理や最初の画面を変える：`main.dart`
