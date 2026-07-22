import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── MAIN ─────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('products');
  await Hive.openBox('invoices');

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? false;
  runApp(CosmeticPOSApp(initialDark: isDark));
}

// ─── THEME PROVIDER ───────────────────────────────────────────────────────────

class ThemeProvider extends ChangeNotifier {
  bool _isDark;
  ThemeProvider(this._isDark);

  bool get isDark => _isDark;

  static const Color sidebarBg = Color(0xFF1A1A2E);
  static const Color accent    = Color(0xFFD4456E);

  Color get pageBg          => _isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF5F5F5);
  Color get cardBg          => _isDark ? const Color(0xFF1A1A2E) : Colors.white;
  Color get tableRowEven    => _isDark ? const Color(0xFF16162A) : Colors.white;
  Color get tableRowOdd     => _isDark ? const Color(0xFF1E1E30) : const Color(0xFFFAFAFA);
  Color get borderColor     => _isDark ? const Color(0xFF2A2A40) : Colors.grey.shade200;
  Color get textPrimary     => _isDark ? const Color(0xFFEEEEFF) : const Color(0xFF1A1A2E);
  Color get textSecondary   => _isDark ? const Color(0xFF8888AA) : Colors.grey.shade600;
  Color get inputFill       => _isDark ? const Color(0xFF1E1E30) : Colors.grey.shade50;
  Color get dividerColor    => _isDark ? const Color(0xFF2A2A40) : Colors.grey.shade200;
  Color get billPanelBg     => _isDark ? const Color(0xFF13131F) : Colors.grey.shade50;
  Color get chargeSectionBg => _isDark ? const Color(0xFF1A1A2E) : Colors.white;

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDark);
    notifyListeners();
  }
}

// ─── MODELS ───────────────────────────────────────────────────────────────────

class Product {
  final String id;
  String name;
  String barcode;
  double price;
  int stock;

  Product({required this.id, required this.name,
    required this.barcode, required this.price, required this.stock});

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'barcode': barcode, 'price': price, 'stock': stock};

  factory Product.fromMap(Map m) => Product(
    id: m['id'], name: m['name'], barcode: m['barcode'],
    price: (m['price'] as num).toDouble(), stock: m['stock'],
  );
}

class BillItem {
  final Product product;
  int qty;
  BillItem({required this.product, required this.qty});
  double get total => product.price * qty;
}

class InvoiceItem {
  final String productName;
  final String barcode;
  final double price;
  final int qty;
  final double total;

  InvoiceItem({required this.productName, required this.barcode,
    required this.price, required this.qty, required this.total});

  Map<String, dynamic> toMap() =>
      {'productName': productName, 'barcode': barcode, 'price': price, 'qty': qty, 'total': total};

  factory InvoiceItem.fromMap(Map m) => InvoiceItem(
    productName: m['productName'], barcode: m['barcode'],
    price: (m['price'] as num).toDouble(), qty: m['qty'],
    total: (m['total'] as num).toDouble(),
  );
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final DateTime date;
  final double subtotal;
  final double discount;
  final double gstPct;
  final double gstAmount;
  final double printingFee;
  final double finalTotal;
  final List<InvoiceItem> items;

  Invoice({
    required this.id, required this.invoiceNumber, required this.date,
    required this.subtotal, required this.discount, required this.gstPct,
    required this.gstAmount, required this.printingFee, required this.finalTotal,
    required this.items,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'invoiceNumber': invoiceNumber, 'date': date.toIso8601String(),
    'subtotal': subtotal, 'discount': discount, 'gstPct': gstPct,
    'gstAmount': gstAmount, 'printingFee': printingFee, 'finalTotal': finalTotal,
    'items': items.map((i) => i.toMap()).toList(),
  };

  factory Invoice.fromMap(Map m) => Invoice(
    id: m['id'], invoiceNumber: m['invoiceNumber'],
    date: DateTime.parse(m['date']),
    subtotal: (m['subtotal'] as num).toDouble(),
    discount: (m['discount'] as num).toDouble(),
    gstPct: (m['gstPct'] as num).toDouble(),
    gstAmount: (m['gstAmount'] as num).toDouble(),
    printingFee: (m['printingFee'] as num).toDouble(),
    finalTotal: (m['finalTotal'] as num).toDouble(),
    items: (m['items'] as List).map((i) => InvoiceItem.fromMap(i)).toList(),
  );
}

// ─── DATA STORE ───────────────────────────────────────────────────────────────

class DataStore {
  static final DataStore _i = DataStore._();
  factory DataStore() => _i;
  DataStore._();

  final ValueNotifier<int> version = ValueNotifier(0);

  Box get _box => Hive.box('products');
  Box get _invBox => Hive.box('invoices');

