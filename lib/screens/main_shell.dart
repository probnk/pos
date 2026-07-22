import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../data/data_store.dart';
import '../widgets/sidebar.dart';
import 'inventory_page.dart';
import 'billing_page.dart';
import 'invoice_history_page.dart';

// ─── MAIN SHELL ───────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final ThemeProvider tp;
  const MainShell({super.key, required this.tp});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _page = 0;
  final store = DataStore();

  @override
  void initState() {
    super.initState();
    widget.tp.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.tp.pageBg,
      body: Row(children: [
        Sidebar(page: _page, tp: widget.tp, onNav: (i) => setState(() => _page = i)),
        Expanded(child: _buildPage()),
      ]),
    );
  }

  Widget _buildPage() {
    switch (_page) {
      case 0: return InventoryPage(store: store, tp: widget.tp);
      case 1: return BillingPage(store: store, tp: widget.tp);
      case 2: return InvoiceHistoryPage(store: store, tp: widget.tp);
      default: return InventoryPage(store: store, tp: widget.tp);
    }
  }
}
