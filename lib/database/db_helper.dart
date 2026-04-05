import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/admin_model.dart';
import '../models/employee_model.dart';
import '../models/department_model.dart';
import '../models/attendance_model.dart';
import '../models/salary_history_model.dart';
import '../models/query_model.dart';
import '../models/message_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // ─── Mock data for Web testing ────────────────────────────────────────────
  static final List<AdminModel> _webAdmins = [
    AdminModel(id: 1, email: 'admin@test.com', password: 'admin123'),
  ];
  static final List<EmployeeModel> _webEmployees = [];
  static final List<DepartmentModel> _webDepartments = [
    DepartmentModel(id: 1, name: 'IT', description: 'Technical support and development'),
    DepartmentModel(id: 2, name: 'HR', description: 'Human resources and recruitment'),
  ];
  static final List<AttendanceModel> _webAttendance = [];
  static final List<SalaryHistoryModel> _webSalaryHistory = [];
  static final List<SupportQueryModel> _webQueries = [];
  static final List<MessageModel> _webMessages = [];

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (kIsWeb) throw UnsupportedError('SQLite not supported on Web – use mock logic.');
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ems_pro_v3.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE admins(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE departments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE employees(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        department_id INTEGER,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        role TEXT NOT NULL,
        salary REAL NOT NULL,
        joining_date TEXT NOT NULL,
        password TEXT NOT NULL,
        FOREIGN KEY (department_id) REFERENCES departments (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        check_in TEXT NOT NULL,
        check_out TEXT,
        status TEXT NOT NULL,
        FOREIGN KEY (employee_id) REFERENCES employees (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE salary_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        date_paid TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pending',
        FOREIGN KEY (employee_id) REFERENCES employees (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE queries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        employee_name TEXT NOT NULL,
        subject TEXT NOT NULL,
        message TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (employee_id) REFERENCES employees (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query_id INTEGER NOT NULL,
        sender_type TEXT NOT NULL,
        sender_id INTEGER NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (query_id) REFERENCES queries (id)
      )
    ''');

    // Seed
    await db.insert('admins', {'email': 'admin@test.com', 'password': 'admin123'});
    await db.insert('departments', {'name': 'IT', 'description': 'Tech and Development'});
    await db.insert('departments', {'name': 'HR', 'description': 'Human Resources'});
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<AdminModel?> getAdmin(String email, String password) async {
    if (kIsWeb) {
      try { return _webAdmins.firstWhere((a) => a.email == email && a.password == password); }
      catch (e) { return null; }
    }
    final db = await database;
    final maps = await db.query('admins', where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return maps.isNotEmpty ? AdminModel.fromMap(maps.first) : null;
  }

  Future<int> updateAdminPassword(int id, String newPassword) async {
    if (kIsWeb) {
      final idx = _webAdmins.indexWhere((a) => a.id == id);
      if (idx != -1) { _webAdmins[idx] = AdminModel(id: _webAdmins[idx].id, email: _webAdmins[idx].email, password: newPassword); return 1; }
      return 0;
    }
    final db = await database;
    return await db.update('admins', {'password': newPassword}, where: 'id = ?', whereArgs: [id]);
  }

  Future<EmployeeModel?> getEmployee(String email, String password) async {
    if (kIsWeb) {
      try { return _webEmployees.firstWhere((e) => e.email == email && e.password == password); }
      catch (e) { return null; }
    }
    final db = await database;
    final maps = await db.query('employees', where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return maps.isNotEmpty ? EmployeeModel.fromMap(maps.first) : null;
  }

  Future<EmployeeModel?> getEmployeeById(int id) async {
    if (kIsWeb) {
      try { return _webEmployees.firstWhere((e) => e.id == id); }
      catch (e) { return null; }
    }
    final db = await database;
    final maps = await db.query('employees', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? EmployeeModel.fromMap(maps.first) : null;
  }

  Future<int> updateEmployeePassword(int id, String newPassword) async {
    if (kIsWeb) {
      final idx = _webEmployees.indexWhere((e) => e.id == id);
      if (idx != -1) {
        final e = _webEmployees[idx];
        _webEmployees[idx] = EmployeeModel(id: e.id, departmentId: e.departmentId, name: e.name, email: e.email, phone: e.phone, role: e.role, salary: e.salary, joiningDate: e.joiningDate, password: newPassword);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update('employees', {'password': newPassword}, where: 'id = ?', whereArgs: [id]);
  }

  // ─── Departments ──────────────────────────────────────────────────────────

  Future<List<DepartmentModel>> getAllDepartments() async {
    if (kIsWeb) return List.from(_webDepartments);
    final db = await database;
    final maps = await db.query('departments');
    return maps.map((m) => DepartmentModel.fromMap(m)).toList();
  }

  Future<int> insertDepartment(DepartmentModel dept) async {
    if (kIsWeb) {
      final newId = (_webDepartments.isEmpty ? 0 : _webDepartments.last.id!) + 1;
      _webDepartments.add(DepartmentModel(id: newId, name: dept.name, description: dept.description));
      return newId;
    }
    final db = await database;
    return await db.insert('departments', dept.toMap());
  }

  Future<int> deleteDepartment(int id) async {
    if (kIsWeb) { _webDepartments.removeWhere((d) => d.id == id); return 1; }
    final db = await database;
    return await db.delete('departments', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Employees ────────────────────────────────────────────────────────────

  Future<List<EmployeeModel>> getAllEmployees() async {
    if (kIsWeb) return List.from(_webEmployees);
    final db = await database;
    final maps = await db.query('employees');
    return maps.map((m) => EmployeeModel.fromMap(m)).toList();
  }

  Future<int> insertEmployee(EmployeeModel employee) async {
    if (kIsWeb) {
      final newId = (_webEmployees.isEmpty ? 0 : _webEmployees.last.id!) + 1;
      _webEmployees.add(EmployeeModel(id: newId, departmentId: employee.departmentId, name: employee.name, email: employee.email, phone: employee.phone, role: employee.role, salary: employee.salary, joiningDate: employee.joiningDate, password: employee.password));
      return newId;
    }
    final db = await database;
    try { return await db.insert('employees', employee.toMap()); }
    catch (e) { return -1; }
  }

  Future<int> updateEmployee(EmployeeModel employee) async {
    if (kIsWeb) {
      final idx = _webEmployees.indexWhere((e) => e.id == employee.id);
      if (idx == -1) return 0;
      final existing = _webEmployees[idx];
      _webEmployees[idx] = EmployeeModel(
        id: employee.id, departmentId: employee.departmentId, name: employee.name,
        email: employee.email, phone: employee.phone, role: employee.role,
        salary: employee.salary, joiningDate: employee.joiningDate,
        password: employee.password.isNotEmpty ? employee.password : existing.password,
      );
      return 1;
    }
    final db = await database;
    final data = employee.toMap();
    if (employee.password.isEmpty) data.remove('password');
    return await db.update('employees', data, where: 'id = ?', whereArgs: [employee.id]);
  }

  Future<int> deleteEmployee(int id) async {
    if (kIsWeb) { _webEmployees.removeWhere((e) => e.id == id); return 1; }
    final db = await database;
    return await db.delete('employees', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Attendance ───────────────────────────────────────────────────────────

  Future<int> logAttendance(AttendanceModel attendance) async {
    if (kIsWeb) {
      final newId = (_webAttendance.isEmpty ? 0 : _webAttendance.last.id!) + 1;
      _webAttendance.add(AttendanceModel(id: newId, employeeId: attendance.employeeId, date: attendance.date, checkIn: attendance.checkIn, status: attendance.status));
      return newId;
    }
    final db = await database;
    return await db.insert('attendance', attendance.toMap());
  }

  Future<List<AttendanceModel>> getEmployeeAttendance(int empId) async {
    if (kIsWeb) return _webAttendance.where((a) => a.employeeId == empId).toList()..sort((a, b) => b.date.compareTo(a.date));
    final db = await database;
    final maps = await db.query('attendance', where: 'employee_id = ?', whereArgs: [empId], orderBy: 'date DESC');
    return maps.map((m) => AttendanceModel.fromMap(m)).toList();
  }

  Future<List<AttendanceModel>> getAllAttendance() async {
    if (kIsWeb) return List.from(_webAttendance);
    final db = await database;
    final maps = await db.query('attendance');
    return maps.map((m) => AttendanceModel.fromMap(m)).toList();
  }

  Future<int> getTodayAttendanceCount(String date) async {
    if (kIsWeb) return _webAttendance.where((a) => a.date == date).length;
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM attendance WHERE date = ?', [date]);
    return (res[0]['count'] ?? 0) as int;
  }

  // ─── Salary ───────────────────────────────────────────────────────────────

  Future<int> insertSalaryHistory(SalaryHistoryModel history) async {
    if (kIsWeb) {
      final newId = (_webSalaryHistory.isEmpty ? 0 : _webSalaryHistory.last.id!) + 1;
      _webSalaryHistory.add(SalaryHistoryModel(id: newId, employeeId: history.employeeId, amount: history.amount, month: history.month, datePaid: history.datePaid, status: history.status));
      return newId;
    }
    final db = await database;
    return await db.insert('salary_history', history.toMap());
  }

  Future<List<SalaryHistoryModel>> getAllSalaries() async {
    if (kIsWeb) return List.from(_webSalaryHistory);
    final db = await database;
    final maps = await db.query('salary_history');
    return maps.map((m) => SalaryHistoryModel.fromMap(m)).toList();
  }

  Future<List<SalaryHistoryModel>> getEmployeeSalaries(int empId) async {
    if (kIsWeb) return _webSalaryHistory.where((s) => s.employeeId == empId).toList();
    final db = await database;
    final maps = await db.query('salary_history', where: 'employee_id = ?', whereArgs: [empId]);
    return maps.map((m) => SalaryHistoryModel.fromMap(m)).toList();
  }

  Future<int> updateSalaryStatus(int historyId, String newStatus) async {
    if (kIsWeb) {
      final idx = _webSalaryHistory.indexWhere((s) => s.id == historyId);
      if (idx != -1) {
        final c = _webSalaryHistory[idx];
        _webSalaryHistory[idx] = SalaryHistoryModel(id: c.id, employeeId: c.employeeId, amount: c.amount, month: c.month, datePaid: c.datePaid, status: newStatus);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update('salary_history', {'status': newStatus}, where: 'id = ?', whereArgs: [historyId]);
  }

  // ─── Queries / Chat ───────────────────────────────────────────────────────

  Future<int> createQuery(SupportQueryModel query) async {
    if (kIsWeb) {
      final newId = (_webQueries.isEmpty ? 0 : _webQueries.last.id!) + 1;
      _webQueries.add(SupportQueryModel(id: newId, employeeId: query.employeeId, employeeName: query.employeeName, subject: query.subject, message: query.message, status: query.status, createdAt: query.createdAt));
      // Also insert first message
      if (query.message.isNotEmpty) {
        final msgId = (_webMessages.isEmpty ? 0 : _webMessages.last.id!) + 1;
        _webMessages.add(MessageModel(id: msgId, queryId: newId, senderType: 'Employee', senderId: query.employeeId, message: query.message, timestamp: query.createdAt));
      }
      return newId;
    }
    final db = await database;
    final queryId = await db.insert('queries', query.toMap());
    // Insert first message
    if (query.message.isNotEmpty) {
      await db.insert('messages', {
        'query_id': queryId,
        'sender_type': 'Employee',
        'sender_id': query.employeeId,
        'message': query.message,
        'timestamp': query.createdAt,
      });
    }
    return queryId;
  }

  Future<List<SupportQueryModel>> getAllQueries() async {
    if (kIsWeb) return List.from(_webQueries)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final db = await database;
    final maps = await db.query('queries', orderBy: 'created_at DESC');
    return maps.map((m) => SupportQueryModel.fromMap(m)).toList();
  }

  Future<List<SupportQueryModel>> getEmployeeQueries(int empId) async {
    if (kIsWeb) return _webQueries.where((q) => q.employeeId == empId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final db = await database;
    final maps = await db.query('queries', where: 'employee_id = ?', whereArgs: [empId], orderBy: 'created_at DESC');
    return maps.map((m) => SupportQueryModel.fromMap(m)).toList();
  }

  Future<int> updateQueryStatus(int queryId, String newStatus) async {
    if (kIsWeb) {
      final idx = _webQueries.indexWhere((q) => q.id == queryId);
      if (idx != -1) {
        final c = _webQueries[idx];
        _webQueries[idx] = SupportQueryModel(id: c.id, employeeId: c.employeeId, employeeName: c.employeeName, subject: c.subject, message: c.message, status: newStatus, createdAt: c.createdAt);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update('queries', {'status': newStatus}, where: 'id = ?', whereArgs: [queryId]);
  }

  Future<int> insertMessage(MessageModel msg) async {
    if (kIsWeb) {
      final newId = (_webMessages.isEmpty ? 0 : _webMessages.last.id!) + 1;
      _webMessages.add(MessageModel(id: newId, queryId: msg.queryId, senderType: msg.senderType, senderId: msg.senderId, message: msg.message, timestamp: msg.timestamp));
      return newId;
    }
    final db = await database;
    return await db.insert('messages', msg.toMap());
  }

  Future<List<MessageModel>> getQueryMessages(int queryId) async {
    if (kIsWeb) return _webMessages.where((m) => m.queryId == queryId).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final db = await database;
    final maps = await db.query('messages', where: 'query_id = ?', whereArgs: [queryId], orderBy: 'timestamp ASC');
    return maps.map((m) => MessageModel.fromMap(m)).toList();
  }

  // ─── Dashboard Stats ──────────────────────────────────────────────────────

  Future<Map<String, int>> getDepartmentEmployeeCounts() async {
    if (kIsWeb) {
      final map = <String, int>{};
      for (var d in _webDepartments) {
        map[d.name] = _webEmployees.where((e) => e.departmentId == d.id).length;
      }
      return map;
    }
    final db = await database;
    final res = await db.rawQuery('''
      SELECT d.name, COUNT(e.id) as count
      FROM departments d
      LEFT JOIN employees e ON d.id = e.department_id
      GROUP BY d.id
    ''');
    final map = <String, int>{};
    for (var r in res) { map[r['name'] as String] = (r['count'] ?? 0) as int; }
    return map;
  }

  Future<double> getTotalSalaryExpense() async {
    if (kIsWeb) return _webEmployees.fold<double>(0.0, (sum, e) => sum + e.salary);
    final db = await database;
    final res = await db.rawQuery('SELECT SUM(salary) as total FROM employees');
    return ((res[0]['total'] ?? 0.0) as num).toDouble();
  }

  Future<int> getTotalEmployeesCount() async {
    if (kIsWeb) return _webEmployees.length;
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM employees');
    return (res[0]['count'] ?? 0) as int;
  }
}
