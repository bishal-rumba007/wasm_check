import 'wasm_compatibility.dart';

/// Whether a dependency was explicitly listed in pubspec.yaml
/// or pulled in by another package.
enum DependencyKind {
  directMain, // under `dependencies:` in pubspec.yaml
  directDev, // under `dev_dependencies:` in pubspec.yaml
  transitive, // pulled in by another package
}

/// A hosted pub.dev package that was analyzed for WASM compatibility.
class DependencyReport {
  const DependencyReport({
    required this.name,
    required this.version,
    required this.kind,
    required this.compatibility,
  });

  final String name;
  final String version;
  final DependencyKind kind;
  final WasmCompatibility compatibility;
}
