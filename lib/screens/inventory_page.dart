import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../data/data_store.dart';
import '../models/models.dart';
import '../widgets/product_dialog.dart';
import '../widgets/table_header.dart';

// ─── INVENTORY PAGE ───────────────────────────────────────────────────────────

class InventoryPage extends StatefulWidget {
  final DataStore store;
  final ThemeProvider tp;
  const InventoryPage({super.key, required this.store, required this.tp});
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _search = '';
  final _scanCtrl = TextEditingController();
  final _scanFocus = FocusNode();
  ThemeProvider get tp => widget.tp;

  @override
  void initState() {
    super.initState();
    tp.addListener(() { if (mounted) setState(() {}); });
    widget.store.version.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _scanCtrl.dispose(); _scanFocus.dispose(); super.dispose(); }

  List<Product> get filtered {
    final q = _search.toLowerCase();
    return widget.store.products.where((p) =>
    p.name.toLowerCase().contains(q) ||
        p.barcode.contains(q) ||
        p.price.toString().contains(q)).toList();
  }

  void _handleInventoryScan(String input) {
    final t = input.trim();
    if (t.isEmpty) return;
    _scanCtrl.clear();
    final existing = widget.store.findByBarcode(t);
    _openDialog(existing, prefillBarcode: existing == null ? t : null);
    _scanFocus.requestFocus();
  }

  void _openDialog(Product? existing, {String? prefillBarcode}) {
    showDialog(
      context: context,
      builder: (_) => ProductDialog(
        existing: existing, prefillBarcode: prefillBarcode, tp: tp,
        onSave: (p) async {
          if (existing == null) await widget.store.addProduct(p);
          else await widget.store.updateProduct(p);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tp.pageBg,
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Inventory', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: tp.textPrimary)),
            Text('Manage products, prices & stock', style: TextStyle(fontSize: 12, color: tp.textSecondary)),
          ]),
          const Spacer(),
          FilledButton.icon(
            icon: const Icon(Icons.add), label: const Text('Add Product'),
            onPressed: () => _openDialog(null),
            style: FilledButton.styleFrom(backgroundColor: ThemeProvider.accent),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _scanCtrl, focusNode: _scanFocus,
              style: TextStyle(color: tp.textPrimary),
              decoration: InputDecoration(
                hintText: 'Scan barcode → auto-fill  |  Type name to search',
                hintStyle: TextStyle(color: tp.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.qr_code_scanner, color: ThemeProvider.accent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: ThemeProvider.accent, width: 1.5)),
                filled: true, fillColor: tp.inputFill,
              ),
              onSubmitted: _handleInventoryScan,
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.qr_code_scanner), label: const Text('Scan'),
            onPressed: () => _handleInventoryScan(_scanCtrl.text),
            style: FilledButton.styleFrom(backgroundColor: ThemeProvider.accent),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _statCard('Total Products', '${widget.store.products.length}', Icons.category),
          const SizedBox(width: 12),
          _statCard('Low Stock (<5)',
              '${widget.store.products.where((p) => p.stock > 0 && p.stock < 5).length}',
              Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 12),
          _statCard('Out of Stock',
              '${widget.store.products.where((p) => p.stock == 0).length}',
              Icons.remove_shopping_cart, color: Colors.red),
        ]),
        const SizedBox(height: 14),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: tp.cardBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tp.borderColor)),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(color: Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                child: const Row(children: [
                  Expanded(flex: 3, child: TableHeader('Product Name')),
                  Expanded(flex: 2, child: TableHeader('Barcode')),
                  Expanded(flex: 1, child: TableHeader('Price (Rs)')),
                  Expanded(flex: 1, child: TableHeader('Stock')),
                  SizedBox(width: 90, child: TableHeader('Actions')),
                ]),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text('No products.', style: TextStyle(color: tp.textSecondary)))
                    : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: tp.dividerColor),
                  itemBuilder: (ctx, i) => Container(
                    color: i.isEven ? tp.tableRowEven : tp.tableRowOdd,
                    child: _ProductRow(product: filtered[i], tp: tp,
                      onEdit: () => _openDialog(filtered[i]),
                      onDelete: () => widget.store.deleteProduct(filtered[i].id),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon,
      {Color color = ThemeProvider.accent}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: tp.cardBg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tp.borderColor)),
        child: Row(children: [
          Icon(icon, color: color, size: 26), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: tp.textSecondary)),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: tp.textPrimary)),
          ]),
        ]),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final ThemeProvider tp;
  final VoidCallback onEdit, onDelete;
  const _ProductRow({required this.product, required this.tp, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isLow = product.stock > 0 && product.stock < 5;
    final isOut = product.stock == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(flex: 3, child: Text(product.name, style: TextStyle(fontWeight: FontWeight.w500, color: tp.textPrimary))),
        Expanded(flex: 2, child: Text(product.barcode, style: TextStyle(fontFamily: 'Courier',
            color: tp.isDark ? Colors.lightBlue.shade200 : Colors.blueGrey, fontSize: 12))),
        Expanded(flex: 1, child: Text('Rs ${product.price.toStringAsFixed(0)}', style: TextStyle(color: tp.textPrimary))),
        Expanded(flex: 1, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: isOut ? Colors.red.withOpacity(0.15) : isLow ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${product.stock}', textAlign: TextAlign.center,
              style: TextStyle(color: isOut ? Colors.red : isLow ? Colors.orange.shade700 : Colors.green.shade700,
                  fontWeight: FontWeight.bold, fontSize: 12)),
        )),
        SizedBox(width: 90, child: Row(children: [
          IconButton(icon: Icon(Icons.edit, size: 18, color: tp.textSecondary), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: onDelete),
        ])),
      ]),
    );
  }
}
