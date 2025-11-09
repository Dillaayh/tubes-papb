// lib/pages/dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../database/app_database.dart';
import '../widgets/empty_state.dart';
import '../utils/constants.dart'; // Pastikan Anda punya file ini

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Wunderlist', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: 'Pengaturan',
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              // ✅ WIDGET STATISTIK BARU DI SINI
              child: _buildStatsHeader(db, theme),
            ),
          ];
        },
        body: StreamBuilder<List<TaskList>>(
          stream: db.taskListDao.watchAll(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const EmptyState(
                icon: Icons.inbox_outlined,
                message: 'Belum Ada Kategori.\nBuat kategori pertama untuk mulai mengelola tugas.',
              );
            }

            final categories = snapshot.data!;
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _CategoryCard(category: category),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-category'),
        icon: const Icon(Icons.add),
        label: const Text('Kategori Baru'),
      ),
    );
  }

  // ✅ FUNGSI BARU UNTUK MEMBUAT HEADER STATISTIK
  Widget _buildStatsHeader(AppDatabase db, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: StreamBuilder<List<Task>>(
        stream: db.taskDao.watchAll(),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];
          final completed = tasks.where((t) => t.isCompleted).length;
          final incomplete = tasks.length - completed;

          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'Total Tugas', value: tasks.length.toString(), color: theme.colorScheme.primary),
                _StatItem(label: 'Aktif', value: incomplete.toString(), color: Colors.orange.shade700),
                _StatItem(label: 'Selesai', value: completed.toString(), color: Colors.green.shade600),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ✅ WIDGET BARU UNTUK ITEM STATISTIK
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}


class _CategoryCard extends StatelessWidget {
  final TaskList category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final color = Color(category.colorValue);
    final icon = AppConstants.getCategoryIcon(category.iconName ?? 'category');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/task-list/${category.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    StreamBuilder<List<Task>>(
                      stream: db.taskDao.watchByListId(category.id),
                      builder: (context, taskSnapshot) {
                        if (!taskSnapshot.hasData) return const SizedBox.shrink();
                        final tasks = taskSnapshot.data!;
                        final incomplete = tasks.where((t) => !t.isCompleted).length;
                        return Text(
                          incomplete == 0 ? 'Semua tugas selesai' : '$incomplete tugas aktif',
                          style: TextStyle(fontSize: 14, color: incomplete == 0 ? Colors.green : Colors.grey[600]),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
