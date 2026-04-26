import 'package:flutter/material.dart';

class PageWrapper extends StatelessWidget {
  final Widget child;

  const PageWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(20), child: child);
  }
}
