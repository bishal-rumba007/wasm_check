/// The WASM compatibility status of a pub.dev package.
///
/// Use exhaustive pattern matching to handle all three states:
///
/// ```dart
/// switch (dep.compatibility) {
///   Compatible(:final signal) => print('✓ $signal'),
///   Incompatible(:final reason) => print('✗ $reason'),
///   Unknown() => print('? could not be determined'),
/// }
/// ```
sealed class WasmCompatibility {
  const WasmCompatibility();
}

/// The package is confirmed WASM-compatible.
///
/// [signal] describes what positive indicator was found
/// (e.g. `'has wasm topic tag on pub.dev'`).
final class Compatible extends WasmCompatibility {
  /// Creates a [Compatible] status with the given [signal].
  const Compatible({required this.signal});

  /// A human-readable description of why this package was deemed compatible.
  final String signal;
}

/// The package is confirmed WASM-incompatible.
///
/// [reason] describes why typically a dependency on `package:js`,
/// which uses legacy JS interop that does not compile to WASM.
final class Incompatible extends WasmCompatibility {
  /// Creates an [Incompatible] status with the given [reason].
  const Incompatible({required this.reason});

  /// A human readable description of why this package blocks WASM compilation.
  final String reason;
}

/// WASM compatibility could not be determined from available signals.
///
/// This does not mean the package is incompatible, it means the pub.dev
/// API did not provide enough information to make a determination.
/// Some packages in this state may use `dart:html` directly, which is
/// also WASM-incompatible but undetectable via pubspec dependencies.
final class Unknown extends WasmCompatibility {
  /// Creates an [Unknown] status.
  const Unknown();
}
