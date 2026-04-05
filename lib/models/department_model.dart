class DepartmentModel {
  final int? id;
  final String name;
  final String description;

  DepartmentModel({this.id, required this.name, required this.description});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  factory DepartmentModel.fromMap(Map<String, dynamic> map) {
    return DepartmentModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
    );
  }
}
