import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/dashboard.dart';
import '../pages/task_list_detail_page.dart';
import '../models/task.dart';

final GoRouter appRouter = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'dashboard',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const Dashboard(),
      ),
    ),
    GoRoute(
      path: '/task-list-detail',
      name: 'taskListDetail',
      pageBuilder: (context, state) {
        final taskList = state.extra as TaskList?;

        if (taskList == null) {
          return MaterialPage(
            key: state.pageKey,
            child: const Scaffold(
              body: Center(
                child: Text('Task list not found'),
              ),
            ),
          );
        }

        return MaterialPage(
          key: state.pageKey,
          child: TaskListDetailPage(taskList: taskList),
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(
      title: const Text('Error'),
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Halaman tidak ditemukan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            state.error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home),
            label: const Text('Kembali ke Beranda'),
          ),
        ],
      ),
    ),
  ),
);