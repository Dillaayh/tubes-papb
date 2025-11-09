// lib/pages/add_edit_task_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart'; // ✅ 1. IMPOR SERVICE NOTIFIKASI

class AddEditTaskPage extends StatefulWidget {
  final String? taskId;
  final String? categoryId;

  const AddEditTaskPage({super.key, this.taskId, this.categoryId});

  @override
  State<AddEditTaskPage> createState() => _AddEditTaskPageState();
}

class _AddEditTaskPageState extends State<AddEditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _selectedCategoryId;
  String _selectedPriority = 'Medium';
  DateTime? _selectedDueDate;
  bool _isLoading = true;
  bool get _isEditMode => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      _selectedCategoryId = int.tryParse(widget.categoryId!);
    }
    if (_isEditMode) {
      _loadTaskData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTaskData() async {
    final db = context.read<AppDatabase>();
    final taskId = int.parse(widget.taskId!);
    final task = await db.taskDao.getById(taskId);

    if (task != null && mounted) {
      setState(() {
        _titleController.text = task.title;
        _descriptionController.text = task.description ?? '';
        _selectedCategoryId = task.taskListId;
        _selectedPriority = task.priority;
        _selectedDueDate = task.dueDate;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      // Biarkan pengguna memilih waktu juga
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDueDate ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _selectedDueDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  // ✅ 2. PERBARUI METODE PENYIMPANAN
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      if(_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori terlebih dahulu')));
      }
      return;
    }

    setState(() => _isLoading = true);

    final db = context.read<AppDatabase>();
    final notificationService = NotificationService();
    final companion = TasksCompanion(
      title: drift.Value(_titleController.text.trim()),
      description: drift.Value(_descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim()),
      taskListId: drift.Value(_selectedCategoryId!),
      priority: drift.Value(_selectedPriority),
      dueDate: drift.Value(_selectedDueDate),
    );

    try {
      if (_isEditMode) {
        final taskId = int.parse(widget.taskId!);
        await db.taskDao.patch(taskId, companion);
        final updatedTask = await db.taskDao.getById(taskId);
        if (updatedTask != null) {
          // Selalu batalkan notifikasi lama
          await notificationService.cancelNotification(updatedTask.id);
          // Jadwalkan yang baru jika ada tanggal
          await notificationService.scheduleNotification(updatedTask);
        }
      } else {
        final newId = await db.taskDao.insertOne(companion);
        final newTask = await db.taskDao.getById(newId);
        if (newTask != null) {
          // Jadwalkan notifikasi untuk tugas baru
          await notificationService.scheduleNotification(newTask);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tugas berhasil ${ _isEditMode ? 'diperbarui' : 'ditambahkan'}')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... UI Anda sudah bagus, tidak perlu diubah ...
    // Saya hanya akan menyalinnya kembali dengan sedikit perbaikan pada _selectDate UI
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Tugas' : 'Tambah Tugas'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul Tugas', prefixIcon: Icon(Icons.title_rounded)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul tidak boleh kosong' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)', prefixIcon: Icon(Icons.description_outlined)),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<TaskList>>(
              stream: context.read<AppDatabase>().taskListDao.watchAll(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final categories = snapshot.data!;
                if (categories.isEmpty) return const Text('Buat kategori terlebih dahulu.');
                return DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Kategori', prefixIcon: Icon(Icons.category_outlined)),
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                  items: categories.map((c) => DropdownMenuItem(value: c.id, child: Row(children: [
                    Icon(AppConstants.getCategoryIcon(c.iconName ?? 'work'), color: Color(c.colorValue), size: 22),
                    const SizedBox(width: 12),
                    Text(c.name),
                  ]))).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(labelText: 'Prioritas', prefixIcon: Icon(Icons.flag_outlined)),
                  onChanged: (v) => setState(() => _selectedPriority = v!),
                  items: AppConstants.priorities.map((p) => DropdownMenuItem(value: p, child: Row(children: [
                    Icon(AppConstants.getPriorityIcon(p), color: AppConstants.getPriorityColor(p), size: 20),
                    const SizedBox(width: 8),
                    Text(p),
                  ]))).toList(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Jatuh Tempo', prefixIcon: Icon(Icons.calendar_today_outlined)),
                    child: Text(
                      _selectedDueDate == null ? 'Pilih Tanggal' : DateFormat('dd MMM yyyy, HH:mm').format(_selectedDueDate!),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(_isEditMode ? 'Perbarui Tugas' : 'Simpan Tugas'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

