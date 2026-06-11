## 0.1.0

* Initial release.
* Analyzes `pubspec.lock` for WASM compatibility using the pub.dev REST API.
* Three compatibility states: COMPATIBLE, INCOMPATIBLE, UNKNOWN.
* Distinguishes direct vs. transitive blockers.
* `--json` flag for machine-readable output.
* `--exit-code` flag for CI pipeline gating.
* `--direct-only` flag to skip transitive dependency analysis.
* `--verbose` flag to show all packages including compatible and unknown.