# `lib` 内のファイル案内

このファイルは、アプリのソースファイルが何を担当しているかをまとめた案内です。

## 起動と設定

| ファイル | 役割 |
|---|---|
| [`main.dart`](main.dart) | アプリの起動処理。保存済みの学年・学期を復元し、授業・課題・科目を読み込んでホーム画面を表示する。 |

## 画面

| ファイル | 役割 |
|---|---|
| [`screens/home_screen.dart`](screens/home_screen.dart) | ホーム画面。今日の情報と「科目→時間割→課題」の登録案内を表示する。 |
| [`screens/class/class_screen.dart`](screens/class/class_screen.dart) | 曜日ごとの授業一覧を表示し、授業の編集・削除や画像取り込みにつなぐ。 |
| [`screens/term/term_management_screen.dart`](screens/term/term_management_screen.dart) | 任意の学年・学期名を作成・切り替え、既存データを新しい期間へ移すか選択する。 |
| [`screens/class/add_class_screen.dart`](screens/class/add_class_screen.dart) | 登録済み科目を選び、先生・教室・時間を入力して授業を追加する。 |
| [`screens/class/edit_class_screen.dart`](screens/class/edit_class_screen.dart) | 登録済み科目から選び、授業情報を編集する。 |
| [`screens/task/assignment_screen.dart`](screens/task/assignment_screen.dart) | 課題一覧を表示し、未提出・提出済みの絞り込み、提出状態の変更、削除を行う。提出済みにしたときは、成果物・振り返りの登録を課題詳細から行うよう案内する。 |
| [`screens/task/add_assignment_screen.dart`](screens/task/add_assignment_screen.dart) | 課題名・登録済み科目・締切と、課題ごとの締切通知設定を指定して課題を追加する。 |
| [`screens/task/edit_assignument_screen.dart`](screens/task/edit_assignument_screen.dart) | 課題情報と、課題ごとの締切通知設定を編集する。 |
| [`screens/task/task_deadline_notification_form.dart`](screens/task/task_deadline_notification_form.dart) | 1日前・3日前・カスタム日数、繰り返し頻度、通知時刻を設定する共通フォーム。 |
| [`screens/task/learning_history_screen.dart`](screens/task/learning_history_screen.dart) | 課題の統計、自己評価の推移、科目別集計を表示する。個別の課題一覧は表示しない。 |
| [`screens/subject/subject_registration_screen.dart`](screens/subject/subject_registration_screen.dart) | 科目を登録し、登録済みの科目一覧を表示する。 |
| [`screens/sub/attendance_screen.dart`](screens/sub/attendance_screen.dart) | 日付ごと・授業ごとに出席、欠席、遅刻、公欠を記録する画面。 |
| [`screens/karender/calender_screen.dart`](screens/karender/calender_screen.dart) | カレンダー画面。予定を表示し、予定追加画面を開く。 |
| [`screens/karender/add_schedule_screen.dart`](screens/karender/add_schedule_screen.dart) | 予定名・開始日・終了日・色を指定して、カレンダーに予定を追加する画面。 |
| [`screens/sub/attendance_screen.dart`](screens/sub/attendance_screen.dart) | メモ用の簡易画面 `MemoScreen` も定義されている（既存の下部メニュー用）。 |
| [`screens/sub/class_otherscreen.dart`](screens/sub/class_otherscreen.dart) | その他画面。現在は「その他画面」という案内を表示する簡易画面。 |

## データと保存

| ファイル | 役割 |
|---|---|
| [`data/repository/subject_repository.dart`](data/repository/subject_repository.dart) | 科目の保存・読み込みと、既存の授業・課題からの科目一覧の補完を行う。 |
| [`data/repository/lesson_repository.dart`](data/repository/lesson_repository.dart) | 期間の作成・選択と、期間ごとの授業の保存・読み込みを行う。 |
| [`widgets/subject_dropdown_field.dart`](widgets/subject_dropdown_field.dart) | 授業・課題フォームで登録済み科目を選択する共通フィールド。 |
| [`screens/lesson_data.dart`](screens/lesson_data.dart) | 授業データの形式（`Lesson`）、曜日ごとの授業リスト、および `SharedPreferences` への保存・読み込みを定義する。 |
| [`screens/task_data.dart`](screens/task_data.dart) | 課題データの形式（`Task`）と課題リストを定義する。締切通知の日数と繰り返し頻度も課題ごとに保持する。 |
| [`data/repository/task_repository.dart`](data/repository/task_repository.dart) | Isarへの課題の保存・読み込み・更新・削除を行う。 |
| [`services/simple_notification_service.dart`](services/simple_notification_service.dart) | Androidの課題締切通知を設定・解除する。通知日は課題ごとの設定に従い、設定した時刻に通知する。 |
| [`screens/sub/attendance_data.dart`](screens/sub/attendance_data.dart) | 授業ごとの出席状況と `SharedPreferences` への保存・読み込みを定義する。出席率は「出席 ÷（出席・欠席・遅刻の記録数）」で計算し、公欠は分母から除外する。 |
| [`screens/karender/schedule.dart`](screens/karender/schedule.dart) | カレンダー予定のデータ形式（予定名、開始日、終了日、色）を定義する。 |

## おおまかなデータの流れ

- アプリ起動時に [`main.dart`](main.dart) が授業と課題を読み込む。
- 学年・学期は [`data/repository/lesson_repository.dart`](data/repository/lesson_repository.dart) で保存・復元し、切り替え時に時間割・科目・課題をまとめて読み直す。
- 既存データの科目名は起動時に科目一覧へ引き継がれ、新しい科目は科目登録画面から追加する。
- ホーム画面から「科目登録→時間割→課題」の順で各登録画面へ移動できる。
- 授業・課題の登録や編集では、共通の科目選択フィールドから登録済み科目を選ぶ。
- 授業の表示・追加・編集には、授業画面と [`screens/lesson_data.dart`](screens/lesson_data.dart) を使う。
- 課題の表示・追加・提出状態変更には、課題画面と [`screens/task_data.dart`](screens/task_data.dart) を使う。
- 課題一覧と分析画面は同じ `TaskData.tasks` を参照し、課題削除時は変更通知で分析内容も更新する。
- 出席状況の入力には [`screens/sub/attendance_screen.dart`](screens/sub/attendance_screen.dart)、記録の保存には [`screens/sub/attendance_data.dart`](screens/sub/attendance_data.dart) を使う。
- ホーム画面は読み込み済みの授業・課題データを参照して表示する。
- カレンダーの予定は、現状では画面内のリストで管理されており、授業・課題のような永続保存処理はこのファイル群にはない。

## ファイルを探すときの目安

- 画面の見た目やボタンの動きを変える：該当する `*_screen.dart`
- 保存する項目や読み書き方法を変える：対応する `*_data.dart` または `schedule.dart`
- アプリ起動時の処理や最初の画面を変える：`main.dart`
