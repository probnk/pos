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
