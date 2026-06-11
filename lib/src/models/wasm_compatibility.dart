sealed class WasmCompatibility {
  const WasmCompatibility();
}

final class Compatible extends WasmCompatibility {
  const Compatible({required this.signal});
  final String signal;
}

final class Incompatible extends WasmCompatibility {
  const Incompatible({required this.reason});
  final String reason;
}

final class Unknown extends WasmCompatibility {
  const Unknown();
}
