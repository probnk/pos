import '../models/models.dart';

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
