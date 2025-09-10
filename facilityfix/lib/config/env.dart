// lib/config/env.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

enum AppRole { tenant, staff, admin }

class AppEnv {
  static AppRole role = AppRole.tenant;

  // I already change
  static const _WEB_API = 'http://10.243.215.130:8000'; 

  static const Map<AppRole, String> _webHosts = {
    AppRole.tenant: _WEB_API,
    AppRole.staff:  _WEB_API,
    AppRole.admin:  _WEB_API,
  };

  static const Map<AppRole, String> _androidEmuHosts = {
    AppRole.tenant: 'http://10.0.2.2:8000',
    AppRole.staff:  'http://10.0.2.2:8000',
    AppRole.admin:  'http://10.0.2.2:8000',
  };

  static const Map<AppRole, String> _iosSimHosts = {
    AppRole.tenant: 'http://127.0.0.1:8000',
    AppRole.staff:  'http://127.0.0.1:8000',
    AppRole.admin:  'http://127.0.0.1:8000',
  };

  static const String _lanHost = _WEB_API; // fallback

  static String resolveBaseUrl({AppRole? overrideRole}) {
    final r = overrideRole ?? role;
    if (kIsWeb) return _webHosts[r]!;
    if (Platform.isAndroid) return _androidEmuHosts[r]!;
    if (Platform.isIOS) return _iosSimHosts[r]!;
    return _lanHost;
  }
}
