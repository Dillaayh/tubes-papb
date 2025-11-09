// lib/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart'; // Mengimpor kelas dari Drift, bukan model manual
import '../utils/constants.dart';
import '../utils/date_helper.dart';

class TaskCard extends StatelessWidget {
  // ✅ MENERIMA TaskWithList, bukan Task dari model lama
  final TaskWithList taskWithList;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const TaskCard({
    super.key,
    required this.taskWithList,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Mengambil data dari TaskWithList
    final task = taskWithList.task;
    final category = taskWithList.taskList;
    final categoryColor = Color(category.colorValue); // ✅ Mengambil warna (int) dari database
    final categoryIcon = AppConstants.getCategoryIcon(category.iconName ?? 'category'); // ✅ Mengambil ikon dari database

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: task.isCompleted ? categoryColor : Colors.grey, width: 2),
                    color: task.isCompleted ? categoryColor : Colors.transparent,
                  ),
                  child: task.isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? Colors.grey[600] : Colors.black87,
                      ),
                    ),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (task.dueDate != null) ...[
                          Icon(Icons.calendar_today_rounded, size: 14, color: _getDueDateColor(task)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM', 'id_ID').format(task.dueDate!),
                            style: TextStyle(fontSize: 13, color: _getDueDateColor(task), fontWeight: FontWeight.w500),
                          ),
                          const Text(' • ', style: TextStyle(color: Colors.grey)),
                        ],
                        Icon(AppConstants.getPriorityIcon(task.priority), size: 14, color: AppConstants.getPriorityColor(task.priority)),
                        const SizedBox(width: 4),
                        Text(task.priority, style: TextStyle(fontSize: 13, color: AppConstants.getPriorityColor(task.priority), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Menerima Task (dari Drift) sebagai parameter
  Color _getDueDateColor(Task task) {
    if (task.dueDate == null) return Colors.grey;
    if (DateHelper.isPast(task.dueDate!) && !task.isCompleted) return Colors.red.shade700;
    if (DateHelper.isToday(task.dueDate!)) return Colors.orange.shade700;
    return Colors.grey.shade600;
  }
}
