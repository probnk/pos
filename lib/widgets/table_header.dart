import 'package:flutter/material.dart';

class TableHeader extends StatelessWidget {
  final String text;
  const TableHeader(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12));
}
