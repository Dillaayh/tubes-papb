import 'package:flutter/material.dart';

class Task {
  String title;
  bool isCompleted;

  Task(this.title, this.isCompleted);
}

class TaskList {
  String name;
  IconData icon;
  Color color;
  List<Task> tasks;

  TaskList({
    required this.name,
    required this.icon,
    required this.color,
    required this.tasks,
  });
}