  // ── Products ──
  List<Product> get products {
    return _box.values
        .map((v) => Product.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> addProduct(Product p) async {
    await _box.put(p.id, p.toMap());
    version.value++;
  }

  Future<void> updateProduct(Product p) async {
    await _box.put(p.id, p.toMap());
    version.value++;
  }

  Future<void> deleteProduct(String id) async {
    await _box.delete(id);
    version.value++;
  }

  Product? findByBarcode(String barcode) {
    try { return products.firstWhere((p) => p.barcode == barcode); }
    catch (_) { return null; }
  }

  // ── Invoices ──
  List<Invoice> get invoices {
    return _invBox.values
        .map((v) => Invoice.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Invoice> searchInvoices(String query) {
    if (query.isEmpty) return invoices;
    return invoices.where((inv) =>
        inv.invoiceNumber.toLowerCase().contains(query.toLowerCase())).toList();
  }

  Future<String> generateInvoiceNumber() async {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}';
    final todayInvoices = invoices.where((inv) => inv.invoiceNumber.contains(dateStr)).length;
    return 'INV-$dateStr-${(todayInvoices + 1).toString().padLeft(4, '0')}';
  }

  Future<void> saveInvoice(Invoice inv) async {
    await _invBox.put(inv.id, inv.toMap());
  }
}

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
        _Sidebar(page: _page, tp: widget.tp, onNav: (i) => setState(() => _page = i)),
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

// ─── SIDEBAR ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int page;
  final ThemeProvider tp;
  final void Function(int) onNav;
  const _Sidebar({required this.page, required this.tp, required this.onNav});

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
                  Expanded(flex: 3, child: _TH('Product Name')),
                  Expanded(flex: 2, child: _TH('Barcode')),
                  Expanded(flex: 1, child: _TH('Price (Rs)')),
                  Expanded(flex: 1, child: _TH('Stock')),
                  SizedBox(width: 90, child: _TH('Actions')),
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

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12));
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

// ─── PRODUCT DIALOG ───────────────────────────────────────────────────────────

class ProductDialog extends StatefulWidget {
  final Product? existing;
  final String? prefillBarcode;
  final ThemeProvider tp;
  final void Function(Product) onSave;
  const ProductDialog({super.key, this.existing, this.prefillBarcode, required this.tp, required this.onSave});
  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  late TextEditingController _name, _barcode, _price, _stock;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name    = TextEditingController(text: e?.name ?? '');
    _barcode = TextEditingController(text: e?.barcode ?? widget.prefillBarcode ?? '');
    _price   = TextEditingController(text: e != null ? e.price.toStringAsFixed(0) : '');
    _stock   = TextEditingController(text: e != null ? '${e.stock}' : '');
  }

  @override
  void dispose() { _name.dispose(); _barcode.dispose(); _price.dispose(); _stock.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final tp = widget.tp;
    final isEdit = widget.existing != null;
    return AlertDialog(
      backgroundColor: tp.cardBg,
      title: Row(children: [
        Icon(isEdit ? Icons.edit : Icons.add_box, color: ThemeProvider.accent),
        const SizedBox(width: 8),
        Text(isEdit ? 'Edit Product' : 'Add New Product', style: TextStyle(color: tp.textPrimary)),
      ]),
      content: SizedBox(width: 420, child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(
          controller: _barcode, readOnly: isEdit,
          style: TextStyle(color: isEdit ? tp.textSecondary : tp.textPrimary),
          decoration: InputDecoration(
            labelText: 'Barcode', labelStyle: TextStyle(color: tp.textSecondary),
            border: const OutlineInputBorder(), filled: true, fillColor: tp.inputFill,
            suffixIcon: isEdit ? const Tooltip(message: 'Barcode cannot be changed',
                child: Icon(Icons.lock_outline, size: 18, color: Colors.grey)) : null,
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _field(_name, 'Product Name', tp, required: true),
        const SizedBox(height: 12),
        _field(_price, 'Price (Rs)', tp, required: true, numeric: true),
        const SizedBox(height: 12),
        _field(_stock, 'Stock Quantity', tp, required: true, numeric: true),
        if (isEdit) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withOpacity(0.3))),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue), SizedBox(width: 8),
              Expanded(child: Text('Barcode is locked. Name, price and stock editable.',
                  style: TextStyle(fontSize: 12, color: Colors.blue))),
            ]),
          ),
        ],
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: tp.textSecondary))),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: ThemeProvider.accent),
          child: Text(isEdit ? 'Update' : 'Add Product'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, ThemeProvider tp,
      {bool required = false, bool numeric = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : null,
      style: TextStyle(color: tp.textPrimary),
      decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: tp.textSecondary),
          border: const OutlineInputBorder(), filled: true, fillColor: tp.inputFill),
      validator: (v) {
        if (required && (v == null || v.isEmpty)) return 'Required';
        if (numeric && v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Enter a valid number';
        return null;
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(Product(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name.text.trim(), barcode: _barcode.text.trim(),
      price: double.parse(_price.text), stock: int.parse(_stock.text),
    ));
    Navigator.pop(context);
  }
}

