import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alz_ai/core/services/geofence_service.dart';
import 'package:alz_ai/core/services/fall_detection_service.dart';
import 'package:alz_ai/core/services/vitals_service.dart';
import 'package:alz_ai/features/patient/vitals/models/vitals_models.dart';
import 'package:alz_ai/core/config/app_config.dart';
import 'package:alz_ai/core/services/location_service.dart';
import 'package:alz_ai/features/patient/background/models/background_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

@pragma('vm:entry-point')
class BackgroundServiceInstance {
  static final _eventController = StreamController<dynamic>.broadcast();

  static Future<void> initialize({
    bool? hasHealthPermissions,
    bool? hasLocationPermissions,
  }) async {
    final service = FlutterBackgroundService();
    
    // Real-time permission check if flags are null
    if (hasLocationPermissions == null) {
      final status = await Permission.location.status;
      hasLocationPermissions = status.isGranted;
    }
    
    if (hasHealthPermissions == null) {
      // We check if we can actually read health data. 
      // This is a simplified check; VitalsService will handle deeper checks.
      hasHealthPermissions = await Permission.activityRecognition.isGranted;
    }

    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt('level') ?? 0;

    // Setup Local Notifications for Foreground Service on Android 13+
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alz_ai_foreground', // id
      'ALZ-AI Monitoring', // title
      description: 'Maintains background safety services',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'alz_ai_foreground',
        initialNotificationTitle: 'Alz-AI is active',
        initialNotificationContent: 'Monitoring and keeping you safe',
        foregroundServiceTypes: [
          if (level == 3 && (hasHealthPermissions ?? false)) AndroidForegroundType.health,
          if (hasLocationPermissions ?? false) AndroidForegroundType.location,
        ],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    
    await service.startService();
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
    
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) => service.setAsForegroundService());
      service.on('setAsBackground').listen((event) => service.setAsBackgroundService());
    }

    service.on('stopService').listen((event) => service.stopSelf());

    // Initialize Services inside Background Isolate
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // Add Auth Interceptor for Background Isolate
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        const secureStorage = FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );
        final token = await secureStorage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));

    final geofenceService = GeofenceService(dio);
    final fallDetectionService = FallDetectionService();
    final vitalsService = VitalsService();
    final locationService = LocationService();
    final tts = FlutterTts();
    // Listen to service streams
    geofenceService.events.listen((event) async {
       service.invoke('geofence_event', event.toJson());
       
       // Immediate sync and voice warning on geofence breach
       if (event is GeofenceBreached) {
          const secureStorage = FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );
          final lang = await secureStorage.read(key: 'language') ?? 'en';
          
          // 1. Voice Warning (Background Isolate)
          final messages = {
            'hi': 'Aai, aap ghar se door ja rahi hain. Kripya ghar laut chaliye.',
            'mr': 'Aai, tumi ghara pasun dur challat ahat. Krupaya ghari parat ya.',
            'en': 'You are moving away from home. Please return to your safe area.',
          };
          final msg = messages[lang] ?? messages['en']!;
          await tts.setLanguage(lang == 'hi' ? 'hi-IN' : (lang == 'mr' ? 'mr-IN' : 'en-US'));
          await tts.speak(msg);

          // 2. Sync to Backend
          final patientId = await secureStorage.read(key: 'patient_id');
          final token = await secureStorage.read(key: 'access_token');
          if (patientId != null && token != null) {
             await dio.post(
               'patient/location',
               data: {
                 'lat': event.latitude,
                 'lng': event.longitude,
                 'accuracy': 0.0,
                 'status': 'outside'
               },
               options: Options(headers: {'Authorization': 'Bearer $token'}),
             );
          }
       }
    });
    fallDetectionService.events.listen((event) => service.invoke('fall_event', event.toJson()));

    int consecutiveFailedHCReads = 0;

    // Vitals Monitoring & Sync Loop (60 seconds)
    Timer.periodic(const Duration(seconds: 60), (timer) async {
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final prefs = await SharedPreferences.getInstance();
      
      final patientId = await secureStorage.read(key: 'patient_id');
      final token = await secureStorage.read(key: 'access_token');
      final levelStr = await secureStorage.read(key: 'level');
      final level = levelStr != null ? int.tryParse(levelStr) : 0;
      final lang = await secureStorage.read(key: 'language') ?? 'en';

      if (patientId == null) {
        return;
      }

      try {
        final reading = await vitalsService.readCurrentVitals();
        
        if (reading != null && reading.heartRate > 0) {
          consecutiveFailedHCReads = 0;
          await prefs.setString('last_vitals_time', DateTime.now().toIso8601String());
          
          // 1. Sync to Backend
          if (token != null) {
            
            await dio.post(
              'caretaker/vitals',
              data: {
                'patient_id': patientId,
                ...reading.toJson(),
              },
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
          }

          // 2. Threshold Checks & Local Alerts
          await _checkVitalsThresholds(reading, tts, lang, prefs);
        } else {
          consecutiveFailedHCReads++;
        }

        // 3. Watch Disconnect Logic (Level 3 specific)
        if (level == 3) {
          bool triggerWatchAlert = false;

          // a) Check last vitals time (WebSocket/HC unified)
          final lastVitalsStr = prefs.getString('last_vitals_time');
          if (lastVitalsStr != null) {
            final lastVitals = DateTime.parse(lastVitalsStr);
            if (DateTime.now().difference(lastVitals).inMinutes >= 30) {
              triggerWatchAlert = true;
            }
          }

          // b) Check HC Failures (3 fails = 3 mins)
          if (consecutiveFailedHCReads >= 3) {
            triggerWatchAlert = true;
          }

          if (triggerWatchAlert) {
            await _alertWatchDisconnected(tts, lang, prefs);
          }
        }
      } catch (e) {
        debugPrint("Background Vitals Sync Error: $e");
      }
    });

    // 4. Initial & Periodic Location Sync (Every 60 seconds)
    Future<void> syncLocation() async {
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final patientId = await secureStorage.read(key: 'patient_id');
      final token = await secureStorage.read(key: 'access_token');
      if (patientId == null || token == null) return;

      try {
        final position = await locationService.getCurrentLocation();
        if (position != null) {
          await dio.post(
            'patient/location',
            data: {
              'lat': position.latitude,
              'lng': position.longitude,
              'accuracy': position.accuracy,
            },
          );
        }
      } catch (e) {
        debugPrint("Background Location Sync Error: $e");
      }
    }

    // Trigger immediate sync on start
    syncLocation();
    
    // Then every 60 seconds
    Timer.periodic(const Duration(seconds: 60), (timer) async {
       await syncLocation();
    });
  }

  static Future<void> _checkVitalsThresholds(VitalsReading reading, FlutterTts tts, String lang, SharedPreferences prefs) async {
    const cooldownDuration = Duration(minutes: 10);
    final now = DateTime.now();

    bool shouldAlert = false;
    String alertType = "";

    // HR Thresholds
    if (reading.heartRate > 120 || reading.heartRate < 45) {
      final lastAlert = prefs.getString('last_alert_hr');
      if (lastAlert == null || now.difference(DateTime.parse(lastAlert)) > cooldownDuration) {
        shouldAlert = true;
        alertType = "hr";
        await prefs.setString('last_alert_hr', now.toIso8601String());
      }
    }

    // SpO2 Threshold
    if (reading.spo2 > 0 && reading.spo2 < 90) {
      final lastAlert = prefs.getString('last_alert_spo2');
      if (lastAlert == null || now.difference(DateTime.parse(lastAlert)) > cooldownDuration) {
        shouldAlert = true;
        alertType = "spo2";
        await prefs.setString('last_alert_spo2', now.toIso8601String());
      }
    }

    if (shouldAlert) {
      await _speakVitalsAlert(tts, lang);
    }
  }

  static Future<void> _speakVitalsAlert(FlutterTts tts, String lang) async {
    final messages = {
      'en': "Abnormal vitals detected. Please sit down and breathe.",
      'hi': "असामान्य महत्वपूर्ण संकेत मिले हैं। कृपया बैठें और सांस लें।",
      'mr': "असामान्य जीवनलक्षणे आढळली आहेत. कृपया बसा आणि श्वास घ्या।",
    };

    final msg = messages[lang] ?? messages['en']!;
    await tts.setLanguage(lang == 'hi' ? 'hi-IN' : (lang == 'mr' ? 'mr-IN' : 'en-US'));
    await tts.speak(msg);
  }

  static Future<void> _alertWatchDisconnected(FlutterTts tts, String lang, SharedPreferences prefs) async {
    const cooldown = Duration(minutes: 10);
    final now = DateTime.now();
    final last = prefs.getString('last_alert_watch_disconnect');
    
    if (last != null && now.difference(DateTime.parse(last)) < cooldown) return;

    final messages = {
      'en': "Smartwatch disconnected. Please wear your watch for safety.",
      'hi': "स्मार्टवॉच डिस्कनेक्ट हो गई है। कृपया सुरक्षा के लिए अपनी घड़ी पहनें।",
      'mr': "स्मार्टवॉच डिस्कनेक्ट झाली आहे. कृपया सुरक्षिततेसाठी तुमची घड्याळ घाला।",
    };

    await prefs.setString('last_alert_watch_disconnect', now.toIso8601String());
    final msg = messages[lang] ?? messages['en']!;
    await tts.setLanguage(lang == 'hi' ? 'hi-IN' : (lang == 'mr' ? 'mr-IN' : 'en-US'));
    await tts.speak(msg);
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }
}
