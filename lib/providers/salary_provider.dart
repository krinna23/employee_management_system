import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/salary_history_model.dart';

class SalaryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<SalaryHistoryModel> _userSalaries = [];
  List<SalaryHistoryModel> get userSalaries => _userSalaries;

  List<SalaryHistoryModel> _allSalaries = [];
  List<SalaryHistoryModel> get allSalaries => _allSalaries;

  Future<void> fetchEmployeeSalaries(int empId) async {
    _userSalaries = await _dbHelper.getEmployeeSalaries(empId);
    notifyListeners();
  }

  Future<void> fetchAllSalaries() async {
    _allSalaries = await _dbHelper.getAllSalaries();
    notifyListeners();
  }

  Future<bool> paySalary(int empId, double amount, String month) async {
    final history = SalaryHistoryModel(
      employeeId: empId,
      amount: amount,
      month: month,
      datePaid: DateTime.now().toIso8601String().split('T')[0],
      status: 'Pending',
    );
    int id = await _dbHelper.insertSalaryHistory(history);
    if (id != -1) {
      await fetchAllSalaries();
      await fetchEmployeeSalaries(empId);
    }
    return id != -1;
  }

  Future<bool> updateSalaryStatus(int historyId, String newStatus, {int? empId}) async {
    final result = await _dbHelper.updateSalaryStatus(historyId, newStatus);
    if (result > 0) {
      await fetchAllSalaries();
      if (empId != null) await fetchEmployeeSalaries(empId);
      return true;
    }
    return false;
  }
}
