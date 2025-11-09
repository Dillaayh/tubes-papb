import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import '../database/app_database.dart' as db;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Pengaturan inisialisasi untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Pengaturan inisialisasi untuk iOS
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // HAPUS tz.initializeTimeZones(); DARI SINI
    // Kita sudah memindahkannya ke main.dart

    // Inisialisasi plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          debugPrint('Notification payload: ${response.payload}');
        }
      },
    );

    // Minta izin yang diperlukan untuk platform Android
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// Menjadwalkan notifikasi untuk sebuah tugas.
  Future<void> scheduleNotification(db.Task task) async {
    if (task.dueDate == null || task.dueDate!.isBefore(DateTime.now())) {
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id,
        'Deadline Tugas Mendekat!',
        'Tugas "${task.title}" akan segera berakhir.',
        tz.TZDateTime.from(task.dueDate!, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'wunderlist_reminders_channel',
            'Pengingat Tugas',
            channelDescription: 'Channel untuk pengingat deadline tugas.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint(
          'SUCCESS: Notifikasi dijadwalkan untuk tugas #${task.id} pada ${task.dueDate}');
    } catch (e) {
      debugPrint('ERROR: Gagal menjadwalkan notifikasi untuk tugas #${task.id}: $e');
    }
  }

  /// Membatalkan notifikasi berdasarkan ID tugas.
  Future<void> cancelNotification(int taskId) async {
    await flutterLocalNotificationsPlugin.cancel(taskId);
    debugPrint('Notifikasi untuk tugas #$taskId dibatalkan.');
  }
}

