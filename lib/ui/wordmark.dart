import 'package:flutter/material.dart';

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      'assets/brand/pendi-wordmark-${dark ? 'dark' : 'light'}.png',
      height: height,
      semanticLabel: 'Pendi',
      filterQuality: FilterQuality.medium,
    );
  }
}
