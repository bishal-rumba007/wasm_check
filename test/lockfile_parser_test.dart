import 'package:test/test.dart';
import 'package:wasm_check/src/models/dependency_report.dart';
import 'package:wasm_check/src/resolver/lockfile_parser.dart';

void main() {
  group('LockfileParser.parseContent', () {
    test('parses a direct main dependency', () {
      const yaml = '''
packages:
  http:
    dependency: "direct main"
    description:
      name: http
      sha256: "abc"
      url: "https://pub.dev"
    source: hosted
    version: "1.2.1"
sdks:
  dart: ">=3.3.0 <4.0.0"
''';
      final deps = LockfileParser.parseContent(yaml);

      expect(deps, hasLength(1));
      expect(deps.first.name, 'http');
      expect(deps.first.version, '1.2.1');
      expect(deps.first.kind, DependencyKind.directMain);
      expect(deps.first.source, 'hosted');
      expect(deps.first.isHosted, isTrue);
    });

    test('parses a direct dev dependency', () {
      const yaml = '''
packages:
  lints:
    dependency: "direct dev"
    description:
      name: lints
      sha256: "def"
      url: "https://pub.dev"
    source: hosted
    version: "4.0.0"
sdks:
  dart: ">=3.3.0 <4.0.0"
''';
      final deps = LockfileParser.parseContent(yaml);

      expect(deps.first.kind, DependencyKind.directDev);
    });

    test('parses a transitive dependency', () {
      const yaml = '''
packages:
  meta:
    dependency: transitive
    description:
      name: meta
      sha256: "ghi"
      url: "https://pub.dev"
    source: hosted
    version: "1.14.0"
sdks:
  dart: ">=3.3.0 <4.0.0"
''';
      final deps = LockfileParser.parseContent(yaml);

      expect(deps.first.kind, DependencyKind.transitive);
    });

    test('marks sdk packages as non-hosted', () {
      const yaml = '''
packages:
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
sdks:
  dart: ">=3.3.0 <4.0.0"
  flutter: ">=3.22.0"
''';
      final deps = LockfileParser.parseContent(yaml);

      expect(deps.first.source, 'sdk');
      expect(deps.first.isHosted, isFalse);
    });

    test('handles multiple packages of different kinds', () {
      const yaml = '''
packages:
  http:
    dependency: "direct main"
    description:
      name: http
      sha256: "a"
      url: "https://pub.dev"
    source: hosted
    version: "1.2.1"
  test:
    dependency: "direct dev"
    description:
      name: test
      sha256: "b"
      url: "https://pub.dev"
    source: hosted
    version: "1.25.2"
  async:
    dependency: transitive
    description:
      name: async
      sha256: "c"
      url: "https://pub.dev"
    source: hosted
    version: "2.11.0"
sdks:
  dart: ">=3.3.0 <4.0.0"
''';
      final deps = LockfileParser.parseContent(yaml);

      expect(deps, hasLength(3));
      expect(
        deps.map((d) => d.kind),
        containsAll([
          DependencyKind.directMain,
          DependencyKind.directDev,
          DependencyKind.transitive,
        ]),
      );
    });

    test('returns empty list for empty packages section', () {
      const yaml = '''
packages:
sdks:
  dart: ">=3.3.0 <4.0.0"
''';
      final deps = LockfileParser.parseContent(yaml);
      expect(deps, isEmpty);
    });
  });
}
