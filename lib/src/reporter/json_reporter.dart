import 'dart:convert';
import 'dart:io';

import '../models/audit_report.dart';
import '../models/dependency_report.dart';
import '../models/wasm_compatibility.dart';

/// Writes the audit report to stdout as structured JSON.
///
/// The schema is stable — suitable for CI pipelines and tooling.
class JsonReporter {
  const JsonReporter();

  void report(AuditReport report) {
    final output = {
      'analysisTimeMs': report.analysisTime.inMilliseconds,
      'canProceed': report.canProceed,
      'summary': {
        'total': report.dependencies.length,
        'blockers': report.blockers.length,
        'directBlockers': report.directBlockers.length,
        'transitiveBlockers': report.transitiveBlockers.length,
        'compatible': report.compatible.length,
        'unknown': report.unknowns.length,
      },
      'dependencies': report.dependencies.map(_depToMap).toList(),
    };

    stdout.writeln(const JsonEncoder.withIndent('  ').convert(output));
  }

  Map<String, dynamic> _depToMap(DependencyReport dep) {
    return {
      'name': dep.name,
      'version': dep.version,
      'kind': switch (dep.kind) {
        DependencyKind.directMain => 'direct_main',
        DependencyKind.directDev => 'direct_dev',
        DependencyKind.transitive => 'transitive',
      },
      'compatibility': switch (dep.compatibility) {
        Compatible(:final signal) => {
            'status': 'compatible',
            'signal': signal,
          },
        Incompatible(:final reason) => {
            'status': 'incompatible',
            'reason': reason,
          },
        Unknown() => {
            'status': 'unknown',
          },
      },
    };
  }
}
