// lib/database/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Enum untuk sorting dan filtering
enum SortOption { priority, dueDate, name }
enum FilterOption { all, active, completed }

// Definisi Tabel TaskLists
@DataClassName('TaskList')
class TaskLists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get iconName => text().nullable()();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF6366F1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Definisi Tabel Tasks
@DataClassName('Task')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get description => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get taskListId => integer().references(TaskLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get priority => text().withDefault(const Constant('Medium'))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Kelas Database Utama
@DriftDatabase(tables: [TaskLists, Tasks], daos: [TaskListDao, TaskDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        await m.addColumn(taskLists, taskLists.colorValue);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.wasCreated) {
        await _initializeDefaultCategories();
      }
    },
  );

  // Kategori Default yang Baru
  Future<void> _initializeDefaultCategories() async {
    await transaction(() async {
      await taskListDao.insertMultiple([
        TaskListsCompanion.insert(name: 'Kuliah', iconName: const Value('school'), colorValue: const Value(0xFF6366F1)),
        TaskListsCompanion.insert(name: 'Pekerjaan Rumah', iconName: const Value('home'), colorValue: const Value(0xFF10B981)),
        TaskListsCompanion.insert(name: 'Tugas Harian', iconName: const Value('category'), colorValue: const Value(0xFFF59E0B)),
        TaskListsCompanion.insert(name: 'Olahraga', iconName: const Value('sports_soccer'), colorValue: const Value(0xFFE53935)),
      ]);
    });
  }

  Future<void> clearAllData() => transaction(() async {
    await delete(tasks).go();
    await delete(taskLists).go();
  });
}

// Fungsi untuk membuka koneksi database
LazyDatabase _openConnection() => LazyDatabase(() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'wunderlist.sqlite'));
  return NativeDatabase.createInBackground(file);
});

// Data class untuk join query
class TaskWithList {
  final Task task;
  final TaskList taskList;
  TaskWithList({required this.task, required this.taskList});
}

// DAO untuk TaskLists
@DriftAccessor(tables: [TaskLists])
class TaskListDao extends DatabaseAccessor<AppDatabase> with _$TaskListDaoMixin {
  TaskListDao(super.db);
  Future<int> insertOne(TaskListsCompanion data) => into(taskLists).insert(data);
  Future<void> insertMultiple(List<TaskListsCompanion> data) => batch((batch) => batch.insertAll(taskLists, data));
  Stream<TaskList> watchById(int id) => (select(taskLists)..where((t) => t.id.equals(id))).watchSingle();
  Stream<List<TaskList>> watchAll() => (select(taskLists)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch();
}

// DAO untuk Tasks
@DriftAccessor(tables: [Tasks, TaskLists])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);
  Future<int> insertOne(TasksCompanion data) => into(tasks).insert(data);
  Future<Task?> getById(int id) => (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  Stream<List<Task>> watchAll() => select(tasks).watch();
  Stream<List<Task>> watchByListId(int listId) => (select(tasks)..where((t) => t.taskListId.equals(listId))).watch();
  Future<int> deleteById(int id) => (delete(tasks)..where((t) => t.id.equals(id))).go();

  Stream<TaskWithList> watchByIdWithList(int taskId) {
    final query = select(tasks).join([innerJoin(taskLists, taskLists.id.equalsExp(tasks.taskListId))])..where(tasks.id.equals(taskId));
    return query.watchSingle().map((row) => TaskWithList(task: row.readTable(tasks), taskList: row.readTable(taskLists)));
  }

  Stream<List<TaskWithList>> watchTasksInCategory(int listId, { SortOption sortBy = SortOption.priority, FilterOption filterBy = FilterOption.all }) {
    final query = select(tasks).join([innerJoin(taskLists, taskLists.id.equalsExp(tasks.taskListId))])..where(taskLists.id.equals(listId));
    if (filterBy == FilterOption.active) query.where(tasks.isCompleted.equals(false));
    if (filterBy == FilterOption.completed) query.where(tasks.isCompleted.equals(true));
    switch (sortBy) {
      case SortOption.dueDate: query.orderBy([OrderingTerm.asc(tasks.dueDate)]); break;
      case SortOption.name: query.orderBy([OrderingTerm.asc(tasks.title)]); break;
      default: query.orderBy([OrderingTerm.asc(CustomExpression<int>("CASE priority WHEN 'Urgent' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 WHEN 'Low' THEN 4 ELSE 5 END"))]);
    }
    return query.watch().map((rows) => rows.map((row) => TaskWithList(task: row.readTable(tasks), taskList: row.readTable(taskLists))).toList());
  }

  Future<void> toggleComplete(int taskId) async {
    final task = await getById(taskId);
    if(task == null) return;
    final newStatus = !task.isCompleted;
    await patch(taskId, TasksCompanion(isCompleted: Value(newStatus), completedAt: Value(newStatus ? DateTime.now() : null)));
  }

  Future<int> patch(int id, TasksCompanion data) => (update(tasks)..where((t) => t.id.equals(id))).write(data.copyWith(updatedAt: Value(DateTime.now())));
  Future<int> deleteCompleted() => (delete(tasks)..where((t) => t.isCompleted.equals(true))).go();
  Future<int> countCompleted() async {
    final expression = tasks.id.count(filter: tasks.isCompleted.equals(true));
    final query = selectOnly(tasks)..addColumns([expression]);
    final result = await query.getSingle();
    return result.read(expression) ?? 0;
  }
}
