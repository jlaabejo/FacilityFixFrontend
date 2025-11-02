import 'package:flutter_test/flutter_test.dart';
import 'package:facilityfix/config/env.dart';

void main() {
  group('AppEnv', () {
    group('baseUrlFor', () {
      test('returns valid URL for all roles', () {
        for (final role in AppRole.values) {
          final url = AppEnv.baseUrlFor(role);
          expect(url, isNotEmpty);
          expect(url, startsWith('http'));
        }
      });
    });

    group('baseUrlWithLan', () {
      test('returns baseUrlFor when lanIp is null', () {
        final originalLanIp = AppEnv.lanIp;
        AppEnv.lanIp = null;
        
        for (final role in AppRole.values) {
          final withLan = AppEnv.baseUrlWithLan(role);
          final without = AppEnv.baseUrlFor(role);
          expect(withLan, equals(without));
        }
        
        AppEnv.lanIp = originalLanIp;
      });

      test('returns baseUrlFor when lanIp is empty', () {
        final originalLanIp = AppEnv.lanIp;
        AppEnv.lanIp = '';
        
        for (final role in AppRole.values) {
          final withLan = AppEnv.baseUrlWithLan(role);
          final without = AppEnv.baseUrlFor(role);
          expect(withLan, equals(without));
        }
        
        AppEnv.lanIp = originalLanIp;
      });

      test('uses LAN IP when set', () {
        final originalLanIp = AppEnv.lanIp;
        AppEnv.lanIp = '192.168.1.100';
        
        for (final role in AppRole.values) {
          final url = AppEnv.baseUrlWithLan(role);
          expect(url, contains('192.168.1.100'));
        }
        
        AppEnv.lanIp = originalLanIp;
      });
    });

    group('AppRole enum', () {
      test('has exactly three roles', () {
        expect(AppRole.values.length, 3);
      });

      test('contains expected roles', () {
        expect(AppRole.values, contains(AppRole.tenant));
        expect(AppRole.values, contains(AppRole.staff));
        expect(AppRole.values, contains(AppRole.admin));
      });
    });
  });
}