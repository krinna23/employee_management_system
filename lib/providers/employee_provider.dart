import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/employee_model.dart';

class EmployeeProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<EmployeeModel> _employees = [];
  List<EmployeeModel> get employees => _employees;

  List<EmployeeModel> _filteredEmployees = [];
  List<EmployeeModel> get filteredEmployees => _filteredEmployees;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  int? _departmentFilter;

  // Dashboard stats
  Map<String, int> _deptCounts = {};
  Map<String, int> get deptCounts => _deptCounts;

  int _todayPresentCount = 0;
  int get todayPresentCount => _todayPresentCount;

  double _totalSalaryExpense = 0.0;
  double get totalSalaryExpense => _totalSalaryExpense;

  int get totalEmployees => _employees.length;

  Future<void> fetchEmployees() async {
    _isLoading = true;
    notifyListeners();
    _employees = await _dbHelper.getAllEmployees();
    _applyFilter();
    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void setDepartmentFilter(int? deptId) {
    _departmentFilter = deptId;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filteredEmployees = _employees.where((emp) {
      final matchSearch = _searchQuery.isEmpty ||
          emp.name.toLowerCase().contains(_searchQuery) ||
          emp.email.toLowerCase().contains(_searchQuery);
      final matchDept = _departmentFilter == null || emp.departmentId == _departmentFilter;
      return matchSearch && matchDept;
    }).toList();
  }

  Future<int> addEmployee(EmployeeModel employee) async {
    int id = await _dbHelper.insertEmployee(employee);
    if (id != -1) await fetchEmployees();
    return id;
  }

  Future<bool> updateEmployee(EmployeeModel employee) async {
    int result = await _dbHelper.updateEmployee(employee);
    if (result > 0) { await fetchEmployees(); return true; }
    return false;
  }

  Future<bool> deleteEmployee(int id) async {
    int result = await _dbHelper.deleteEmployee(id);
    if (result > 0) { await fetchEmployees(); return true; }
    return false;
  }

  Future<void> fetchDashboardStats() async {
    _deptCounts = await _dbHelper.getDepartmentEmployeeCounts();
    _totalSalaryExpense = await _dbHelper.getTotalSalaryExpense();
    final todayStr = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    _todayPresentCount = await _dbHelper.getTodayAttendanceCount(todayStr);
    notifyListeners();
  }
}
