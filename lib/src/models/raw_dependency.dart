import 'dependency_report.dart';

/// A dependency as parsed directly from pubspec.lock,
/// before compatibility has been checked.
class RawDependency {
  const RawDependency({
    required this.name,
    required this.version,
    required this.kind,
    required this.source,
  });

  final String name;
  final String version;
  final DependencyKind kind;
  final String source; // 'hosted', 'sdk', 'path', or 'git'

  /// Only hosted packages can be queried against the pub.dev API.
  bool get isHosted => source == 'hosted';
}
