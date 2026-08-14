import 'package:uuid/uuid.dart';

class PurchaseModel {
  final String id;
  final String itemName;
  final num amount;
  final String? supplierName;
  final String? notes;
  final DateTime purchaseDate;
  final DateTime createdAt;
  final bool pendingSync;

  PurchaseModel({
    String? id,
    required this.itemName,
    required this.amount,
    this.supplierName,
    this.notes,
    required this.purchaseDate,
    DateTime? createdAt,
    this.pendingSync = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toUtc();

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as String?,
      itemName: json['item_name'] as String,
      amount: json['amount'] as num,
      supplierName: json['supplier_name'] as String?,
      notes: json['notes'] as String?,
      purchaseDate: DateTime.parse(json['purchase_date'] as String).toUtc(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toUtc()
          : null,
      pendingSync: json['pendingSync'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'amount': amount,
      'supplier_name': supplierName,
      'notes': notes,
      'purchase_date': purchaseDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'pendingSync': pendingSync,
    };
  }

  PurchaseModel copyWith({
    String? itemName,
    num? amount,
    String? supplierName,
    String? notes,
    DateTime? purchaseDate,
    bool? pendingSync,
  }) {
    return PurchaseModel(
      id: id,
      itemName: itemName ?? this.itemName,
      amount: amount ?? this.amount,
      supplierName: supplierName ?? this.supplierName,
      notes: notes ?? this.notes,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      createdAt: createdAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
