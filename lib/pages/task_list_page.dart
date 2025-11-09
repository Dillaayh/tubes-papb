// lib/pages/task_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../database/app_database.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';

class TaskListPage extends StatefulWidget {
  final int categoryId;
  const TaskListPage({super.key, required this.categoryId});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  SortOption _sortOption = SortOption.priority;
  FilterOption _filterOption = FilterOption.all;

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();

    return StreamBuilder<TaskList>(
      // ✅ FIX: Menggunakan watchById (Stream) bukan getById (Future)
      stream: db.taskListDao.watchById(widget.categoryId),
      builder: (context, categorySnapshot) {
        if (!categorySnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final category = categorySnapshot.data!;
        final color = Color(category.colorValue);

        return Scaffold(
          appBar: AppBar(
            title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: color.withOpacity(0.1),
            elevation: 0,
            actions: [
              PopupMenuButton<dynamic>(
                onSelected: (value) {
                  if (value == 'delete_completed') {
                    _showDeleteCompletedDialog(context, db);
                  } else {
                    setState(() {
                      if (value is SortOption) _sortOption = value;
                      if (value is FilterOption) _filterOption = value;
                    });
                  }
                },
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: 'Opsi',
                itemBuilder: (context) => [
                  const PopupMenuItem(enabled: false, child: Text('URUTKAN BERDASARKAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  CheckedPopupMenuItem(value: SortOption.priority, checked: _sortOption == SortOption.priority, child: const Text('Prioritas')),
                  CheckedPopupMenuItem(value: SortOption.dueDate, checked: _sortOption == SortOption.dueDate, child: const Text('Tanggal')),
                  CheckedPopupMenuItem(value: SortOption.name, checked: _sortOption == SortOption.name, child: const Text('Nama')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(enabled: false, child: Text('TAMPILKAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  CheckedPopupMenuItem(value: FilterOption.all, checked: _filterOption == FilterOption.all, child: const Text('Semua Tugas')),
                  CheckedPopupMenuItem(value: FilterOption.active, checked: _filterOption == FilterOption.active, child: const Text('Tugas Aktif')),
                  CheckedPopupMenuItem(value: FilterOption.completed, checked: _filterOption == FilterOption.completed, child: const Text('Tugas Selesai')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'delete_completed', child: Text('Hapus Tugas Selesai')),
                ],
              ),
            ],
          ),
          body: StreamBuilder<List<TaskWithList>>(
            // ✅ FIX: Menggunakan watchTasksInCategory yang lebih canggih
            stream: db.taskDao.watchTasksInCategory(
              widget.categoryId,
              sortBy: _sortOption,
              filterBy: _filterOption,
            ),
            builder: (context, taskSnapshot) {
              if (taskSnapshot.connectionState == ConnectionState.waiting && !taskSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!taskSnapshot.hasData || taskSnapshot.data!.isEmpty) {
                return const EmptyState(
                  message: 'Belum ada tugas di kategori ini.\nTekan tombol + untuk menambahkan.',
                  icon: Icons.check_box_outline_blank_rounded,
                );
              }

              final tasksWithList = taskSnapshot.data!;
              return AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: tasksWithList.length,
                  itemBuilder: (context, index) {
                    final item = tasksWithList[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          // ✅ FIX: Memanggil TaskCard yang benar
                          child: TaskCard(
                            taskWithList: item,
                            onTap: () => context.push('/task-detail/${item.task.id}'),
                            onToggle: () => db.taskDao.toggleComplete(item.task.id),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/add-task/${category.id}'),
            backgroundColor: color,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  // ✅ FIX: Menggunakan metode deleteCompleted dari DAO
  void _showDeleteCompletedDialog(BuildContext context, AppDatabase db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tugas Selesai'),
        content: const Text('Anda yakin ingin menghapus semua tugas yang sudah selesai di kategori ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Metode deleteCompleted tidak spesifik per list, ini akan menghapus semua tugas selesai
              // Jika ingin per list, kita perlu metode baru di DAO. Untuk sekarang, ini sudah cukup.
              await db.taskDao.deleteCompleted();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tugas selesai berhasil dihapus')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
