class EntryModel {
  int? id;
  int type; // 1 for Trip Entry, 2 for Load/Ton Report
  DateTime date;
  String details;
  String vehicleNumber;
  double dieselExpense;
  double otherExpense; // Autos in Type 1, Other in Type 2
  double totalExpense;
  double earnings; // Manual in Type 1, Calculated in Type 2
  double? ratePerTon; // Required for Type 2
  double? totalTon; // Required for Type 2
  double profit;

  EntryModel({
    this.id,
    required this.type,
    required this.date,
    required this.details,
    required this.vehicleNumber,
    required this.dieselExpense,
    required this.otherExpense,
    required this.totalExpense,
    required this.earnings,
    this.ratePerTon,
    this.totalTon,
    required this.profit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'date': date.toIso8601String(),
      'details': details,
      'vehicle_number': vehicleNumber,
      'diesel_expense': dieselExpense,
      'other_expense': otherExpense,
      'total_expense': totalExpense,
      'earnings': earnings,
      'rate_per_ton': ratePerTon,
      'total_ton': totalTon,
      'profit': profit,
    };
  }

  factory EntryModel.fromMap(Map<String, dynamic> map) {
    return EntryModel(
      id: map['id'],
      type: map['type'],
      date: DateTime.parse(map['date']),
      details: map['details'],
      vehicleNumber: map['vehicle_number'],
      dieselExpense: map['diesel_expense'],
      otherExpense: map['other_expense'],
      totalExpense: map['total_expense'],
      earnings: map['earnings'],
      ratePerTon: map['rate_per_ton'],
      totalTon: map['total_ton'],
      profit: map['profit'],
    );
  }
}
