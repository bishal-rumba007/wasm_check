import 'package:test/test.dart';
import 'package:wasm_check/src/checker/compatibility_checker.dart';
import 'package:wasm_check/src/models/wasm_compatibility.dart';

void main() {
  group('checkCompatibility', () {
    test('returns Compatible when topics contains wasm', () {
      final pubspec = {
        'topics': ['networking', 'wasm'],
        'dependencies': <String, dynamic>{},
      };

      final result = checkCompatibility(pubspec);
      expect(result, isA<Compatible>());
      expect((result as Compatible).signal, contains('wasm topic'));
    });

    test('returns Compatible when dependencies contains web (package:web)', () {
      final pubspec = {
        'topics': <String>[],
        'dependencies': {
          'web': '>=0.3.0 <2.0.0',
          'http_parser': '^4.0.0',
        },
      };

      final result = checkCompatibility(pubspec);
      expect(result, isA<Compatible>());
      expect((result as Compatible).signal, contains('package:web'));
    });

    test('returns Incompatible when dependencies contains js (package:js)', () {
      final pubspec = {
        'topics': <String>[],
        'dependencies': {
          'js': '^0.6.7',
          'meta': '^1.3.0',
        },
      };

      final result = checkCompatibility(pubspec);
      expect(result, isA<Incompatible>());
      expect((result as Incompatible).reason, contains('package:js'));
    });

    test('wasm topic takes precedence over js dependency', () {
      // Edge case: a package could theoretically have both.
      // The wasm topic is the stronger positive signal.
      final pubspec = {
        'topics': ['wasm'],
        'dependencies': {'js': '^0.6.7'},
      };

      final result = checkCompatibility(pubspec);
      expect(result, isA<Compatible>());
    });

    test('returns Unknown when no signal is present', () {
      final pubspec = {
        'topics': <String>['networking'],
        'dependencies': {
          'meta': '^1.3.0',
          'collection': '^1.18.0',
        },
      };

      final result = checkCompatibility(pubspec);
      expect(result, isA<Unknown>());
    });

    test('returns Unknown when topics and dependencies are absent', () {
      final pubspec = <String, dynamic>{};

      final result = checkCompatibility(pubspec);
      expect(result, isA<Unknown>());
    });

    test('handles null topics gracefully', () {
      final pubspec = {
        'topics': null,
        'dependencies': <String, dynamic>{},
      };

      expect(() => checkCompatibility(pubspec), returnsNormally);
    });
  });
}
