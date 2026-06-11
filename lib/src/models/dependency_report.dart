import 'wasm_compatibility.dart';

/// Whether a package was directly listed in pubspec.yaml
/// or pulled in as a dependency of another package.
enum DependencyKind {
  /// Listed under `dependencies:` in pubspec.yaml.
  /// You own this dependency directly and can upgrade or replace it.
  directMain,

  /// Listed under `dev_dependencies:` in pubspec.yaml.
  /// Not compiled into the app's WASM output.
  directDev,

  /// Pulled in by another package, not listed in your pubspec.yaml.
  /// To resolve a transitive blocker, upgrade the package that pulls it in,
  /// or find an alternative that doesn't depend on it.
  transitive,
}

/// A hosted pub.dev package from your dependency tree,
/// along with its WASM compatibility status.
class DependencyReport {
  /// Creates a [DependencyReport].
  const DependencyReport({
    required this.name,
    required this.version,
    required this.kind,
    required this.compatibility,
  });

  /// The package name as it appears on pub.dev.
  final String name;

  /// The resolved version string from pubspec.lock.
  final String version;

  /// Whether this package is a direct or transitive dependency.
  final DependencyKind kind;

  /// The WASM compatibility status determined from the pub.dev API.
  ///
  /// Will be one of [Compatible], [Incompatible], or [Unknown].
  final WasmCompatibility compatibility;
}