// ─── BILLING PAGE ─────────────────────────────────────────────────────────────

class BillingPage extends StatefulWidget {
  final DataStore store;
  final ThemeProvider tp;
  const BillingPage({super.key, required this.store, required this.tp});
  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final List<BillItem> _bill = [];
  final _scanCtrl    = TextEditingController();
  final _scanFocus   = FocusNode();
  String _searchQuery = '';
  String? _errorMsg;
  final _discountCtrl = TextEditingController(text: '0');
  final _gstCtrl      = TextEditingController(text: '2');
  final _printingCtrl = TextEditingController(text: '1');
  ThemeProvider get tp => widget.tp;

  @override
  void initState() {
    super.initState();
    tp.addListener(() { if (mounted) setState(() {}); });
    widget.store.version.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _scanCtrl.dispose(); _scanFocus.dispose();
    _discountCtrl.dispose(); _gstCtrl.dispose(); _printingCtrl.dispose();
    super.dispose();
  }

  void _handleScan(String input) {
    final t = input.trim();
    if (t.isEmpty) return;
    final product = widget.store.findByBarcode(t);
    setState(() => _errorMsg = product == null ? 'Barcode not found: $t' : null);
    if (product != null) _addToBill(product);
    _scanCtrl.clear();
    _scanFocus.requestFocus();
  }

  void _addToBill(Product p) {
    setState(() {
      final i = _bill.indexWhere((x) => x.product.id == p.id);
      if (i != -1) _bill[i].qty++;
      else _bill.add(BillItem(product: p, qty: 1));
    });
  }

  void _changeQty(int index, int delta) {
    setState(() {
      _bill[index].qty += delta;
      if (_bill[index].qty <= 0) _bill.removeAt(index);
    });
  }

  double get _subtotal      => _bill.fold(0, (s, i) => s + i.total);
  double get _discount      => double.tryParse(_discountCtrl.text) ?? 0;
  double get _gstPct        => double.tryParse(_gstCtrl.text) ?? 0;
  double get _printing      => double.tryParse(_printingCtrl.text) ?? 0;
  double get _afterDiscount => _subtotal - _discount;
  double get _gstAmount     => _afterDiscount * _gstPct / 100;
  double get _finalTotal    => _afterDiscount + _gstAmount + _printing;

