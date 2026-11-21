import 'package:flutter/material.dart';

/// Shows [builder] once a deferred library has loaded (splits web bundles;
/// a no-op on Android).
class Deferred extends StatelessWidget {
  const Deferred(this.load, this.builder, {super.key});

  final Future<void> Function() load;
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: load(),
      builder: (context, snap) => snap.connectionState == ConnectionState.done
          ? builder()
          : const Scaffold(body: LinearProgressIndicator()),
    );
  }
}
