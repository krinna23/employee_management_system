import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/admin_model.dart';
import '../models/employee_model.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _userRole;
  String? get userRole => _userRole;

  int? _userId;
  int? get userId => _userId;

  AdminModel? _admin;
  AdminModel? get admin => _admin;

  EmployeeModel? _employee;
  EmployeeModel? get employee => _employee;

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('role');
    _userId = prefs.getInt('id');
    
    if (_userId != null) {
      if (_userRole == 'admin') {
        // In a real app we'd fetch admin details, but since we only have 1 seeded admin:
        _admin = AdminModel(id: _userId, email: 'admin@test.com', password: '');
      } else {
        _employee = await _dbHelper.getEmployeeById(_userId!);
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password, bool isAdmin) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (isAdmin) {
        final admin = await _dbHelper.getAdmin(email, password);
        if (admin != null) {
          _admin = admin;
          _userRole = 'admin';
          _userId = admin.id;
          await prefs.setString('role', 'admin');
          await prefs.setInt('id', _userId ?? 1);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } else {
        final emp = await _dbHelper.getEmployee(email, password);
        if (emp != null) {
          _employee = emp;
          _userRole = 'employee';
          _userId = emp.id;
          await prefs.setString('role', 'employee');
          await prefs.setInt('id', _userId!);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _userRole = null;
    _userId = null;
    _admin = null;
    _employee = null;
    notifyListeners();
  }

  Future<bool> changePassword(String newPassword) async {
    if (_userId == null || _userRole == null) return false;
    
    int result = 0;
    if (_userRole == 'admin') {
      result = await _dbHelper.updateAdminPassword(_userId!, newPassword);
    } else {
      result = await _dbHelper.updateEmployeePassword(_userId!, newPassword);
    }
    
    return result > 0;
  }
}
