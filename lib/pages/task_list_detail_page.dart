// lib/pages/task_list_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../services/notification_service.dart'; // ✅ IMPOR SERVICE
import '../widgets/empty_state.dart';

class TaskListPage extends StatelessWidget {
  final String categoryId;
  const TaskListPage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    final int id = int.parse(categoryId);

    return Scaffold(
      body: StreamBuilder<TaskList>(
        stream: db.taskListDao.watchById(id),
        builder: (context, snapshot) {
          final category = snapshot.data;
          if (category == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(category.name),
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _showDeleteCategoryDialog(context, db, category),
                    tooltip: 'Hapus Kategori',
                  ),
                ],
              ),
              _buildTaskList(context, db, id),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-task/$categoryId'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, AppDatabase db, int categoryId) {
    return StreamBuilder<List<Task>>(
      stream: db.taskDao.watchByListId(categoryId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }
        final tasks = snapshot.data!;
        if (tasks.isEmpty) {
          return const SliverFillRemaining(
            child: EmptyState(
              icon: Icons.task_alt,
              message: 'Belum ada tugas di sini.',
            ),
          );
        }

        return SliverList.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return ListTile(
              leading: Checkbox(
                value: task.isCompleted,
                onChanged: (_) {
                  // Panggil metode toggleComplete dari DAO
                  db.taskDao.toggleComplete(task.id);
                },
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? Colors.grey : null,
                ),
              ),
              subtitle: task.dueDate != null ? Text('Jatuh tempo: ${task.dueDate!.toLocal()}') : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteTaskDialog(context, db, task),
              ),
              onTap: () => context.push('/edit-task/${task.id}'),
            );
          },
        );
      },
    );
  }

  void _showDeleteTaskDialog(BuildContext context, AppDatabase db, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: Text('Anda yakin ingin menghapus tugas "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              context.pop();
              await db.taskDao.deleteById(task.id);
              // ✅ BATALKAN NOTIFIKASI SAAT TUGAS DIHAPUS
              await NotificationService().cancelNotification(task.id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, AppDatabase db, TaskList category) {
    // ... (Fungsi ini bisa Anda kembangkan untuk menghapus kategori beserta semua tugasnya)
    // Jangan lupa untuk membatalkan notifikasi semua tugas di dalamnya jika Anda mengimplementasikan ini.
  }
}