  List<Product> get _filteredProducts {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return widget.store.products;
    return widget.store.products
        .where((p) => p.name.toLowerCase().contains(q) || p.barcode.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // LEFT
      Expanded(
        flex: 3,
        child: Container(
          color: tp.pageBg,
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Sales / Billing', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: tp.textPrimary)),
            Text('Scan barcode or tap product to add', style: TextStyle(fontSize: 12, color: tp.textSecondary)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _scanCtrl, focusNode: _scanFocus, autofocus: true,
                  style: TextStyle(color: tp.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Scan barcode or type product name...',
                    hintStyle: TextStyle(color: tp.textSecondary),
                    prefixIcon: Icon(Icons.qr_code_scanner, color: tp.textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: ThemeProvider.accent, width: 2)),
                    errorText: _errorMsg, filled: true, fillColor: tp.inputFill,
                  ),
                  onSubmitted: _handleScan,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.add), label: const Text('Add'),
                onPressed: () => _handleScan(_scanCtrl.text),
                style: FilledButton.styleFrom(backgroundColor: ThemeProvider.accent),
              ),
            ]),
            const SizedBox(height: 14),
            Text('PRODUCTS — TAP TO ADD', style: TextStyle(fontSize: 11,
                fontWeight: FontWeight.w600, color: tp.textSecondary, letterSpacing: 1)),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, childAspectRatio: 2.4, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: _filteredProducts.length,
                itemBuilder: (ctx, i) {
                  final p = _filteredProducts[i];
                  return InkWell(
                    onTap: () => _addToBill(p),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(color: tp.cardBg,
                          borderRadius: BorderRadius.circular(10), border: Border.all(color: tp.borderColor)),
                      padding: const EdgeInsets.all(10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(p.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: tp.textPrimary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text('Rs ${p.price.toStringAsFixed(0)}',
                                  style: const TextStyle(color: ThemeProvider.accent, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text('Qty:${p.stock}', style: TextStyle(fontSize: 10, color: tp.textSecondary)),
                            ]),
                          ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),

      // RIGHT
      Container(
        width: 570,
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: tp.borderColor)),
          color: tp.billPanelBg,
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFF1A1A2E),
            child: Row(children: [
              const Icon(Icons.receipt_long, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Current Bill', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_bill.isNotEmpty)
                Text('${_bill.fold(0, (s, i) => s + i.qty)} items',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),
          Container(
            color: tp.isDark ? const Color(0xFF16162A) : Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(children: [
              SizedBox(width: 30, child: Text('S#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tp.textSecondary))),
              SizedBox(width: 110, child: Text('Barcode', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tp.textSecondary))),
              Expanded(child: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tp.textSecondary))),
              SizedBox(width: 64, child: Text('Price', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tp.textSecondary))),
              SizedBox(width: 80, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tp.textSecondary))),
              SizedBox(width: 68, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tp.textSecondary))),
              const SizedBox(width: 28),
            ]),
          ),
          Expanded(
            child: _bill.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shopping_cart_outlined, size: 44, color: tp.textSecondary),
              const SizedBox(height: 8),
              Text('Scan a product to start', style: TextStyle(color: tp.textSecondary)),
            ]))
                : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _bill.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: tp.dividerColor),
              itemBuilder: (ctx, i) {
                final item = _bill[i];
                return Container(
                  color: i.isEven ? tp.tableRowEven : tp.tableRowOdd,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(children: [
                    SizedBox(width: 30, child: Text('${i+1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tp.textSecondary))),
                    SizedBox(width: 110, child: Text(item.product.barcode,
                        style: TextStyle(fontSize: 10, fontFamily: 'Courier',
                            color: tp.isDark ? Colors.lightBlue.shade200 : Colors.blueGrey),
                        overflow: TextOverflow.ellipsis)),
                    Expanded(child: Text(item.product.name,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tp.textPrimary),
                        overflow: TextOverflow.ellipsis)),
                    SizedBox(width: 64, child: Text('Rs ${item.product.price.toStringAsFixed(0)}',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: tp.textPrimary))),
                    SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _qtyBtn(Icons.remove, () => _changeQty(i, -1), Colors.red),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text('${item.qty}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: tp.textPrimary))),
                      _qtyBtn(Icons.add, () => _changeQty(i, 1), ThemeProvider.accent),
                    ])),
                    SizedBox(width: 68, child: Text('Rs ${item.total.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: ThemeProvider.accent))),
                    SizedBox(width: 28, child: IconButton(
                        icon: Icon(Icons.close, size: 14, color: tp.textSecondary),
                        onPressed: () => setState(() => _bill.removeAt(i)),
                        padding: EdgeInsets.zero)),
                  ]),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: tp.chargeSectionBg, border: Border(top: BorderSide(color: tp.borderColor))),
            child: Column(children: [
              _totalRow('Subtotal', 'Rs ${_subtotal.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 13, color: tp.textSecondary)),
              const SizedBox(height: 8),
              _chargeRow('Discount (Rs)', _discountCtrl, tp, '− Rs ${_discount.toStringAsFixed(0)}', Colors.green),
              const SizedBox(height: 6),
              _chargeRow('GST (%)', _gstCtrl, tp, '+ Rs ${_gstAmount.toStringAsFixed(1)}', Colors.orange, suffix: '%'),
              const SizedBox(height: 6),
              _chargeRow('Printing Fee (Rs)', _printingCtrl, tp, '+ Rs ${_printing.toStringAsFixed(0)}', tp.textSecondary),
              Divider(height: 14, color: tp.dividerColor),
              Row(children: [
                Text('FINAL TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tp.textPrimary)),
                const Spacer(),
                Text('Rs ${_finalTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ThemeProvider.accent)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  icon: Icon(Icons.delete_sweep, color: tp.textSecondary),
                  label: Text('Clear', style: TextStyle(color: tp.textSecondary)),
                  onPressed: _bill.isEmpty ? null : () => setState(() => _bill.clear()),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: tp.borderColor)),
                )),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: FilledButton.icon(
                  icon: const Icon(Icons.print), label: const Text('Print Bill'),
                  onPressed: _bill.isEmpty ? null : () => _printBill(context),
                  style: FilledButton.styleFrom(backgroundColor: ThemeProvider.accent),
                )),
              ]),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(4),
        child: Container(width: 20, height: 20,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withOpacity(0.3))),
            child: Icon(icon, size: 12, color: color)));
  }

  Widget _chargeRow(String label, TextEditingController ctrl, ThemeProvider tp,
      String result, Color resultColor, {String? suffix}) {
    return Row(children: [
      Text(label, style: TextStyle(fontSize: 13, color: tp.textSecondary)),
      const Spacer(),
      SizedBox(width: suffix != null ? 60 : 80, height: 32, child: TextField(
        controller: ctrl, keyboardType: TextInputType.number, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tp.textPrimary),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: tp.borderColor)),
          filled: true, fillColor: tp.inputFill, isDense: true,
          suffixText: suffix, suffixStyle: TextStyle(color: tp.textSecondary),
        ),
        onChanged: (_) => setState(() {}),
      )),
      const SizedBox(width: 8),
      SizedBox(width: 90, child: Text(result, textAlign: TextAlign.right,
          style: TextStyle(fontSize: 13, color: resultColor, fontWeight: FontWeight.w600))),
    ]);
  }

  Widget _totalRow(String label, String value, {TextStyle? style}) {
    return Row(children: [
      Text(label, style: style ?? TextStyle(fontSize: 13, color: tp.textPrimary)), const Spacer(),
      Text(value, style: style ?? TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tp.textPrimary)),
    ]);
  }

  void _printBill(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BillPreviewDialog(
        bill: _bill, subtotal: _subtotal, discount: _discount,
        gstPct: _gstPct, gstAmount: _gstAmount, printingFee: _printing,
        finalTotal: _finalTotal, tp: tp,
        onConfirm: () async {
          final invoiceNumber = await widget.store.generateInvoiceNumber();
          final invoice = Invoice(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            invoiceNumber: invoiceNumber,
            date: DateTime.now(),
            subtotal: _subtotal,
            discount: _discount,
            gstPct: _gstPct,
            gstAmount: _gstAmount,
            printingFee: _printing,
            finalTotal: _finalTotal,
            items: _bill.map((b) => InvoiceItem(
              productName: b.product.name,
              barcode: b.product.barcode,
              price: b.product.price,
              qty: b.qty,
              total: b.total,
            )).toList(),
          );
          await widget.store.saveInvoice(invoice);
          for (final item in _bill) {
            item.product.stock -= item.qty;
            if (item.product.stock < 0) item.product.stock = 0;
            await widget.store.updateProduct(item.product);
          }
          await _sendToPrinter(_bill, invoiceNumber);
          setState(() { _bill.clear(); _discountCtrl.text = '0'; });
        },
      ),
    );
  }

  Future<String?> _getThermalPrinterName() async {
    try {
      final result = await Process.run('wmic', ['printer', 'get', 'name', '/format:list']);
      final lines = result.stdout.toString().split('\n');
      final names = lines.where((l) => l.trim().startsWith('Name=') && l.trim().length > 5)
          .map((l) => l.trim().replaceFirst('Name=', '').trim()).toList();
      final kws = ['thermal', 'receipt', 'blackcopper', 'bc87', 'pos', '80'];
      for (final name in names) {
        for (final kw in kws) { if (name.toLowerCase().contains(kw)) return name; }
      }
      return names.isNotEmpty ? names.first : null;
    } catch (_) { return null; }
  }

  Future<void> _sendToPrinter(List<BillItem> bill, String invoiceNumber) async {
    final bytes = buildEscPos(invoiceNumber: invoiceNumber, billItems: bill,
        subtotal: _subtotal, discount: _discount, gstPct: _gstPct,
        gstAmount: _gstAmount, printing: _printing, finalTotal: _finalTotal);
    try {
      if (Platform.isWindows) {
        final tmp = File('${Directory.systemTemp.path}/bill_raw.bin');
        await tmp.writeAsBytes(bytes);
        final printerName = await _getThermalPrinterName();
        if (printerName != null) {
          await Process.run('cmd', ['/c', 'copy', '/b', tmp.path, r'\\.\' + printerName]);
        }
      } else if (Platform.isLinux) {
        final tmp = File('${Directory.systemTemp.path}/bill_raw.bin');
        await tmp.writeAsBytes(bytes);
        await Process.run('lp', ['-o', 'raw', tmp.path]);
      }
    } catch (e) { debugPrint('Print error: $e'); }
  }
}

// ─── ESC/POS BUILDER ─────────────────────────────────────────────────────────

List<int> buildEscPos({
  required String invoiceNumber,
  List<BillItem>? billItems,
  List<InvoiceItem>? invoiceItems,
  required double subtotal,
  required double discount,
  required double gstPct,
  required double gstAmount,
  required double printing,
  required double finalTotal,
}) {
  final bytes = <int>[];
  final now = DateTime.now();
  bytes.addAll([0x1B, 0x40]);
  bytes.addAll([0x1B, 0x74, 0x00]);
  bytes.addAll([0x1B, 0x61, 0x01]);
  bytes.addAll([0x1B, 0x45, 0x01]);
  bytes.addAll('COSMETIC STORE\n'.codeUnits);
  bytes.addAll([0x1B, 0x45, 0x00]);
  bytes.addAll('================================\n'.codeUnits);
  bytes.addAll('Invoice: $invoiceNumber\n'.codeUnits);
  bytes.addAll('${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}'
      '  ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}\n'.codeUnits);
  bytes.addAll('================================\n'.codeUnits);
  bytes.addAll([0x1B, 0x61, 0x00]);
  bytes.addAll('No  Name              Qty    Total\n'.codeUnits);
  bytes.addAll('--------------------------------\n'.codeUnits);

  if (billItems != null) {
    for (int i = 0; i < billItems.length; i++) {
      final item = billItems[i];
      final name = item.product.name.length > 16 ? item.product.name.substring(0, 16) : item.product.name.padRight(16);
      bytes.addAll('${(i+1).toString().padLeft(2)}  $name  ${item.qty.toString().padLeft(3)}  Rs ${item.total.toStringAsFixed(0)}\n'.codeUnits);
    }
  } else if (invoiceItems != null) {
    for (int i = 0; i < invoiceItems.length; i++) {
      final item = invoiceItems[i];
      final name = item.productName.length > 16 ? item.productName.substring(0, 16) : item.productName.padRight(16);
      bytes.addAll('${(i+1).toString().padLeft(2)}  $name  ${item.qty.toString().padLeft(3)}  Rs ${item.total.toStringAsFixed(0)}\n'.codeUnits);
    }
  }

  bytes.addAll('--------------------------------\n'.codeUnits);
  bytes.addAll(('Subtotal:'.padRight(20) + 'Rs ${subtotal.toStringAsFixed(0)}\n').codeUnits);
  if (discount > 0) bytes.addAll(('Discount:'.padRight(20) + '- Rs ${discount.toStringAsFixed(0)}\n').codeUnits);
  if (gstAmount > 0) bytes.addAll(('GST(${gstPct.toStringAsFixed(0)}%):'.padRight(20) + '+ Rs ${gstAmount.toStringAsFixed(1)}\n').codeUnits);
  bytes.addAll(('Printing:'.padRight(20) + '+ Rs ${printing.toStringAsFixed(0)}\n').codeUnits);
  bytes.addAll('================================\n'.codeUnits);
  bytes.addAll([0x1B, 0x45, 0x01]);
  bytes.addAll(('TOTAL:'.padRight(20) + 'Rs ${finalTotal.toStringAsFixed(0)}\n').codeUnits);
  bytes.addAll([0x1B, 0x45, 0x00]);
  bytes.addAll('================================\n'.codeUnits);
  bytes.addAll([0x1B, 0x61, 0x01]);
  bytes.addAll('NO RETURN/EXCHANGE AFTER BILLING\n'.codeUnits);
  bytes.addAll('Thank You! Come Again\n'.codeUnits);
  bytes.addAll([0x1B, 0x64, 0x04]);
  bytes.addAll([0x1D, 0x56, 0x41, 0x00]);
  return bytes;
}

// ─── BILL PREVIEW DIALOG ─────────────────────────────────────────────────────

class BillPreviewDialog extends StatelessWidget {
  final List<BillItem>? bill;
  final Invoice? invoice;
  final double subtotal, discount, gstPct, gstAmount, printingFee, finalTotal;
  final ThemeProvider tp;
  final VoidCallback onConfirm;

  const BillPreviewDialog({
    super.key, this.bill, this.invoice,
    required this.subtotal, required this.discount, required this.gstPct,
    required this.gstAmount, required this.printingFee, required this.finalTotal,
    required this.tp, required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final d = invoice?.date ?? DateTime.now();
    final invNum = invoice?.invoiceNumber ?? 'Preview';
    final billItems = bill ?? [];
    final invItems = invoice?.items ?? [];

    return AlertDialog(
      backgroundColor: tp.cardBg,
      title: Row(children: [
        const Icon(Icons.receipt, color: ThemeProvider.accent),
        const SizedBox(width: 8),
        Expanded(child: Text('Bill Preview — $invNum',
            style: TextStyle(color: tp.textPrimary, fontSize: 15), overflow: TextOverflow.ellipsis)),
      ]),
      content: SizedBox(width: 380, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Text('COSMETIC STORE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tp.textPrimary))),
        Center(child: Text('$invNum\n${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}',
            textAlign: TextAlign.center, style: TextStyle(color: tp.textSecondary, fontSize: 12))),
        Divider(color: tp.dividerColor),
        Row(children: [
          SizedBox(width: 26, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tp.textSecondary))),
          Expanded(child: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tp.textSecondary))),
          SizedBox(width: 32, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tp.textSecondary))),
          SizedBox(width: 80, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tp.textSecondary))),
        ]),
        const SizedBox(height: 4),
        if (billItems.isNotEmpty) ...billItems.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            SizedBox(width: 26, child: Text('${e.key+1}', style: TextStyle(fontSize: 12, color: tp.textSecondary))),
            Expanded(child: Text('${e.value.product.name}\n  Rs ${e.value.product.price.toStringAsFixed(0)} each',
                style: TextStyle(fontSize: 12, color: tp.textPrimary), overflow: TextOverflow.ellipsis)),
            SizedBox(width: 32, child: Text('×${e.value.qty}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: tp.textPrimary))),
            SizedBox(width: 80, child: Text('Rs ${e.value.total.toStringAsFixed(0)}', textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tp.textPrimary))),
          ]),
        )),
        if (invItems.isNotEmpty) ...invItems.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            SizedBox(width: 26, child: Text('${e.key+1}', style: TextStyle(fontSize: 12, color: tp.textSecondary))),
            Expanded(child: Text('${e.value.productName}\n  Rs ${e.value.price.toStringAsFixed(0)} each',
                style: TextStyle(fontSize: 12, color: tp.textPrimary), overflow: TextOverflow.ellipsis)),
            SizedBox(width: 32, child: Text('×${e.value.qty}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: tp.textPrimary))),
            SizedBox(width: 80, child: Text('Rs ${e.value.total.toStringAsFixed(0)}', textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tp.textPrimary))),
          ]),
        )),
        Divider(color: tp.dividerColor),
        _pRow('Subtotal', 'Rs ${subtotal.toStringAsFixed(0)}', tp),
        if (discount > 0) _pRow('Discount', '− Rs ${discount.toStringAsFixed(0)}', tp, color: Colors.green),
        if (gstAmount > 0) _pRow('GST (${gstPct.toStringAsFixed(0)}%)', '+ Rs ${gstAmount.toStringAsFixed(1)}', tp, color: Colors.orange),
        _pRow('Printing Fee', '+ Rs ${printingFee.toStringAsFixed(0)}', tp),
        Divider(color: tp.dividerColor),
        Row(children: [
          Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: tp.textPrimary)),
          const Spacer(),
          Text('Rs ${finalTotal.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: ThemeProvider.accent)),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.withOpacity(0.3))),
          child: const Row(children: [
            Icon(Icons.warning_amber, size: 14, color: Colors.red), SizedBox(width: 6),
            Expanded(child: Text('NO RETURN / EXCHANGE AFTER BILLING.',
                style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600))),
          ]),
        ),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: tp.textSecondary))),
        FilledButton.icon(
          icon: const Icon(Icons.print), label: const Text('Print'),
          onPressed: () { Navigator.pop(context); onConfirm(); },
          style: FilledButton.styleFrom(backgroundColor: ThemeProvider.accent),
        ),
      ],
    );
  }

  Widget _pRow(String label, String value, ThemeProvider tp, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Text(label, style: TextStyle(fontSize: 12, color: tp.textSecondary)), const Spacer(),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? tp.textPrimary)),
    ]),
  );
}

