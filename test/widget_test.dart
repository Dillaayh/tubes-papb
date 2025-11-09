// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide isNull; // ✅ PERBAIKAN DI SINI
import 'package:provider/provider.dart';
import 'package:wuunderlist/main.dart';
import 'package:wuunderlist/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

// Helper untuk membuat AppDatabase dalam memori untuk testing
AppDatabase _constructDb({bool logStatements = false}) {
  return AppDatabase.forTesting(
    NativeDatabase.memory(logStatements: logStatements),
  );
}

void main() {
  late AppDatabase database;

  // Atur database sebelum setiap test
  setUp(() {
    database = _constructDb();
  });

  // Tutup database setelah setiap test
  tearDown(() async {
    await database.close();
  });

  // Wrapper untuk menyediakan database ke widget yang di-test
  Widget createApp() {
    return Provider<AppDatabase>.value(
      value: database,
      child: const MyApp(),
    );
  }

  group('Wunderlist App Tests', () {
    testWidgets('App should launch without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createApp());
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App should show dashboard screen', (WidgetTester tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Wunderlist'), findsOneWidget);
    });
  });

  group('Database Tests', () {
    test('Can insert and retrieve task lists', () async {
      await database.taskListDao.insertOne(
        TaskListsCompanion.insert(
          name: 'Test List',
          iconName: const Value('test_icon'),
          colorValue: const Value(0xFF000000),
        ),
      );

      final taskLists = await database.taskListDao.watchAll().first;
      expect(taskLists.any((tl) => tl.name == 'Test List'), isTrue);
    });

    test('Can insert and retrieve tasks', () async {
      final taskListId = await database.taskListDao.insertOne(
        TaskListsCompanion.insert(name: 'Test List', colorValue: const Value(0xFF000000)),
      );
      await database.taskDao.insertOne(
        TasksCompanion.insert(
          title: 'Test Task',
          taskListId: taskListId,
        ),
      );

      final tasks = await database.taskDao.watchAll().first;
      expect(tasks.any((t) => t.title == 'Test Task'), isTrue);
    });

    test('Can update a task', () async {
      final taskListId = await database.taskListDao.insertOne(TaskListsCompanion.insert(name: 'List'));
      final taskId = await database.taskDao.insertOne(TasksCompanion.insert(title: 'Original', taskListId: taskListId));

      await database.taskDao.patch(taskId, const TasksCompanion(title: Value('Updated')));

      final updatedTask = await database.taskDao.getById(taskId);
      expect(updatedTask?.title, 'Updated');
    });

    test('Can delete a task', () async {
      final taskListId = await database.taskListDao.insertOne(TaskListsCompanion.insert(name: 'List'));
      final taskId = await database.taskDao.insertOne(TasksCompanion.insert(title: 'To Delete', taskListId: taskListId));

      await database.taskDao.deleteById(taskId);

      final task = await database.taskDao.getById(taskId);
      expect(task, null); // <- Menggunakan null dari Dart, bukan isNull dari matcher
    });

    test('Can toggle task completion', () async {
      final taskListId = await database.taskListDao.insertOne(TaskListsCompanion.insert(name: 'List'));
      final taskId = await database.taskDao.insertOne(TasksCompanion.insert(title: 'To Toggle', taskListId: taskListId));

      var task = await database.taskDao.getById(taskId);
      expect(task?.isCompleted, isFalse);

      await database.taskDao.toggleComplete(taskId);
      task = await database.taskDao.getById(taskId);
      expect(task?.isCompleted, isTrue);

      await database.taskDao.toggleComplete(taskId);
      task = await database.taskDao.getById(taskId);
      expect(task?.isCompleted, isFalse);
    });
  });
}
