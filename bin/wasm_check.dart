import 'dart:io';

import 'package:args/args.dart';
import 'package:wasm_check/wasm_check.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      help: 'Path to the Dart/Flutter project (defaults to current directory).',
      defaultsTo: '.',
    )
    ..addFlag(
      'json',
      help: 'Output results as JSON.',
      negatable: false,
    )
    ..addFlag(
      'direct-only',
      help: 'Only analyze direct dependencies; skip transitive.',
      negatable: false,
    )
    ..addFlag(
      'exit-code',
      help: 'Exit with code 1 if any blockers are found (for CI gating).',
      negatable: false,
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show all packages including compatible and unknown.',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show usage information.',
      negatable: false,
    );

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln('Run wasm_check --help for usage.');
    exit(64); // EX_USAGE
  }

  if (results['help'] as bool) {
    stdout
      ..writeln(
          'Audit your Dart/Flutter dependency tree for WASM compatibility.\n')
      ..writeln('Usage: wasm_check [options]\n')
      ..writeln(parser.usage);
    exit(0);
  }

  final projectPath = results['path'] as String;
  final useJson = results['json'] as bool;
  final directOnly = results['direct-only'] as bool;
  final useExitCode = results['exit-code'] as bool;
  final verbose = results['verbose'] as bool;

  try {
    final report = await WasmAudit.analyze(
      projectPath: projectPath,
      directOnly: directOnly,
    );

    if (useJson) {
      const JsonReporter().report(report);
    } else {
      TerminalReporter(verbose: verbose).report(report);
    }

    if (useExitCode && !report.canProceed) {
      exit(1);
    }
  } on FileSystemException catch (e) {
    stderr.writeln('Error: ${e.message}');
    if (e.path != null) stderr.writeln('  at: ${e.path}');
    exit(1);
  } catch (e, stack) {
    stderr.writeln('Unexpected error: $e');
    stderr.writeln(stack.toString());
    exit(1);
  }
}
