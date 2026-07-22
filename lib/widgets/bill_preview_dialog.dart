import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/theme_provider.dart';
import '../models/models.dart';
import '../utils/esc_pos_builder.dart';

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
