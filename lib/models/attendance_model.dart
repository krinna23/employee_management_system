class AttendanceModel {
  final int? id;
  final int employeeId;
  final String date;
  final String checkIn;
  final String? checkOut;
  final String status; // Present, Late, Absent

  AttendanceModel({
    this.id,
    required this.employeeId,
    required this.date,
    required this.checkIn,
    this.checkOut,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date,
      'check_in': checkIn,
      'check_out': checkOut,
      'status': status,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'],
      employeeId: map['employee_id'],
      date: map['date'],
      checkIn: map['check_in'],
      checkOut: map['check_out'],
      status: map['status'],
    );
  }
}
