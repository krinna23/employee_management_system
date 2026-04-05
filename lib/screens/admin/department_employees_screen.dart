import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_provider.dart';
import '../../models/department_model.dart';
import 'manage_employee_screen.dart';

class DepartmentEmployeesScreen extends StatelessWidget {
  final DepartmentModel department;

  const DepartmentEmployeesScreen({Key? key, required this.department}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${department.name} Department', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(department.description, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, _) {
          final deptEmployees = provider.employees.where((e) => e.departmentId == department.id).toList();

          if (deptEmployees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No employees in this department yet.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${deptEmployees.length} Employee${deptEmployees.length != 1 ? 's' : ''}', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: deptEmployees.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final emp = deptEmployees[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Text(emp.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(emp.role, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                  Text(emp.email, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('\$${emp.salary.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 15)),
                                const Text('/month', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF4F46E5)),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageEmployeeScreen(employee: emp))),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
