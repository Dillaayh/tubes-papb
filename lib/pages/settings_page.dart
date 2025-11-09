// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(20)),
                  child: const Center(child: Text('✓', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white))),
                ),
                const SizedBox(height: 16),
                const Text('Wunderlist', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Versi 1.0.0', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader('Statistik'),
          StreamBuilder<List<Task>>(
            stream: db.taskDao.watchAll(),
            builder: (context, snapshot) {
              final tasks = snapshot.data ?? [];
              final completed = tasks.where((t) => t.isCompleted).length;
              final incomplete = tasks.length - completed;
              return Column(
                children: [
                  _buildStatTile(icon: Icons.task_alt, title: 'Total Tugas', value: tasks.length.toString(), color: const Color(0xFF6366F1)),
                  _buildStatTile(icon: Icons.check_circle, title: 'Selesai', value: completed.toString(), color: const Color(0xFF10B981)),
                  _buildStatTile(icon: Icons.pending_actions, title: 'Belum Selesai', value: incomplete.toString(), color: const Color(0xFFF59E0B)),
                ],
              );
            },
          ),
          const Divider(),
          _buildSectionHeader('Kelola Data'),
          _buildSettingTile(icon: Icons.delete_sweep, title: 'Hapus Tugas Selesai', subtitle: 'Hapus semua tugas yang sudah selesai', onTap: () => _showDeleteCompletedDialog(context, db), color: const Color(0xFFF59E0B)),
          _buildSettingTile(icon: Icons.delete_forever, title: 'Hapus Semua Data', subtitle: 'Hapus semua tugas dan kategori', onTap: () => _showClearAllDataDialog(context, db), color: const Color(0xFFEF4444)),
          _buildSettingTile(icon: Icons.refresh, title: 'Reset Database', subtitle: 'Hapus semua data dan buat ulang kategori default', onTap: () => _showResetDatabaseDialog(context, db), color: const Color(0xFF8B5CF6)),
          const Divider(),
          _buildSectionHeader('Tentang'),
          _buildSettingTile(icon: Icons.info_outline, title: 'Tentang Aplikasi', subtitle: 'Informasi tentang Wunderlist', onTap: () => _showAboutDialog(context)),
          _buildSettingTile(icon: Icons.help_outline, title: 'Bantuan', subtitle: 'Panduan penggunaan aplikasi', onTap: () => _showHelpDialog(context)),
          _buildSettingTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', subtitle: 'Kebijakan privasi', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy Policy akan segera hadir')))),
          const SizedBox(height: 32),
          Center(child: Text('Made with ❤️ by You', style: TextStyle(fontSize: 14, color: Colors.grey[600]))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ✅✅✅ SEMUA METODE HELPER YANG HILANG DIKEMBALIKAN DI SINI ✅✅✅

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
    );
  }

  Widget _buildStatTile({required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color))),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: (color ?? const Color(0xFF6366F1)).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color ?? const Color(0xFF6366F1), size: 24),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showDeleteCompletedDialog(BuildContext context, AppDatabase db) async {
    final count = await db.taskDao.countCompleted();
    if (count == 0 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada tugas yang sudah selesai')));
      return;
    }
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Tugas Selesai'),
          content: Text('Anda yakin ingin menghapus $count tugas yang sudah selesai?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await db.taskDao.deleteCompleted();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count tugas berhasil dihapus'), backgroundColor: Colors.green));
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

  void _showClearAllDataDialog(BuildContext context, AppDatabase db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Data'),
        content: const Text('Anda yakin ingin menghapus SEMUA tugas dan kategori? Tindakan ini tidak bisa dikembalikan!'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await db.clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua data berhasil dihapus'), backgroundColor: Colors.red));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  void _showResetDatabaseDialog(BuildContext context, AppDatabase db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Database'),
        content: const Text('Ini akan menghapus SEMUA data Anda dan membuat ulang kategori default. Anda yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await db.clearAllData();
              await (db as dynamic)._initializeDefaultCategories();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database berhasil direset'), backgroundColor: Colors.green));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.purple),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Tentang Wunderlist'),
      content: const Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Wunderlist adalah aplikasi todo list sederhana untuk membantu kamu mengatur tugas kuliah, pekerjaan rumah, dan kebutuhan harian.', style: TextStyle(height: 1.5)),
        SizedBox(height: 16),
        Text('Versi: 1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Dibuat dengan Flutter & ❤️', style: TextStyle(fontWeight: FontWeight.bold)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Tutup'))],
    ));
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Bantuan'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHelpItem('➕ Tambah Kategori', 'Tekan tombol + di dashboard untuk membuat kategori baru'),
          _buildHelpItem('📝 Tambah Task', 'Masuk ke kategori, lalu tap tombol + untuk menambah task'),
          _buildHelpItem('✓ Tandai Selesai', 'Tap checkbox di sebelah kiri task untuk menandai selesai'),
          _buildHelpItem('✏️ Edit Task', 'Tap task untuk lihat detail, lalu tap tombol edit'),
          _buildHelpItem('🗑️ Hapus Task', 'Tap tombol delete di halaman detail task'),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Mengerti'))],
    ));
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(description, style: TextStyle(color: Colors.grey[600], height: 1.4)),
      ]),
    );
  }
}
