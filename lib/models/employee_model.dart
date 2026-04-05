class EmployeeModel {
  final int? id;
  final int? departmentId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final double salary;
  final String joiningDate;
  final String password;

  EmployeeModel({
    this.id,
    this.departmentId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.salary,
    required this.joiningDate,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'department_id': departmentId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'salary': salary,
      'joining_date': joiningDate,
      'password': password,
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'],
      departmentId: map['department_id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      role: map['role'],
      salary: map['salary'] is int ? (map['salary'] as int).toDouble() : map['salary'],
      joiningDate: map['joining_date'],
      password: map['password'],
    );
  }
}
