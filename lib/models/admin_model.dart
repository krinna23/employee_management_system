class AdminModel {
  final int? id;
  final String email;
  final String password;

  AdminModel({this.id, required this.email, required this.password});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
    };
  }

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      id: map['id'],
      email: map['email'],
      password: map['password'],
    );
  }
}
