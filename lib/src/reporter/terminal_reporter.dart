import 'dart:io';

import '../models/audit_report.dart';
import '../models/dependency_report.dart';
import '../models/wasm_compatibility.dart';

/// Writes a human-readable WASM audit report to stdout.
class TerminalReporter {
  const TerminalReporter({this.verbose = false});

  final bool verbose;

  static final String _divider = ''.padLeft(76, '─');
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _reset = '\x1B[0m';

  bool get _useColor => stdout.hasTerminal;

  void report(AuditReport report) {
    _line(_divider);
    _line(
      '  wasm_check  ·  ${report.dependencies.length} packages  ·  '
      '${_formatDuration(report.analysisTime)}',
    );
    _line(_divider);
    _blank();

    _writeBlockers(report.blockers);
    _blank();
    _writeCompatible(report.compatible);
    _blank();
    _writeUnknowns(report.unknowns);
    _blank();

    _line(_divider);
    _writeSummary(report);
    _line(_divider);
  }

  void _writeBlockers(List<DependencyReport> blockers) {
    final header = 'BLOCKERS (${blockers.length})';
    stdout.writeln(blockers.isEmpty ? header : _c(header, _red));

    if (blockers.isEmpty) {
      _line('  ✓  No blockers found.');
      return;
    }

    for (final dep in blockers) {
      final nameVer = '${dep.name}  ${dep.version}'.padRight(52);
      _line('  ✗  $nameVer  [${_kindLabel(dep.kind)}]');
      if (dep.compatibility case Incompatible(:final reason)) {
        _line('       └─ $reason');
      }
    }
  }

  void _writeCompatible(List<DependencyReport> compatible) {
    _line('COMPATIBLE (${compatible.length})');

    if (compatible.isEmpty) {
      _line('  No confirmed WASM-compatible packages.');
    } else if (verbose) {
      for (final dep in compatible) {
        final nameVer = '${dep.name}  ${dep.version}'.padRight(52);
        _line('  ✓  $nameVer  [${_kindLabel(dep.kind)}]');
        if (dep.compatibility case Compatible(:final signal)) {
          _line('       └─ $signal');
        }
      }
    } else {
      _line('  ✓  ${compatible.length} packages confirmed WASM-compatible.');
      _line('     Run with --verbose to list them.');
    }
  }

  void _writeUnknowns(List<DependencyReport> unknowns) {
    _line('UNKNOWN (${unknowns.length})');

    if (unknowns.isEmpty) {
      _line('  ✓  All packages have a known compatibility signal.');
    } else if (verbose) {
      for (final dep in unknowns) {
        final nameVer = '${dep.name}  ${dep.version}'.padRight(52);
        _line('  ?  $nameVer  [${_kindLabel(dep.kind)}]');
      }
      _blank();
      _line(
        '     Note: some unknowns may use dart:html directly,\n'
        '     which is undetectable via pubspec dependencies alone.',
      );
    } else {
      _line('  ?  ${unknowns.length} packages could not be verified.');
      _line('     Run with --verbose to list them.');
      _line(
          '     Some may use dart:html directly (undetectable via pub.dev API).');
    }
  }

  void _writeSummary(AuditReport report) {
    if (report.canProceed) {
      _line('  ${_c("✓  READY — no blockers found.", _green)}');
    } else {
      final b = report.blockers.length;
      _line(
          '  ${_c("✗  BLOCKED — $b blocker${b == 1 ? "" : "s"} found.", _red)}');

      final direct = report.directBlockers;
      final transitive = report.transitiveBlockers;

      if (direct.isNotEmpty) {
        _line(
          '     · ${direct.length} direct — '
          'replace or upgrade to a WASM-compatible version.',
        );
      }
      if (transitive.isNotEmpty) {
        _line(
          '     · ${transitive.length} transitive — '
          'owned by upstream packages; find alternatives.',
        );
      }
    }
  }

  void _line(String text) => stdout.writeln(text);
  void _blank() => stdout.writeln();

  String _c(String text, String code) => _useColor ? '$code$text$_reset' : text;

  String _kindLabel(DependencyKind kind) => switch (kind) {
        DependencyKind.directMain => 'direct',
        DependencyKind.directDev => 'dev',
        DependencyKind.transitive => 'transitive',
      };

  String _formatDuration(Duration d) => d.inMilliseconds < 1000
      ? '${d.inMilliseconds}ms'
      : '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
}
