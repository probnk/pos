import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import 'main_shell.dart';

// ─── APP ROOT ─────────────────────────────────────────────────────────────────

class CosmeticPOSApp extends StatefulWidget {
  final bool initialDark;
  const CosmeticPOSApp({super.key, required this.initialDark});
  @override
  State<CosmeticPOSApp> createState() => _CosmeticPOSAppState();
}

class _CosmeticPOSAppState extends State<CosmeticPOSApp> {
  late ThemeProvider _tp;

  @override
  void initState() {
    super.initState();
    _tp = ThemeProvider(widget.initialDark);
    _tp.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tp.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cosmetic Store POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: ThemeProvider.accent,
          brightness: _tp.isDark ? Brightness.dark : Brightness.light,
        ),
        scaffoldBackgroundColor: _tp.pageBg,
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      home: MainShell(tp: _tp),
    );
  }
}
