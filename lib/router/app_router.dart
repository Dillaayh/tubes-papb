// lib/router/app_router.dart
import 'package:go_router/go_router.dart';
import '../pages/onboarding_page.dart'; // Asumsi Anda akan membuat file ini
import '../pages/dashboard.dart';
import '../pages/add_category_page.dart';
import '../pages/task_list_page.dart';
import '../pages/add_edit_task_page.dart';
import '../pages/task_detail_page.dart';
import '../pages/settings_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/onboarding', // Arahkan ke dashboard untuk sekarang
  routes: [
    GoRoute(
      path: '/onboarding', // Ganti path awal jika perlu
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const Dashboard(),
    ),
    GoRoute(
      path: '/add-category',
      builder: (context, state) => const AddCategoryPage(),
    ),
    GoRoute(
      path: '/task-list/:categoryId',
      builder: (context, state) {
        final categoryId = int.parse(state.pathParameters['categoryId']!);
        return TaskListPage(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/add-task/:categoryId',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId'];
        return AddEditTaskPage(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/edit-task/:taskId',
      builder: (context, state) {
        // 'taskId' di sini merujuk ke parameter di path, misal: /edit-task/123
        final taskId = state.pathParameters['taskId']!;
        return AddEditTaskPage(taskId: taskId);
      },
    ),
    GoRoute(
      // ✅ FIX: Ganti nama parameter agar konsisten
      path: '/task-detail/:taskId',
      builder: (context, state) {
        // ✅ FIX: Parse String ke int sebelum dikirim ke page
        final taskId = int.parse(state.pathParameters['taskId']!);
        return TaskDetailPage(taskId: taskId);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
