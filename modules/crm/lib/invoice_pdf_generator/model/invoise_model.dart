import 'package:flutter_riverpod/flutter_riverpod.dart';

class Invoice {
final  String invoiceNumber;
final  DateTime dateOfIssue;
final  DateTime dateOfSale;
final  Sellerdummy sellerdummy;
final  Buyer buyer;
final  List<InvoiceItem> items;
final  PaymentDetails paymentDetails;
final  String remarks;
final  double totalDue;
final  double paidamount;
final  String agentLogo;

   Invoice({
    required this.paidamount,
    required this.invoiceNumber,
    required this.dateOfIssue,
    required this.dateOfSale,
    required this.sellerdummy,
    required this.buyer,
    required this.items,
    required this.paymentDetails,
    required this.remarks,
    required this.totalDue,
    required this.agentLogo,
  });
}

class Sellerdummy {
 final String companyName;
 final String address;
 final String vatNumber;

  const Sellerdummy({
    required this.companyName,
    required this.address,
    required this.vatNumber,
  });
}

class Buyer {
 final String companyName;
 final String address;
 final String vatNumber;

  const Buyer({
    required this.companyName,
    required this.address,
    required this.vatNumber,
  });
}

class Priceonly {
 final int quantity;
 final double netUnitPrice;
 final double vatRate;

  const Priceonly({
    required this.quantity,
    required this.netUnitPrice,
    required this.vatRate,
  });

  double get netAmount => netUnitPrice * quantity;
  double get vatAmount => netAmount * (vatRate / 100);
  double get grossAmount => netAmount + vatAmount;
}

class InvoiceItem {
 final String description;
 final int quantity;
 final double netUnitPrice;
 final double vatRate;

  const InvoiceItem({
    required this.description,
    required this.quantity,
    required this.netUnitPrice,
    required this.vatRate,
  });

  double get netAmount => netUnitPrice * quantity;
  double get vatAmount => netAmount * (vatRate / 100);
  double get grossAmount => netAmount + vatAmount;
}

class PaymentDetails {
  final String paymentTerms;
  final String paymentMethod;
  final DateTime dueDate;

  const PaymentDetails({
    required this.paymentTerms,
    required this.paymentMethod,
    required this.dueDate,
  });
}

final invoicetoggleProvider = StateProvider<bool>((ref) => false);

void toggleBoolean(WidgetRef ref) {
  final currentValue = ref.read(invoicetoggleProvider.notifier).state;
  ref.read(invoicetoggleProvider.notifier).state = !currentValue;
}