// ─── INVOICE HISTORY PAGE ────────────────────────────────────────────────────

class InvoiceHistoryPage extends StatefulWidget {
  final DataStore store;
  final ThemeProvider tp;
  const InvoiceHistoryPage({super.key, required this.store, required this.tp});
  @override
  State<InvoiceHistoryPage> createState() => _InvoiceHistoryPageState();
}

class _InvoiceHistoryPageState extends State<InvoiceHistoryPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  ThemeProvider get tp => widget.tp;

  @override
  void initState() {
    super.initState();
    tp.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<Invoice> get _invoices => widget.store.searchInvoices(_query);

  Future<String?> _getThermalPrinterName() async {
    try {
      final result = await Process.run('wmic', ['printer', 'get', 'name', '/format:list']);
      final lines = result.stdout.toString().split('\n');
      final names = lines.where((l) => l.trim().startsWith('Name=') && l.trim().length > 5)
          .map((l) => l.trim().replaceFirst('Name=', '').trim()).toList();
      final kws = ['thermal', 'receipt', 'blackcopper', 'bc87', 'pos', '80'];
      for (final name in names) {
        for (final kw in kws) { if (name.toLowerCase().contains(kw)) return name; }
      }
      return names.isNotEmpty ? names.first : null;
    } catch (_) { return null; }
  }

  Future<void> _reprint(Invoice inv) async {
    final bytes = buildEscPos(
      invoiceNumber: inv.invoiceNumber, invoiceItems: inv.items,
      subtotal: inv.subtotal, discount: inv.discount, gstPct: inv.gstPct,
      gstAmount: inv.gstAmount, printing: inv.printingFee, finalTotal: inv.finalTotal,
    );
    try {
      if (Platform.isWindows) {
        final tmp = File('${Directory.systemTemp.path}/bill_raw.bin');
        await tmp.writeAsBytes(bytes);
        final printerName = await _getThermalPrinterName();
        if (printerName != null) {
          await Process.run('cmd', ['/c', 'copy', '/b', tmp.path, r'\\.\' + printerName]);
        }
      }
    } catch (e) { debugPrint('Reprint error: $e'); }
  }

  Future<void> _download(Invoice inv) async {
    final buf = StringBuffer();
    buf.writeln('        COSMETIC STORE');
    buf.writeln('================================');
    buf.writeln('Invoice: ${inv.invoiceNumber}');
    buf.writeln('${inv.date.day}/${inv.date.month}/${inv.date.year}  ${inv.date.hour.toString().padLeft(2,'0')}:${inv.date.minute.toString().padLeft(2,'0')}');
    buf.writeln('================================');
    buf.writeln('No  Name              Qty  Total');
    buf.writeln('--------------------------------');
    for (int i = 0; i < inv.items.length; i++) {
      final item = inv.items[i];
      final name = item.productName.length > 16 ? item.productName.substring(0, 16) : item.productName.padRight(16);
      buf.writeln('${(i+1).toString().padLeft(2)}  $name  ${item.qty.toString().padLeft(3)}  Rs ${item.total.toStringAsFixed(0)}');
    }
    buf.writeln('--------------------------------');
    buf.writeln('Subtotal:'.padRight(20) + 'Rs ${inv.subtotal.toStringAsFixed(0)}');
    if (inv.discount > 0) buf.writeln('Discount:'.padRight(20) + '- Rs ${inv.discount.toStringAsFixed(0)}');
    if (inv.gstAmount > 0) buf.writeln('GST(${inv.gstPct.toStringAsFixed(0)}%):'.padRight(20) + '+ Rs ${inv.gstAmount.toStringAsFixed(1)}');
    buf.writeln('Printing:'.padRight(20) + '+ Rs ${inv.printingFee.toStringAsFixed(0)}');
    buf.writeln('================================');
    buf.writeln('TOTAL:'.padRight(20) + 'Rs ${inv.finalTotal.toStringAsFixed(0)}');
    buf.writeln('================================');
    buf.writeln('  NO RETURN/EXCHANGE AFTER BILLING');
    buf.writeln('       Thank You! Come Again');

    try {
      final file = File('${Directory.current.path}/${inv.invoiceNumber}.txt');
      await file.writeAsString(buf.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Saved: ${file.path}'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showPreview(Invoice inv) {
    showDialog(
      context: context,
      builder: (_) => BillPreviewDialog(
        invoice: inv,
        subtotal: inv.subtotal, discount: inv.discount, gstPct: inv.gstPct,
        gstAmount: inv.gstAmount, printingFee: inv.printingFee, finalTotal: inv.finalTotal,
        tp: tp,
        onConfirm: () => _reprint(inv),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoices = _invoices;
    return Container(
      color: tp.pageBg,
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Invoice History', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: tp.textPrimary)),
            Text('Search, preview, reprint or download past bills', style: TextStyle(fontSize: 12, color: tp.textSecondary)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: ThemeProvider.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ThemeProvider.accent.withOpacity(0.3))),
            child: Text('${invoices.length} Invoices',
                style: const TextStyle(color: ThemeProvider.accent, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          style: TextStyle(color: tp.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search by invoice number e.g. INV-20260514-0001...',
            hintStyle: TextStyle(color: tp.textSecondary, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: tp.textSecondary),
            suffixIcon: _query.isNotEmpty
                ? IconButton(icon: Icon(Icons.clear, color: tp.textSecondary),
                onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true, fillColor: tp.inputFill,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
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
                  SizedBox(width: 190, child: _TH('Invoice Number')),
                  SizedBox(width: 160, child: _TH('Date & Time')),
                  Expanded(child: _TH('Items')),
                  SizedBox(width: 100, child: _TH('Discount')),
                  SizedBox(width: 120, child: _TH('Total')),
                  SizedBox(width: 130, child: _TH('Actions')),
                ]),
              ),
              Expanded(
                child: invoices.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.receipt_long, size: 48, color: tp.textSecondary),
                  const SizedBox(height: 8),
                  Text('No invoices found.', style: TextStyle(color: tp.textSecondary)),
                ]))
                    : ListView.separated(
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: tp.dividerColor),
                  itemBuilder: (ctx, i) {
                    final inv = invoices[i];
                    final d = inv.date;
                    return Container(
                      color: i.isEven ? tp.tableRowEven : tp.tableRowOdd,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        SizedBox(width: 190, child: Text(inv.invoiceNumber,
                            style: const TextStyle(fontFamily: 'Courier',
                                color: ThemeProvider.accent, fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 160, child: Text(
                            '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}',
                            style: TextStyle(fontSize: 12, color: tp.textSecondary))),
                        Expanded(child: Text(
                            '${inv.items.length} products · ${inv.items.fold(0, (s, i) => s + i.qty)} pcs',
                            style: TextStyle(fontSize: 12, color: tp.textPrimary))),
                        SizedBox(width: 100, child: Text(
                            inv.discount > 0 ? '− Rs ${inv.discount.toStringAsFixed(0)}' : '—',
                            style: TextStyle(fontSize: 12, color: inv.discount > 0 ? Colors.green : tp.textSecondary))),
                        SizedBox(width: 120, child: Text('Rs ${inv.finalTotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThemeProvider.accent))),
                        SizedBox(width: 130, child: Row(children: [
                          _actionBtn(Icons.visibility, 'Preview', Colors.blue, () => _showPreview(inv)),
                          const SizedBox(width: 4),
                          _actionBtn(Icons.print, 'Reprint', ThemeProvider.accent, () => _reprint(inv)),
                          const SizedBox(width: 4),
                          _actionBtn(Icons.download, 'Download', Colors.green, () => _download(inv)),
                        ])),
                      ]),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(7),
              border: Border.all(color: color.withOpacity(0.3))),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}