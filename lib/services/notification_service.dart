import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service untuk mengelola local notifications
/// Digunakan untuk mengirim notifikasi konflik jadwal ke user
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    // Set default timezone to Asia/Jakarta (WIB)
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // Android notification settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS notification settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    print('✅ Notification service initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // TODO: Navigate to HomePage or specific screen
    // Bisa menggunakan NavigatorKey untuk navigasi dari service
  }

  /// Request notification permission (untuk Android 13+)
  Future<bool> requestPermission() async {
    if (!_initialized) await initialize();

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return true; // iOS handled via initialization
  }

  /// Send immediate notification untuk konflik jadwal
  Future<void> sendConflictNotification({
    required int conflictCount,
    String? conflictDetails,
  }) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'conflict_alerts', // channel ID
      'Konflik Jadwal', // channel name
      channelDescription: 'Notifikasi ketika terdeteksi konflik jadwal',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF9800), // AppColors.warning
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = conflictCount == 1
        ? '⚠️ Konflik Jadwal Terdeteksi'
        : '⚠️ $conflictCount Konflik Jadwal Terdeteksi';

    final body = conflictDetails ??
        'Ada bentrok antara jadwal kuliah dengan kegiatan lain hari ini. Tap untuk lihat detail.';

    await _notifications.show(
      0, // notification ID
      title,
      body,
      notificationDetails,
      payload: 'conflict_alert',
    );

    print('🔔 Sent conflict notification: $conflictCount conflicts');
  }

  /// Schedule daily morning check (07:00 AM)
  Future<void> scheduleDailyConflictCheck() async {
    if (!_initialized) await initialize();

    // Cancel existing scheduled notifications
    await _notifications.cancel(1);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      7, // 07:00 AM
      0,
    );

    // Jika sudah lewat jam 7 hari ini, schedule untuk besok
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_check',
      'Cek Harian',
      channelDescription: 'Pengecekan konflik jadwal harian',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      1, // notification ID
      '🌅 Selamat Pagi!',
      'Tap untuk cek jadwal hari ini',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: 'daily_check',
    );

    print('📅 Scheduled daily check at 07:00 AM');
  }

  /// Send notification 1 jam sebelum konflik
  Future<void> schedulePreConflictWarning({
    required String academicTitle,
    required String conflictTitle,
    required DateTime conflictTime,
  }) async {
    if (!_initialized) await initialize();

    // Schedule 1 jam sebelum konflik
    final warningTime = conflictTime.subtract(const Duration(hours: 1));

    // Jika waktu warning sudah lewat, skip
    if (warningTime.isBefore(DateTime.now())) {
      return;
    }

    final scheduledTime = tz.TZDateTime.from(warningTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      'pre_conflict_warning',
      'Peringatan Konflik',
      channelDescription: 'Peringatan 1 jam sebelum konflik jadwal',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF9800),
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = conflictTime.millisecondsSinceEpoch ~/ 1000;

    await _notifications.zonedSchedule(
      notificationId,
      '⏰ Peringatan: Konflik dalam 1 Jam',
      '$academicTitle bentrok dengan $conflictTitle',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'pre_conflict,$notificationId',
    );

    print('⏰ Scheduled pre-conflict warning at ${warningTime.hour}:${warningTime.minute}');
  }

  /// Schedule reminder 30 menit sebelum event dimulai
  /// 
  /// Untuk mengingatkan user sebelum kuliah, rapat, atau event penting lainnya
  Future<void> scheduleEventReminder({
    required String eventTitle,
    required String eventType,
    required DateTime eventStartTime,
  }) async {
    if (!_initialized) await initialize();

    // Schedule 30 menit sebelum event
    final reminderTime = eventStartTime.subtract(const Duration(minutes: 30));

    // Jika waktu reminder sudah lewat, skip
    if (reminderTime.isBefore(DateTime.now())) {
      return;
    }

    final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      'event_reminders',
      'Pengingat Event',
      channelDescription: 'Pengingat 30 menit sebelum event dimulai',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF013880), // AppColors.primary
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Unique ID based on event start time
    final notificationId = eventStartTime.millisecondsSinceEpoch ~/ 1000;

    final timeString = '${eventStartTime.hour.toString().padLeft(2, '0')}:${eventStartTime.minute.toString().padLeft(2, '0')}';

    await _notifications.zonedSchedule(
      notificationId,
      '🔔 Pengingat: $eventType',
      '$eventTitle dimulai jam $timeString (30 menit lagi)',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'event_reminder,$notificationId',
    );

    print('🔔 Scheduled reminder for "$eventTitle" at ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');
  }

  /// Schedule reminders untuk semua event hari ini
  /// 
  /// Akan men-schedule notification 30 menit sebelum setiap event
  Future<void> scheduleAllEventReminders(List<dynamic> events) async {
    if (!_initialized) await initialize();

    int scheduled = 0;

    for (var event in events) {
      // Skip if event doesn't have required properties
      if (event == null) continue;

      try {
        final title = event.title as String? ?? 'Event';
        final startTime = event.startTime as DateTime?;
        final source = event.source?.displayName as String? ?? 'Event';

        if (startTime == null) continue;

        // Hanya schedule untuk event yang belum lewat
        if (startTime.isAfter(DateTime.now())) {
          await scheduleEventReminder(
            eventTitle: title,
            eventType: source,
            eventStartTime: startTime,
          );
          scheduled++;
        }
      } catch (e) {
        print('Error scheduling reminder for event: $e');
      }
    }

    print('📅 Scheduled $scheduled event reminders for today');
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print('🔕 All notifications cancelled');
  }

  /// Cancel specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
