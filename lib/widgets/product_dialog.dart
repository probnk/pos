import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../models/models.dart';

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
