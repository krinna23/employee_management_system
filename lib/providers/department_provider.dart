import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/department_model.dart';

class DepartmentProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<DepartmentModel> _departments = [];
  List<DepartmentModel> get departments => _departments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchDepartments() async {
    _isLoading = true;
    notifyListeners();
    _departments = await _dbHelper.getAllDepartments();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addDepartment(DepartmentModel dept) async {
    int id = await _dbHelper.insertDepartment(dept);
    if (id != -1) await fetchDepartments();
    return id;
  }
}
