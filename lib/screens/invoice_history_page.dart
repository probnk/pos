import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/theme_provider.dart';
import '../data/data_store.dart';
import '../models/models.dart';
import '../utils/esc_pos_builder.dart';
import '../widgets/bill_preview_dialog.dart';
import '../widgets/table_header.dart';

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
                  SizedBox(width: 190, child: TableHeader('Invoice Number')),
                  SizedBox(width: 160, child: TableHeader('Date & Time')),
                  Expanded(child: TableHeader('Items')),
                  SizedBox(width: 100, child: TableHeader('Discount')),
                  SizedBox(width: 120, child: TableHeader('Total')),
                  SizedBox(width: 130, child: TableHeader('Actions')),
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