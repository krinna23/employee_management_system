class SalaryHistoryModel {
  final int? id;
  final int employeeId;
  final double amount;
  final String month;
  final String datePaid;
  final String status;

  SalaryHistoryModel({
    this.id,
    required this.employeeId,
    required this.amount,
    required this.month,
    required this.datePaid,
    this.status = 'Pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'amount': amount,
      'month': month,
      'date_paid': datePaid,
      'status': status,
    };
  }

  factory SalaryHistoryModel.fromMap(Map<String, dynamic> map) {
    return SalaryHistoryModel(
      id: map['id'],
      employeeId: map['employee_id'],
      amount: map['amount'] is int ? (map['amount'] as int).toDouble() : map['amount'],
      month: map['month'],
      datePaid: map['date_paid'],
      status: map['status'] ?? 'Pending',
    );
  }
}
