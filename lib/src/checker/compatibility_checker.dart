import 'dart:math';

import '../client/pub_api_client.dart';
import '../models/audit_report.dart';
import '../models/dependency_report.dart';
import '../models/raw_dependency.dart';
import '../models/wasm_compatibility.dart';
import '../resolver/lockfile_parser.dart';

/// Analyzes a Dart/Flutter project's dependency tree for WASM compatibility.
class WasmAudit {
  WasmAudit._();

  /// Analyzes the project at [projectPath] and returns an [AuditReport].
  ///
  /// - Skips sdk, path, and git dependencies (not on pub.dev).
  /// - Skips dev dependencies (they don't compile into WASM output).
  /// - When [directOnly] is true, also skips transitive dependencies.
  /// - Processes up to [concurrency] pub.dev API calls simultaneously.
  static Future<AuditReport> analyze({
    required String projectPath,
    bool directOnly = false,
    int concurrency = 10,
  }) async {
    final stopwatch = Stopwatch()..start();
    final client = PubApiClient();

    try {
      final rawDeps = LockfileParser.parse(projectPath);

      final toCheck = rawDeps
          .where((d) => d.isHosted)
          .where((d) => d.kind != DependencyKind.directDev)
          .where((d) => !directOnly || d.kind != DependencyKind.transitive)
          .toList();

      final reports = <DependencyReport>[];

      for (var i = 0; i < toCheck.length; i += concurrency) {
        final end = min(i + concurrency, toCheck.length);
        final batch = toCheck.sublist(i, end);

        final batchResults = await Future.wait(
          batch.map((dep) => _checkOne(dep, client)),
        );
        reports.addAll(batchResults);
      }

      stopwatch.stop();
      return AuditReport(
        dependencies: reports,
        analysisTime: stopwatch.elapsed,
      );
    } finally {
      client.close();
    }
  }

  static Future<DependencyReport> _checkOne(
    RawDependency dep,
    PubApiClient client,
  ) async {
    final pubspec = await client.fetchPubspec(dep.name, dep.version);

    return DependencyReport(
      name: dep.name,
      version: dep.version,
      kind: dep.kind,
      compatibility:
          pubspec == null ? const Unknown() : checkCompatibility(pubspec),
    );
  }
}

/// Determines WASM compatibility from a package's pubspec map.
///
/// Option C detection logic:
/// - COMPATIBLE  if topics contains 'wasm'
/// - COMPATIBLE  if dependencies contains 'web' (package:web)
/// - INCOMPATIBLE if dependencies contains 'js' (package:js)
/// - UNKNOWN     otherwise
///
/// Exposed at package-internal level (no underscore) so tests can
/// import it directly without going through the pub.dev API.
WasmCompatibility checkCompatibility(Map<String, dynamic> pubspec) {
  // Positive signal 1 — explicit wasm topic tag
  final rawTopics = pubspec['topics'];
  if (rawTopics is List) {
    if (rawTopics.contains('wasm')) {
      return const Compatible(signal: 'has wasm topic tag on pub.dev');
    }
  }

  // Extract dependency keys from the pubspec map
  final depKeys = <String>{};
  final rawDeps = pubspec['dependencies'];
  if (rawDeps is Map) {
    depKeys.addAll(rawDeps.keys.whereType<String>());
  }

  // Positive signal 2 — depends on package:web (the WASM-compatible interop lib)
  if (depKeys.contains('web')) {
    return const Compatible(
      signal: 'uses package:web (WASM-compatible JS interop)',
    );
  }

  // Negative signal — depends on package:js (legacy interop, WASM-incompatible)
  if (depKeys.contains('js')) {
    return const Incompatible(
      reason:
          'depends on package:js (legacy JS interop — not supported in WASM)',
    );
  }

  return const Unknown();
}
