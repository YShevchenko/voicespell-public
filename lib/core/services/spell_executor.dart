import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service to execute spell actions
class SpellExecutor {
  static final SpellExecutor instance = SpellExecutor._();
  SpellExecutor._();

  bool _flashlightOn = false;

  Future<bool> executeSpell(String actionType, String? actionParams) async {
    try {
      switch (actionType) {
        case 'FLASHLIGHT_TOGGLE':
          return await _toggleFlashlight();

        case 'DARK_MODE':
          // Dark mode would require platform-specific code
          // For now, just return success
          return true;

        case 'TIMER_START':
          if (actionParams != null) {
            final params = jsonDecode(actionParams);
            final duration = params['duration'] as int;
            return await _startTimer(duration);
          }
          return false;

        case 'OPEN_APP':
          if (actionParams != null) {
            final params = jsonDecode(actionParams);
            final app = params['app'] as String;
            return await _openApp(app);
          }
          return false;

        case 'BRIGHTNESS_MAX':
          // Brightness control requires platform-specific code
          return true;

        case 'BRIGHTNESS_MIN':
          // Brightness control requires platform-specific code
          return true;

        default:
          return false;
      }
    } catch (e) {
      print('Error executing spell: $e');
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
    } catch (e) {
      print('Error toggling flashlight: $e');
      return false;
    }
  }

  Future<bool> _startTimer(int durationSeconds) async {
    try {
      // Open clock app with timer
      final url = Uri.parse('clock://timer?duration=$durationSeconds');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        return true;
      }
      return false;
    } catch (e) {
      print('Error starting timer: $e');
      return false;
    }
  }

  Future<bool> _openApp(String appName) async {
    try {
      String scheme;
      switch (appName) {
        case 'camera':
          scheme = 'camera://';
          break;
        case 'music':
          scheme = 'music://';
          break;
        case 'messages':
          scheme = 'sms://';
          break;
        case 'maps':
          scheme = 'maps://';
          break;
        case 'phone':
          scheme = 'tel://';
          break;
        case 'calendar':
          scheme = 'calshow://';
          break;
        case 'notes':
          scheme = 'mobilenotes://';
          break;
        case 'browser':
          scheme = 'http://';
          break;
        case 'settings':
          scheme = 'app-settings://';
          break;
        case 'photos':
          scheme = 'photos-redirect://';
          break;
        case 'clock':
          scheme = 'clock://';
          break;
        case 'weather':
          scheme = 'weather://';
          break;
        case 'contacts':
          scheme = 'contacts://';
          break;
        case 'wallet':
          scheme = 'shoebox://';
          break;
        case 'files':
          scheme = 'shareddocuments://';
          break;
        case 'mail':
          scheme = 'mailto://';
          break;
        default:
          return false;
      }

      final url = Uri.parse(scheme);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      print('Error opening app: $e');
      return false;
    }
  }
}
