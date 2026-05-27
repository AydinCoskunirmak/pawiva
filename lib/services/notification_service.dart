import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:pawiva/models/reminder_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Timer? _notificationTimer;
  static VoidCallback? onStopRequested;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final String timezone = DateTime.now().timeZoneName;
      final Map<String, String> tzMap = {
        'GMT': 'GMT',
        'UTC': 'UTC',
        // Americas
        'EST': 'America/New_York',
        'EDT': 'America/New_York',
        'CST': 'America/Chicago',
        'CDT': 'America/Chicago',
        'MST': 'America/Denver',
        'MDT': 'America/Denver',
        'PST': 'America/Los_Angeles',
        'PDT': 'America/Los_Angeles',
        'ADT': 'America/Halifax',
        'NST': 'America/St_Johns',
        'BRT': 'America/Sao_Paulo',
        'ART': 'America/Argentina/Buenos_Aires',
        'CLT': 'America/Santiago',
        'COT': 'America/Bogota',
        'PET': 'America/Lima',
        'VET': 'America/Caracas',
        'BOT': 'America/La_Paz',
        'GYT': 'America/Guyana',
        'SRT': 'America/Paramaribo',
        'UYT': 'America/Montevideo',
        'PYT': 'America/Asuncion',
        'ECT': 'America/Guayaquil',
        'AKST': 'America/Anchorage',
        'HST': 'Pacific/Honolulu',
        'HDT': 'Pacific/Honolulu',
        // Europe
        'WET': 'Europe/Lisbon',
        'WEST': 'Europe/Lisbon',
        'CET': 'Europe/Paris',
        'CEST': 'Europe/Paris',
        'EET': 'Europe/Helsinki',
        'TRT': 'Europe/Istanbul',
        'MSK': 'Europe/Moscow',
        'FET': 'Europe/Minsk',
        'SAMT': 'Europe/Samara',
        'YEKT': 'Asia/Yekaterinburg',
        // Africa
        'WAT': 'Africa/Lagos',
        'CAT': 'Africa/Harare',
        'EAT': 'Africa/Nairobi',
        'SAST': 'Africa/Johannesburg',
        // Asia
        'IST': 'Asia/Kolkata',
        'PKT': 'Asia/Karachi',
        'BST': 'Asia/Dhaka',
        'NPT': 'Asia/Kathmandu',
        'LKT': 'Asia/Colombo',
        'MMT': 'Asia/Rangoon',
        'ICT': 'Asia/Bangkok',
        'WIB': 'Asia/Jakarta',
        'HKT': 'Asia/Hong_Kong',
        'SGT': 'Asia/Singapore',
        'MYT': 'Asia/Kuala_Lumpur',
        'PHT': 'Asia/Manila',
        'JST': 'Asia/Tokyo',
        'KST': 'Asia/Seoul',
        'WIT': 'Asia/Jayapura',
        'WITA': 'Asia/Makassar',
        'TLT': 'Asia/Dili',
        'IRKT': 'Asia/Irkutsk',
        'KRAT': 'Asia/Krasnoyarsk',
        'OMST': 'Asia/Omsk',
        'NOVT': 'Asia/Novosibirsk',
        'QYZT': 'Asia/Almaty',
        'UZT': 'Asia/Tashkent',
        'TMT': 'Asia/Ashgabat',
        'AFT': 'Asia/Kabul',
        'IRST': 'Asia/Tehran',
        'GST': 'Asia/Dubai',
        'AST': 'Asia/Riyadh',
        'IDT': 'Asia/Jerusalem',
        // Pacific
        'AEST': 'Australia/Sydney',
        'AEDT': 'Australia/Sydney',
        'ACST': 'Australia/Darwin',
        'ACDT': 'Australia/Adelaide',
        'AWST': 'Australia/Perth',
        'NZST': 'Pacific/Auckland',
        'FJT': 'Pacific/Fiji',
        'PGT': 'Pacific/Port_Moresby',
        'SBT': 'Pacific/Guadalcanal',
        'VUT': 'Pacific/Efate',
        'NCT': 'Pacific/Noumea',
        'WST': 'Pacific/Apia',
        'TOT': 'Pacific/Tongatapu',
        'CHAST': 'Pacific/Chatham',
        'LINT': 'Pacific/Kiritimati',
        '+03': 'Europe/Istanbul',
        '+00': 'UTC',
        '+01': 'Europe/Paris',
        '+02': 'Europe/Helsinki',
        '+04': 'Asia/Dubai',
        '+05': 'Asia/Karachi',
        '+05:30': 'Asia/Kolkata',
        '+06': 'Asia/Dhaka',
        '+07': 'Asia/Bangkok',
        '+08': 'Asia/Shanghai',
        '+09': 'Asia/Tokyo',
        '+10': 'Australia/Sydney',
        '+11': 'Pacific/Guadalcanal',
        '+12': 'Pacific/Auckland',
        '-01': 'Atlantic/Azores',
        '-02': 'America/Noronha',
        '-03': 'America/Sao_Paulo',
        '-04': 'America/Halifax',
        '-05': 'America/New_York',
        '-06': 'America/Chicago',
        '-07': 'America/Denver',
        '-08': 'America/Los_Angeles',
        '-09': 'America/Anchorage',
        '-10': 'Pacific/Honolulu',
      };
      final String tzName = tzMap[timezone] ?? 'UTC';
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  void startActivityNotifications(String activity) {
    stopActivityNotifications();

    int intervalMinutes;
    String body;

    switch (activity) {
      case "walk with paws":
        intervalMinutes = 20;
        body = "Are you still walking with Paws? 🐾";
        break;
      case "cuddle and love":
        intervalMinutes = 10;
        body = "Are you still cuddling and loving Paws? 🐾";
        break;
      case "playtime for paws":
        intervalMinutes = 10;
        body = "Are you still having playtime with Paws? 🐾";
        break;
      case "snuggle nap":
        intervalMinutes = 15;
        body = "Are you still snuggling for a nap with Paws? 🐾";
        break;
      default:
        return;
    }

    // Schedule notifications in advance for iOS background support
    _scheduleActivityNotifications(body, intervalMinutes);

    // Timer.periodic for foreground (Android)
    _notificationTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
          (timer) => _showActivityNotification(body),
    );
  }

  Future<void> _scheduleActivityNotifications(String body, int intervalMinutes) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pawiva_timer_channel',
      'Pawiva Timer',
      channelDescription: 'Timer activity notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule 5 notifications in advance
    for (int i = 1; i <= 5; i++) {
      final scheduledTime = tz.TZDateTime.now(tz.local).add(
        Duration(minutes: intervalMinutes * i),
      );
      await _notifications.zonedSchedule(
        100 + i,
        'Pawiva 🐾',
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  void stopActivityNotifications() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    // Only cancel activity notifications (100-105)
    for (int i = 100; i <= 105; i++) {
      _notifications.cancel(i);
    }
  }

  static void stopFromNotification() {
    NotificationService().stopActivityNotifications();
    onStopRequested?.call();
  }

  Future<void> _showActivityNotification(String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pawiva_timer_channel',
      'Pawiva Timer',
      channelDescription: 'Timer activity notifications',
      importance: Importance.high,
      priority: Priority.high,
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'pawiva_timer',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      'Pawiva 🐾',
      body,
      details,
    );
  }

  Future<void> scheduleReminder(ReminderModel reminder) async {
    String body;
    switch (reminder.activity) {
      case "walk with paws":
        body = "🐾 Time for your walk with Paws!";
        break;
      case "cuddle and love":
        body = "🤗 Time to cuddle and love Paws!";
        break;
      case "playtime for paws":
        body = "🎾 Playtime with Paws!";
        break;
      case "snuggle nap":
        body = "😴 Snuggle nap time with Paws!";
        break;
      default:
        body = "Time for activity with Paws!";
    }

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'pawiva_reminders_channel',
      'Pawiva Reminders',
      channelDescription: 'Scheduled reminders for activities',
      importance: Importance.max,
      priority: Priority.max,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (reminder.weekdays.isNotEmpty) {
      for (int day in reminder.weekdays) {
        await _notifications.zonedSchedule(
          reminder.id + day * 1000,
          'Pawiva 🐾',
          body,
          _nextInstanceOfWeekday(day, reminder.time.hour, reminder.time.minute),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } else {
      // One-time reminder
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        reminder.isTomorrow ? now.day + 1 : now.day,
        reminder.time.hour,
        reminder.time.minute,
      );

      // If Today and already passed, don't schedule or schedule for next occurrence?
      // For Pawiva, one-time reminders are usually for specific day.
      if (scheduledDate.isAfter(now)) {
        await _notifications.zonedSchedule(
          reminder.id,
          'Pawiva 🐾',
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
    for (int i = 1; i <= 7; i++) {
      await _notifications.cancel(id + i * 1000);
    }
  }
}

@pragma('vm:entry-point')
void _onNotificationResponse(NotificationResponse response) {
  if (response.actionId == 'stop_action') {
    NotificationService.stopFromNotification();
  }
}