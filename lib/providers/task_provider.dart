import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskList> _taskLists = [
    TaskList(
      name: 'Hari Ini',
      icon: Icons.today,
      color: Colors.red,
      tasks: [
        Task('Beli groceries', false),
        Task('Meeting dengan tim', true),
        Task('Review laporan', false),
      ],
    ),
    TaskList(
      name: 'Pekerjaan',
      icon: Icons.work,
      color: Colors.blue,
      tasks: [
        Task('Presentasi proyek', false),
        Task('Email client', true),
        Task('Update dokumentasi', false),
        Task('Code review', false),
      ],
    ),
    TaskList(
      name: 'Pribadi',
      icon: Icons.person,
      color: Colors.green,
      tasks: [
        Task('Olahraga pagi', true),
        Task('Baca buku', false),
        Task('Call keluarga', false),
      ],
    ),
    TaskList(
      name: 'Belanja',
      icon: Icons.shopping_cart,
      color: Colors.orange,
      tasks: [
        Task('Susu', false),
        Task('Roti', false),
        Task('Sayuran', true),
        Task('Buah-buahan', false),
      ],
    ),
  ];

  List<TaskList> get taskLists => _taskLists;

  // Get all tasks from all lists
  List<Task> get allTasks {
    List<Task> tasks = [];
    for (var list in _taskLists) {
      tasks.addAll(list.tasks);
    }
    return tasks;
  }

  // Statistics
  int get totalTasks {
    return _taskLists.fold(0, (sum, list) => sum + list.tasks.length);
  }

  int get completedTasks {
    return _taskLists.fold(
      0,
          (sum, list) => sum + list.tasks.where((task) => task.isCompleted).length,
    );
  }

  int get incompleteTasks {
    return _taskLists.fold(
      0,
          (sum, list) => sum + list.tasks.where((task) => !task.isCompleted).length,
    );
  }

  // Add new task list
  void addTaskList(TaskList taskList) {
    _taskLists.add(taskList);
    notifyListeners();
  }

  // Add task to specific list
  void addTask(int listIndex, Task task) {
    if (listIndex >= 0 && listIndex < _taskLists.length) {
      _taskLists[listIndex].tasks.add(task);
      notifyListeners();
    }
  }

  // Toggle task completion
  void toggleTaskCompletion(Task task) {
    task.isCompleted = !task.isCompleted;
    notifyListeners();
  }

  // Delete task from list
  void deleteTask(TaskList taskList, Task task) {
    taskList.tasks.remove(task);
    notifyListeners();
  }

  // Delete task list
  void deleteTaskList(TaskList taskList) {
    _taskLists.remove(taskList);
    notifyListeners();
  }

  // Update task
  void updateTask(Task task, String newTitle) {
    task.title = newTitle;
    notifyListeners();
  }

  // Update task list
  void updateTaskList(TaskList taskList, String newName) {
    taskList.name = newName;
    notifyListeners();
  }
}