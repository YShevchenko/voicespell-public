import 'dart:async';
import 'package:torch_light/torch_light.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:volume_controller/volume_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/spell.dart';

/// Executes spell actions on the device.
class SpellExecutor {
  static final SpellExecutor instance = SpellExecutor._();
  SpellExecutor._();

  bool _flashlightOn = false;
  bool _isMuted = false;
  double _volumeBeforeMute = 0.5;
  bool _tzInitialized = false;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  final VolumeController _volume = VolumeController();

  Future<void> _ensureTzInitialized() async {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  Future<void> initNotifications() async {
    if (_notificationsInitialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
    _notificationsInitialized = true;
  }

  Future<bool> execute(Spell spell) async {
    try {
      switch (spell.actionType) {
        case SpellAction.toggleFlashlight:
          return _toggleFlashlight();

        case SpellAction.revelio:
          return _revelio();

        case SpellAction.adjustBrightness:
          return _toggleBrightness();

        case SpellAction.setTimer:
          return _setTimer();

        case SpellAction.muteUnmute:
          return _toggleMute();

        case SpellAction.customIntent:
          if (spell.intentUrl != null && spell.intentUrl!.isNotEmpty) {
            return _launchUrl(spell.intentUrl!);
          }
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> _toggleFlashlight() async {
    try {
      if (_flashlightOn) {
        await TorchLight.disableTorch();
        _flashlightOn = false;
      } else {
        await TorchLight.enableTorch();
        _flashlightOn = true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Revelio: enable flashlight for 3 seconds then disable.
  Future<bool> _revelio() async {
    try {
      await TorchLight.enableTorch();
      await Future.delayed(const Duration(seconds: 3));
      await TorchLight.disableTorch();
      _flashlightOn = false;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Toggle brightness between 10% and 100%.
  Future<bool> _toggleBrightness() async {
    try {
      final current = await ScreenBrightness().current;
      if (current > 0.2) {
        await ScreenBrightness().setScreenBrightness(0.1);
      } else {
        await ScreenBrightness().setScreenBrightness(1.0);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Create a 5-minute countdown notification.
  Future<bool> _setTimer() async {
    try {
      await initNotifications();
      await _ensureTzInitialized();

      const androidDetails = AndroidNotificationDetails(
        'voicespell_timer',
        'VoiceSpell Timers',
        channelDescription: 'Countdown timer notifications from VoiceSpell',
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);

      // Show an immediate "timer started" notification
      await _notifications.show(
        1001,
        'Tempus — Timer Started',
        'Your 5-minute timer is running. You will be notified when it ends.',
        details,
      );

      // Schedule the end notification after 5 minutes using TZDateTime
      final now = tz.TZDateTime.now(tz.local);
      final endTime = now.add(const Duration(minutes: 5));

      await _notifications.zonedSchedule(
        1002,
        'Tempus — Timer Complete!',
        '5 minutes are up!',
        endTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Toggle mute/unmute system volume.
  Future<bool> _toggleMute() async {
    try {
      if (_isMuted) {
        _volume.setVolume(_volumeBeforeMute);
        _isMuted = false;
      } else {
        _volumeBeforeMute = await _volume.getVolume();
        _volume.setVolume(0.0);
        _isMuted = true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _launchUrl(String urlStr) async {
    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
