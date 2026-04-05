import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/query_model.dart';
import '../models/message_model.dart';

class QueryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<SupportQueryModel> _allQueries = [];
  List<SupportQueryModel> get allQueries => _allQueries;

  List<SupportQueryModel> _userQueries = [];
  List<SupportQueryModel> get userQueries => _userQueries;

  List<SupportQueryModel> _filteredQueries = [];
  List<SupportQueryModel> get filteredQueries => _filteredQueries;

  List<MessageModel> _currentMessages = [];
  List<MessageModel> get currentMessages => _currentMessages;

  String _statusFilter = 'All';
  String get statusFilter => _statusFilter;

  String _searchQuery = '';

  Future<void> fetchAllQueries() async {
    _allQueries = await _dbHelper.getAllQueries();
    _applyAdminFilter();
    notifyListeners();
  }

  Future<void> fetchEmployeeQueries(int empId) async {
    _userQueries = await _dbHelper.getEmployeeQueries(empId);
    notifyListeners();
  }

  Future<void> fetchMessages(int queryId) async {
    _currentMessages = await _dbHelper.getQueryMessages(queryId);
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyAdminFilter();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyAdminFilter();
    notifyListeners();
  }

  void _applyAdminFilter() {
    _filteredQueries = _allQueries.where((q) {
      final matchStatus = _statusFilter == 'All' || q.status == _statusFilter;
      final matchSearch = _searchQuery.isEmpty || q.employeeName.toLowerCase().contains(_searchQuery) || q.subject.toLowerCase().contains(_searchQuery);
      return matchStatus && matchSearch;
    }).toList();
  }

  Future<int> raiseQuery(int empId, String empName, String subject, String message) async {
    final query = SupportQueryModel(
      employeeId: empId,
      employeeName: empName,
      subject: subject,
      message: message,
      status: 'Pending',
      createdAt: DateTime.now().toIso8601String(),
    );
    int id = await _dbHelper.createQuery(query);
    if (id != -1) await fetchEmployeeQueries(empId);
    return id;
  }

  Future<bool> updateQueryStatus(int queryId, String status) async {
    int result = await _dbHelper.updateQueryStatus(queryId, status);
    if (result > 0) {
      await fetchAllQueries();
      return true;
    }
    return false;
  }

  Future<bool> sendMessage(int queryId, String senderType, int senderId, String message) async {
    final msg = MessageModel(
      queryId: queryId,
      senderType: senderType,
      senderId: senderId,
      message: message,
      timestamp: DateTime.now().toIso8601String(),
    );
    int id = await _dbHelper.insertMessage(msg);
    if (id != -1) {
      await fetchMessages(queryId);
      return true;
    }
    return false;
  }
}
