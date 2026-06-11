// ignore_for_file: avoid_print

import 'package:wasm_check/wasm_check.dart';

/// Demonstrates wasm_check as a library.
///
/// Run from your project root:
/// ```
/// dart run example/example.dart
/// ```
Future<void> main() async {
  print('Running WASM compatibility audit on current project...\n');

  final report = await WasmAudit.analyze(
    projectPath: '.',
    directOnly: false,
  );

  // Use exhaustive pattern matching — the compiler ensures you handle
  // all three states: Compatible, Incompatible, Unknown.
  for (final dep in report.dependencies) {
    final status = switch (dep.compatibility) {
      Compatible(:final signal) => '✓  $signal',
      Incompatible(:final reason) => '✗  $reason',
      Unknown() => '?  no compatibility signal found',
    };
    print('${dep.name} ${dep.version} — $status');
  }

  print('\n--- Summary ---');
  print('Packages analyzed : ${report.dependencies.length}');
  print('Blockers          : ${report.blockers.length}');
  print('  Direct          : ${report.directBlockers.length}');
  print('  Transitive      : ${report.transitiveBlockers.length}');
  print('Compatible        : ${report.compatible.length}');
  print('Unknown           : ${report.unknowns.length}');
  print('Analysis time     : ${report.analysisTime.inMilliseconds}ms');
  print('');

  if (report.canProceed) {
    print('✓ READY — no blockers found. Safe to build with --wasm.');
  } else {
    print('✗ BLOCKED — ${report.blockers.length} package(s) prevent WASM.');
    print('');

    if (report.directBlockers.isNotEmpty) {
      print('Direct blockers (you can fix these):');
      for (final dep in report.directBlockers) {
        print('  ${dep.name} ${dep.version}');
      }
    }

    if (report.transitiveBlockers.isNotEmpty) {
      print('Transitive blockers (owned by upstream):');
      for (final dep in report.transitiveBlockers) {
        print('  ${dep.name} ${dep.version}');
      }
    }
  }
}
