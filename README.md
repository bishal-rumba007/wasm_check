# wasm_check

Pre-flight WASM compatibility audit for Dart and Flutter projects.

Checks your entire dependency tree *before* you build — identifying which packages
will block `flutter build web --wasm` before you spend time waiting for a failed compile.

## Install

```bash
dart pub global activate wasm_check
```

## Usage

```bash
# Analyze the current directory
wasm_check

# Analyze a specific project
wasm_check --path /path/to/your/project

# Show all packages (not just blockers)
wasm_check --verbose

# Machine-readable output for CI pipelines
wasm_check --json

# Exit with code 1 if any blockers found (for CI gating)
wasm_check --exit-code

# Only check direct dependencies (skip transitive)
wasm_check --direct-only
```

### Example output

```
──────────────────────────────────────────────────────────────
  wasm_check  ·  42 packages  ·  2.8s
──────────────────────────────────────────────────────────────

BLOCKERS (2)
  ✗  flutter_secure_storage_web  1.2.1     [direct]
       └─ depends on package:js (legacy JS interop — not supported in WASM)
  ✗  mapbox_gl                   0.16.0    [transitive]
       └─ depends on package:js (legacy JS interop — not supported in WASM)

COMPATIBLE (32)
  ✓  32 packages confirmed WASM-compatible.
     Run with --verbose to list them.

UNKNOWN (8)
  ?  8 packages could not be verified.
     Run with --verbose to list them.
     Some may use dart:html directly (undetectable via pub.dev API).

──────────────────────────────────────────────────────────────
  ✗  BLOCKED — 2 blockers found
     · 1 direct — replace or upgrade to a WASM-compatible version.
     · 1 transitive — owned by upstream packages; find alternatives.
──────────────────────────────────────────────────────────────
```

## Understanding the output

| Status | Meaning |
|---|---|
| **BLOCKER** | Confirmed WASM-incompatible. Depends on `package:js` (legacy JS interop). |
| **COMPATIBLE** | Confirmed WASM-compatible. Has `wasm` topic tag or uses `package:web`. |
| **UNKNOWN** | No compatibility signal found. May be fine, or may use `dart:html` directly. |

**Direct vs. transitive blockers matter.** Direct blockers are packages you listed in
your `pubspec.yaml` — you can upgrade or replace them. Transitive blockers are owned
by upstream packages; file issues with those maintainers or find alternatives.

## CI integration

```yaml
# .github/workflows/wasm_check.yml
- name: Install wasm_check
  run: dart pub global activate wasm_check

- name: Check WASM compatibility
  run: wasm_check --exit-code --path .
```

With `--json`, you can parse the output in CI scripts:

```bash
wasm_check --json | jq '.summary.blockers'
```

## Library usage

```dart
import 'package:wasm_check/wasm_check.dart';

Future<void> main() async {
  final report = await WasmAudit.analyze(projectPath: '.');

  print('Blockers: ${report.blockers.length}');
  print('Can proceed: ${report.canProceed}');

  for (final dep in report.blockers) {
    final reason = switch (dep.compatibility) {
      Incompatible(:final reason) => reason,
      _ => 'unknown reason',
    };
    print('${dep.name} ${dep.version}: $reason');
  }
}
```

## How detection works

`wasm_check` queries the [pub.dev REST API](https://pub.dev/help/api) for each
hosted package in your `pubspec.lock` and checks two signals:

**Compatible** if the package:
- Has the `wasm` topic tag on pub.dev, **or**
- Lists `package:web` as a dependency (the WASM-compatible interop library)

**Incompatible** if the package:
- Lists `package:js` as a dependency (the legacy interop library that doesn't compile to WASM)

**Unknown** if neither signal is present.

## Known limitations

- Packages that use `dart:html` *directly* (without `package:js`) will appear as
  **UNKNOWN** rather than **INCOMPATIBLE**. `dart:html` is a Dart SDK library and
  doesn't appear in a package's `pubspec.yaml` dependencies.
- Dev dependencies (`dev_dependencies:`) are not analyzed — they don't compile
  into WASM output.
- `sdk`, `path`, and `git` dependencies are skipped.
- Detection accuracy depends on pub.dev package authors correctly tagging their
  packages and migrating to `package:web`.