import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundService {
  static const MethodChannel _backgroundChannel =
  MethodChannel('background_channel');

  static Future<void> initialize() async {
    try {
      await _backgroundChannel.invokeMethod('initialize');
    } catch (e) {
      print('Error initializing background service: $e');
    }
  }

  static Future<void> start() async {
    try {
      await _backgroundChannel.invokeMethod('start');
    } catch (e) {
      print('Error starting background service: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _backgroundChannel.invokeMethod('stop');
    } catch (e) {
      print('Error stopping background service: $e');
    }
  }

  static void startService(RootIsolateToken rootIsolateToken) async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    await start();
    await handleHeartRateData();
  }

  static Future<void> handleHeartRateData() async {
    HealthFactory health = HealthFactory();
    List<HealthDataType> types = [HealthDataType.HEART_RATE];
    DateTime startDate = DateTime.now().subtract(Duration(hours: 3));
    DateTime endDate = DateTime.now();
    List<HealthDataPoint> heartRateData = await health.getHealthDataFromTypes(
      startDate,
      endDate,
      types,
    );

    bool isStressDetected = detectStress(heartRateData);
    if (isStressDetected) {
      showNotification('Nivelul de stres a crescut', 'Nivelul tău de stres a crescut considerabil. Apasă aici pentru a lua o pauză de relaxare.');
    }
  }

  static bool detectStress(List<HealthDataPoint> heartRateData) {
    // Calculam variabilitatea ritmului cardiac (HRV)

    double heartRateVariability = calculateHeartRateVariability(heartRateData);
    double limita = 3.0;

    return heartRateVariability < limita; // Returneaza true cand stresul este detectat
  }


  static double calculateHeartRateVariability(List<HealthDataPoint> heartRateData) {
    // Extragem intervalul RR din datele preluate prin API (batai pe secunda)
    List<double> rrIntervale = [];
    for (int i = 1; i < heartRateData.length; i++) {
      double rrInterval = heartRateData[i].dateFrom.difference(heartRateData[i - 1].dateFrom).inMilliseconds.toDouble();
      rrIntervale.add(rrInterval);
    }

    // HRV bazat pe intervalul RR
    // deviatia standard a intervalelor RR (SDNN)
    double average = rrIntervale.reduce((a, b) => a + b) / rrIntervale.length; //calculam media
    double variab = rrIntervale.map((interval) => (interval - average) * (interval - average)).reduce((a, b) => a + b) / rrIntervale.length;//facem diferenta dintre
    double sdnn = math.sqrt(variab);

    return sdnn;
  }

  static void showNotification(String title, String body) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_notification');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'hush',
      'Hush',
      channelDescription: 'notification channel',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Colors.blue,
      colorized: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}