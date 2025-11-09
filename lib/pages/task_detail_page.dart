// lib/pages/task_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../utils/constants.dart';
import '../utils/date_helper.dart';

class TaskDetailPage extends StatelessWidget {
  final int taskId;

  const TaskDetailPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();

    return StreamBuilder<TaskWithList>(
      stream: db.taskDao.watchByIdWithList(taskId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tugas Tidak Ditemukan')),
            // ✅ FIX: Hapus 'const' dari Center
            body: Center(child: Text('Tugas dengan ID $taskId tidak ditemukan.')),
          );
        }

        final item = snapshot.data!;
        final task = item.task;
        final category = item.taskList;
        final categoryColor = Color(category.colorValue);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Tugas'),
            actions: [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/edit-task/$taskId'), tooltip: 'Edit Tugas'),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _showDeleteDialog(context, db, task), tooltip: 'Hapus Tugas'),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(task.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(task.isCompleted ? 'Selesai' : 'Aktif', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: task.isCompleted ? Colors.green : Colors.orange,
                  avatar: Icon(task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildInfoRow(icon: AppConstants.getCategoryIcon(category.iconName ?? 'category'), iconColor: categoryColor, label: 'Kategori', value: category.name),
              _buildInfoRow(icon: AppConstants.getPriorityIcon(task.priority), iconColor: AppConstants.getPriorityColor(task.priority), label: 'Prioritas', value: task.priority),
              if (task.dueDate != null) _buildInfoRow(icon: Icons.calendar_today_outlined, iconColor: _getDueDateColor(task), label: 'Jatuh Tempo', value: DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(task.dueDate!)),
              _buildInfoRow(icon: Icons.access_time, iconColor: Colors.grey, label: 'Dibuat Pada', value: DateFormat('dd MMM yyyy, HH:mm').format(task.createdAt)),

              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Deskripsi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Text(task.description!, style: const TextStyle(fontSize: 16, height: 1.5)),
                ),
              ],
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => db.taskDao.toggleComplete(task.id),
            icon: Icon(task.isCompleted ? Icons.undo_rounded : Icons.check_circle_outline_rounded),
            label: Text(task.isCompleted ? 'Tandai Belum Selesai' : 'Tandai Selesai'),
            backgroundColor: task.isCompleted ? Colors.orange.shade700 : Colors.green.shade600,
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({ required IconData icon, required Color iconColor, required String label, required String value, Color? valueColor }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: valueColor)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDueDateColor(Task task) {
    if (task.dueDate == null) return Colors.grey;
    if (DateHelper.isPast(task.dueDate!) && !task.isCompleted) return Colors.red.shade700;
    if (DateHelper.isToday(task.dueDate!)) return Colors.orange.shade700;
    return Colors.grey.shade600;
  }

  void _showDeleteDialog(BuildContext context, AppDatabase db, Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: Text('Anda yakin ingin menghapus tugas "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await db.taskDao.deleteById(task.id);
              if (context.mounted) context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
