import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/attendance_model.dart';

class AttendanceProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<AttendanceModel> _userAttendance = [];
  List<AttendanceModel> get userAttendance => _userAttendance;

  List<AttendanceModel> _allAttendance = [];
  List<AttendanceModel> get allAttendance => _allAttendance;

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> fetchEmployeeAttendance(int empId) async {
    _userAttendance = await _dbHelper.getEmployeeAttendance(empId);
    notifyListeners();
  }

  Future<void> fetchAllAttendance() async {
    _allAttendance = await _dbHelper.getAllAttendance();
    notifyListeners();
  }

  /// Returns true if this employee has already checked in TODAY
  bool hasCheckedInToday(int empId) {
    return _userAttendance.any((a) => a.employeeId == empId && a.date == _todayStr);
  }

  Future<bool> checkIn(int empId) async {
    // Prevent duplicate check-in on same date
    if (_userAttendance.any((a) => a.date == _todayStr)) return false;

    final now = DateTime.now();
    final attendance = AttendanceModel(
      employeeId: empId,
      date: _todayStr,
      checkIn: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      status: now.hour < 10 ? 'Present' : 'Late',
    );

    int id = await _dbHelper.logAttendance(attendance);
    if (id != -1) {
      await fetchEmployeeAttendance(empId);
      await fetchAllAttendance(); // keep admin view fresh
      return true;
    }
    return false;
  }
}
