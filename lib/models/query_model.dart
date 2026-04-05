class SupportQueryModel {
  final int? id;
  final int employeeId;
  final String employeeName; // denormalized for display
  final String subject;
  final String message; // initial message body
  final String status; // Pending, In Process, Resolved
  final String createdAt;

  SupportQueryModel({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  SupportQueryModel copyWith({String? status}) {
    return SupportQueryModel(
      id: id,
      employeeId: employeeId,
      employeeName: employeeName,
      subject: subject,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'subject': subject,
      'message': message,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory SupportQueryModel.fromMap(Map<String, dynamic> map) {
    return SupportQueryModel(
      id: map['id'],
      employeeId: map['employee_id'],
      employeeName: map['employee_name'] ?? 'Unknown',
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'Pending',
      createdAt: map['created_at'] ?? '',
    );
  }
}
