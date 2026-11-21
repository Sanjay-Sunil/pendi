import 'package:flutter/material.dart';

void main() {
  runApp(const PendiApp());
}

class PendiApp extends StatelessWidget {
  const PendiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Pendi',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('pendi'))),
    );
  }
}
