import 'dart:io';

import 'package:yaml/yaml.dart';

import '../models/dependency_report.dart';
import '../models/raw_dependency.dart';

/// Parses pubspec.lock into a flat list of [RawDependency].
class LockfileParser {
  /// Reads pubspec.lock from [projectPath] and parses it.
  ///
  /// Throws [FileSystemException] if pubspec.lock does not exist.
  static List<RawDependency> parse(String projectPath) {
    final lockfile = File('$projectPath/pubspec.lock');
    if (!lockfile.existsSync()) {
      throw FileSystemException(
        'pubspec.lock not found. Run `dart pub get` first.',
        lockfile.path,
      );
    }
    return parseContent(lockfile.readAsStringSync());
  }

  /// Parses the YAML [content] of a pubspec.lock directly.
  ///
  /// Exposed separately so tests can pass fixture strings
  /// without touching the filesystem.
  static List<RawDependency> parseContent(String content) {
    final doc = loadYaml(content);
    if (doc is! YamlMap) return [];

    final packages = doc['packages'];
    if (packages is! YamlMap) return [];

    final result = <RawDependency>[];

    for (final entry in packages.entries) {
      final name = entry.key as String;
      final data = entry.value;
      if (data is! YamlMap) continue;

      final source = data['source'] as String? ?? 'hosted';
      final version = data['version'] as String? ?? '0.0.0';
      final depField = data['dependency'] as String? ?? 'transitive';

      final kind = switch (depField) {
        'direct main' => DependencyKind.directMain,
        'direct dev' => DependencyKind.directDev,
        _ => DependencyKind.transitive,
      };

      result.add(RawDependency(
        name: name,
        version: version,
        kind: kind,
        source: source,
      ));
    }

    return result;
  }
}
