import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = 
      InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
  }
  
  static Future<void> showMedicationReminder(String medicationName, String dosage) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'alz_ai_medications',
        'Medication Reminders',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''),
      ),
    );
    await _notifications.show(
      1,
      '💊 Time for your medication',
      '$medicationName — $dosage',
      details,
    );
  }
  
  static Future<void> showSAATHICheckin(String message) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'alz_ai_saathi',
        'SAATHI Check-ins',
        importance: Importance.defaultImportance,
      ),
    );
    await _notifications.show(2, 'SAATHI wants to talk 💙', message, details);
  }

  static Future<void> showEmergencySOSConfirmation() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'alz_ai_critical',
        'Critical Health Alerts',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        channelShowBadge: true,
      ),
    );
    await _notifications.show(3, '🚨 Emergency Alert Sent', 'Help is on the way. Your location has been shared.', details);
  }

  static Future<void> showHealthAlert(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'alz_ai_health',
        'Vitals System Warnings',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      ),
    );
    await _notifications.show(4, title, body, details);
  }
  
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
