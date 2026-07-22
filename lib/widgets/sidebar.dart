import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

// ─── SIDEBAR ──────────────────────────────────────────────────────────────────

class Sidebar extends StatelessWidget {
  final int page;
  final ThemeProvider tp;
  final void Function(int) onNav;
  const Sidebar({required this.page, required this.tp, required this.onNav});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: ThemeProvider.sidebarBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.store, color: ThemeProvider.accent, size: 32),
            const SizedBox(height: 8),
            const Text('Cosmetic POS',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Store Manager', style: TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 32),
        _navItem(0, Icons.inventory_2, 'Inventory'),
        _navItem(1, Icons.point_of_sale, 'Sales / Billing'),
        _navItem(2, Icons.history, 'Invoice History'),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: tp.toggle,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(children: [
                Icon(tp.isDark ? Icons.light_mode : Icons.dark_mode,
                    color: tp.isDark ? const Color(0xFFFFD700) : Colors.white60, size: 18),
                const SizedBox(width: 10),
                Text(tp.isDark ? 'Light Mode' : 'Dark Mode',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final sel = page == index;
    return InkWell(
      onTap: () => onNav(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? ThemeProvider.accent.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(10),
          border: sel ? Border.all(color: ThemeProvider.accent.withOpacity(0.5)) : null,
        ),
        child: Row(children: [
          Icon(icon, color: sel ? ThemeProvider.accent : Colors.white54),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(
            color: sel ? Colors.white : Colors.white54,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
          )),
        ]),
      ),
    );
  }
}
