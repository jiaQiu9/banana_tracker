class BananaEntry {
  final int? id;
  final DateTime eatenAt;
  final double amount;

  BananaEntry({this.id, required this.eatenAt, this.amount = 0.0});

  Map<String, dynamic> toMap() => {
        'id': id,
        'eaten_at': eatenAt.toIso8601String(),
        'amount': amount,
      };

  factory BananaEntry.fromMap(Map<String, dynamic> map) => BananaEntry(
        id: map['id'] as int?,
        eatenAt: DateTime.parse(map['eaten_at'] as String),
        amount: (map['amount'] as num?)?.toDouble() ?? 1.0,
      );

  BananaEntry copyWith({int? id, DateTime? eatenAt, double? amount}) =>
      BananaEntry(
        id: id ?? this.id,
        eatenAt: eatenAt ?? this.eatenAt,
        amount: amount ?? this.amount,
      );
}
