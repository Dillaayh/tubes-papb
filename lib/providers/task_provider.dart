// // lib/providers/task_provider.dart
// import 'package:flutter/material.dart';
// import 'package:drift/drift.dart' as drift;
// import '../models/task.dart' as models;
// import '../database/app_database.dart';  // ✅ Ubah dari data/local ke database
//
// class TaskProvider extends ChangeNotifier {
//   final AppDatabase _database;
//
//   List<models.Task> _tasks = [];
//   bool _isLoading = false;
//   String? _errorMessage;
//
//   TaskProvider(this._database) {
//     _initializeData();
//   }
//
//   // Getters
//   List<models.Task> get tasks => _tasks;
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//
//   List<models.Task> get completedTasks =>
//       _tasks.where((task) => task.isCompleted).toList();
//
//   List<models.Task> get incompleteTasks =>
//       _tasks.where((task) => !task.isCompleted).toList();
//
//   // ==================== INITIALIZATION ====================
//
//   Future<void> _initializeData() async {
//     try {
//       _setLoading(true);
//       await loadAllTasks();
//       _setLoading(false);
//     } catch (e) {
//       _setError('Error initializing data: $e');
//       _setLoading(false);
//     }
//   }
//
//   Future<void> loadAllTasks() async {
//     try {
//       _setLoading(true);
//
//       final dbTasks = await _database.taskDao.getAll();
//
//       _tasks = await Future.wait(
//         dbTasks.map((dbTask) async {
//           final taskList = await _database.taskListDao.getById(dbTask.taskListId);
//
//           return models.Task(
//             id: dbTask.id.toString(),
//             title: dbTask.title,
//             description: dbTask.description ?? '',
//             category: taskList?.name ?? 'Uncategorized',
//             isCompleted: dbTask.isCompleted,
//             dueDate: dbTask.dueDate,
//             priority: dbTask.priority,
//             createdAt: dbTask.createdAt,
//             completedAt: dbTask.completedAt,
//             updatedAt: dbTask.updatedAt,
//           );
//         }).toList(),
//       );
//
//       _clearError();
//       _setLoading(false);
//       notifyListeners();
//     } catch (e) {
//       _setError('Error loading tasks: $e');
//       _setLoading(false);
//     }
//   }
//
//   // ==================== GET OPERATIONS ====================
//
//   List<models.Task> getTasksByCategory(String category) {
//     return _tasks.where((task) => task.category == category).toList();
//   }
//
//   models.Task? getTaskById(String id) {
//     try {
//       return _tasks.firstWhere((task) => task.id == id);
//     } catch (e) {
//       return null;
//     }
//   }
//
//   int getCountByCategory(String category) {
//     return _tasks.where((task) => task.category == category).length;
//   }
//
//   int getIncompleteCountByCategory(String category) {
//     return _tasks
//         .where((task) => task.category == category && !task.isCompleted)
//         .length;
//   }
//
//   int get totalTasksCount => _tasks.length;
//   int get completedTasksCount => completedTasks.length;
//   int get incompleteTasksCount => incompleteTasks.length;
//
//   // ==================== ADD OPERATION ====================
//
//   Future<bool> addTask(models.Task task) async {
//     try {
//       _setLoading(true);
//
//       if (task.title.trim().isEmpty) {
//         _setError('Judul tugas tidak boleh kosong');
//         _setLoading(false);
//         return false;
//       }
//
//       final taskLists = await _database.taskListDao.getAll();
//       final taskList = taskLists.firstWhere(
//             (list) => list.name.toLowerCase() == task.category.toLowerCase(),
//         orElse: () => taskLists.first,
//       );
//
//       final trimmedDescription = task.description.trim();
//       final String? descriptionValue =
//       trimmedDescription.isEmpty ? null : trimmedDescription;
//
//       final taskId = await _database.taskDao.insertOne(
//         TasksCompanion.insert(
//           title: task.title.trim(),
//           description: drift.Value(descriptionValue),
//           taskListId: taskList.id,
//           isCompleted: drift.Value(task.isCompleted),
//           priority: drift.Value(task.priority),
//           dueDate: drift.Value(task.dueDate),
//         ),
//       );
//
//       if (taskId > 0) {
//         await loadAllTasks();
//         _clearError();
//         return true;
//       }
//
//       _setError('Gagal menambah tugas');
//       _setLoading(false);
//       return false;
//     } catch (e) {
//       _setError('Error adding task: $e');
//       _setLoading(false);
//       return false;
//     }
//   }
//
//   // ==================== UPDATE OPERATION ====================
//
//   Future<bool> updateTask(models.Task updatedTask) async {
//     try {
//       _setLoading(true);
//
//       if (updatedTask.title.trim().isEmpty) {
//         _setError('Judul tugas tidak boleh kosong');
//         _setLoading(false);
//         return false;
//       }
//
//       final taskId = int.tryParse(updatedTask.id);
//       if (taskId == null) {
//         _setError('ID tugas tidak valid');
//         _setLoading(false);
//         return false;
//       }
//
//       final dbTask = await _database.taskDao.getById(taskId);
//       if (dbTask == null) {
//         _setError('Tugas tidak ditemukan');
//         _setLoading(false);
//         return false;
//       }
//
//       final trimmedDescription = updatedTask.description.trim();
//       final String? descriptionValue =
//       trimmedDescription.isEmpty ? null : trimmedDescription;
//
//       await _database.taskDao.patch(
//         taskId,
//         TasksCompanion(
//           title: drift.Value(updatedTask.title.trim()),
//           description: drift.Value(descriptionValue),
//           isCompleted: drift.Value(updatedTask.isCompleted),
//           priority: drift.Value(updatedTask.priority),
//           dueDate: drift.Value(updatedTask.dueDate),
//           completedAt: drift.Value(
//               updatedTask.isCompleted ? DateTime.now() : null
//           ),
//         ),
//       );
//
//       await loadAllTasks();
//       _clearError();
//       return true;
//     } catch (e) {
//       _setError('Error updating task: $e');
//       _setLoading(false);
//       return false;
//     }
//   }
//
//   // ==================== DELETE OPERATION ====================
//
//   Future<bool> deleteTask(String id) async {
//     try {
//       _setLoading(true);
//
//       final taskId = int.tryParse(id);
//       if (taskId == null) {
//         _setError('ID tugas tidak valid');
//         _setLoading(false);
//         return false;
//       }
//
//       final result = await _database.taskDao.deleteById(taskId);
//
//       if (result > 0) {
//         await loadAllTasks();
//         _clearError();
//         return true;
//       }
//
//       _setError('Gagal menghapus tugas');
//       _setLoading(false);
//       return false;
//     } catch (e) {
//       _setError('Error deleting task: $e');
//       _setLoading(false);
//       return false;
//     }
//   }
//
//   // ==================== TOGGLE OPERATION ====================
//
//   Future<bool> toggleComplete(String id) async {
//     try {
//       _setLoading(true);
//
//       final taskId = int.tryParse(id);
//       if (taskId == null) {
//         _setError('ID tugas tidak valid');
//         _setLoading(false);
//         return false;
//       }
//
//       await _database.taskDao.toggleComplete(taskId);
//
//       await loadAllTasks();
//       _clearError();
//       return true;
//     } catch (e) {
//       _setError('Error toggling task: $e');
//       _setLoading(false);
//       return false;
//     }
//   }
//
//   // ==================== ADDITIONAL OPERATIONS ====================
//
//   Future<List<models.Task>> searchTasks(String query) async {
//     try {
//       if (query.trim().isEmpty) {
//         return [];
//       }
//
//       return _tasks.where((task) {
//         final lowerQuery = query.toLowerCase();
//         return task.title.toLowerCase().contains(lowerQuery) ||
//             task.description.toLowerCase().contains(lowerQuery);
//       }).toList();
//     } catch (e) {
//       _setError('Error searching tasks: $e');
//       return [];
//     }
//   }
//
//   Future<bool> deleteCompletedTasksByCategory(String category) async {
//     try {
//       _setLoading(true);
//
//       final taskLists = await _database.taskListDao.getAll();
//       final taskList = taskLists.firstWhere(
//             (list) => list.name.toLowerCase() == category.toLowerCase(),
//         orElse: () => throw Exception('Category not found'),
//       );
//
//       final result = await _database.taskDao.deleteCompletedInList(taskList.id);
//
//       if (result >= 0) {
//         await loadAllTasks();
//         _clearError();
//         return true;
//       }
//
//       _setError('Gagal menghapus tugas selesai');
//       _setLoading(false);
//       return false;
//     } catch (e) {
//       _setError('Error deleting completed tasks: $e');
//       _setLoading(false);
//       return false;
//     }
//   }
//
//   Future<void> refresh() async {
//     await loadAllTasks();
//   }
//
//   // ==================== HELPER METHODS ====================
//
//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }
//
//   void _setError(String message) {
//     _errorMessage = message;
//     debugPrint('TaskProvider Error: $message');
//     notifyListeners();
//   }
//
//   void _clearError() {
//     _errorMessage = null;
//   }
//
//   @override
//   void dispose() {
//     _database.close();
//     super.dispose();
//   }
// }
