import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/theme_provider.dart';
import '../data/data_store.dart';
import '../models/models.dart';
import '../utils/esc_pos_builder.dart';
import '../widgets/bill_preview_dialog.dart';

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
