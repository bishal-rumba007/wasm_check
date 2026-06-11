import 'dependency_report.dart';
import 'wasm_compatibility.dart';

/// The complete result of a WASM compatibility analysis.
class AuditReport {
  const AuditReport({
    required this.dependencies,
    required this.analysisTime,
  });

  /// All hosted packages that were analyzed.
  /// Does not include sdk, path, or git dependencies.
  final List<DependencyReport> dependencies;

  /// How long the analysis took, including all pub.dev API calls.
  final Duration analysisTime;

  /// Packages confirmed to be WASM-incompatible.
  List<DependencyReport> get blockers =>
      dependencies.where((d) => d.compatibility is Incompatible).toList();

  /// Blockers that are direct (non-dev) dependencies — you can
  /// upgrade or replace these directly.
  List<DependencyReport> get directBlockers =>
      blockers.where((d) => d.kind == DependencyKind.directMain).toList();

  /// Blockers that are transitive — owned by upstream packages.
  List<DependencyReport> get transitiveBlockers =>
      blockers.where((d) => d.kind == DependencyKind.transitive).toList();

  /// Packages where compatibility could not be determined.
  List<DependencyReport> get unknowns =>
      dependencies.where((d) => d.compatibility is Unknown).toList();

  /// Packages confirmed to be WASM-compatible.
  List<DependencyReport> get compatible =>
      dependencies.where((d) => d.compatibility is Compatible).toList();

  /// True only if zero INCOMPATIBLE packages were found.
  bool get canProceed => blockers.isEmpty;
}
