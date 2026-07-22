import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

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
