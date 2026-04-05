import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/query_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/salary_provider.dart';
import '../../models/department_model.dart';
import '../../models/query_model.dart';
import '../../widgets/layout_scaffold.dart';
import '../../widgets/stat_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'manage_employee_screen.dart';
import 'department_employees_screen.dart';
import '../shared/chat_detail_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<SidebarItem> _sidebarItems = [
    const SidebarItem(title: 'Dashboard', icon: Icons.dashboard_outlined),
    const SidebarItem(title: 'Employees', icon: Icons.people_outline),
    const SidebarItem(title: 'Departments', icon: Icons.business_outlined),
    const SidebarItem(title: 'Attendance', icon: Icons.event_available_outlined),
    const SidebarItem(title: 'Salary', icon: Icons.monetization_on_outlined),
    const SidebarItem(title: 'Queries', icon: Icons.chat_bubble_outline),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      context.read<EmployeeProvider>().fetchEmployees();
      context.read<EmployeeProvider>().fetchDashboardStats();
      context.read<DepartmentProvider>().fetchDepartments();
      context.read<QueryProvider>().fetchAllQueries();
      context.read<AttendanceProvider>().fetchAllAttendance();
      context.read<SalaryProvider>().fetchAllSalaries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutScaffold(
      title: _sidebarItems[_selectedIndex].title,
      selectedIndex: _selectedIndex,
      onIndexSelected: (index) => setState(() => _selectedIndex = index),
      items: _sidebarItems,
      body: _buildCurrentModule(),
    );
  }

  Widget _buildCurrentModule() {
    switch (_selectedIndex) {
      case 0: return _buildDashboardView();
      case 1: return _buildEmployeesModule();
      case 2: return _buildDepartmentsModule();
      case 3: return _buildAttendanceModule();
      case 4: return _buildSalaryModule();
      case 5: return _buildQueriesModule();
      default: return Container();
    }
  }

  // ─── Dashboard ────────────────────────────────────────────────────────────

  Widget _buildDashboardView() {
    return Consumer<EmployeeProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 40) / 3;
                  if (cardWidth < 180) {
                    return Column(
                      children: [
                        StatCard(title: 'Total Employees', value: provider.totalEmployees.toString(), icon: Icons.people_alt_rounded, color: const Color(0xFF4F46E5)),
                        const SizedBox(height: 16),
                        StatCard(title: 'Present Today', value: provider.todayPresentCount.toString(), icon: Icons.how_to_reg_rounded, color: const Color(0xFF10B981)),
                        const SizedBox(height: 16),
                        StatCard(title: 'Total Salary', value: '\$${(provider.totalSalaryExpense / 1000).toStringAsFixed(1)}k', icon: Icons.account_balance_wallet_rounded, color: const Color(0xFFF59E0B)),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: StatCard(title: 'Total Employees', value: provider.totalEmployees.toString(), icon: Icons.people_alt_rounded, color: const Color(0xFF4F46E5))),
                      const SizedBox(width: 20),
                      Expanded(child: StatCard(title: 'Present Today', value: provider.todayPresentCount.toString(), icon: Icons.how_to_reg_rounded, color: const Color(0xFF10B981))),
                      const SizedBox(width: 20),
                      Expanded(child: StatCard(title: 'Total Salary', value: '\$${(provider.totalSalaryExpense / 1000).toStringAsFixed(1)}k', icon: Icons.account_balance_wallet_rounded, color: const Color(0xFFF59E0B))),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              _buildChartSection(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartSection(BuildContext context) {
    return Consumer<EmployeeProvider>(
      builder: (context, empProvider, _) {
        // Department pie chart data
        final List<PieChartSectionData> deptSections = [];
        final colors = [const Color(0xFF4F46E5), const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF8B5CF6)];
        int i = 0;
        empProvider.deptCounts.forEach((deptName, count) {
          if (count > 0) {
            deptSections.add(PieChartSectionData(
              value: count.toDouble(), title: '$deptName\n$count',
              color: colors[i % colors.length], radius: 60,
              titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ));
            i++;
          }
        });
        if (deptSections.isEmpty) {
          deptSections.add(PieChartSectionData(value: 1, title: 'No Data', color: Colors.grey.shade300, radius: 60));
        }

        final presentCount = empProvider.todayPresentCount;
        final absentCount = (empProvider.totalEmployees - presentCount).clamp(0, empProvider.totalEmployees);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isVertical = constraints.maxWidth < 700;
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                SizedBox(
                  width: isVertical ? constraints.maxWidth : (constraints.maxWidth - 20) * 0.6,
                  child: _chartCard(
                    title: "Today's Attendance",
                    subtitle: '$presentCount Present · $absentCount Absent',
                    child: SizedBox(
                      height: 260,
                      child: BarChart(BarChartData(
                        maxY: (empProvider.totalEmployees > 0) ? empProvider.totalEmployees.toDouble() + 2 : 10,
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: presentCount.toDouble(), color: const Color(0xFF10B981), width: 40, borderRadius: BorderRadius.circular(6))]),
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: absentCount.toDouble(), color: const Color(0xFFEF4444), width: 40, borderRadius: BorderRadius.circular(6))]),
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(v.toInt() == 0 ? 'Present' : 'Absent', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            );
                          })),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                      )),
                    ),
                  ),
                ),
                SizedBox(
                  width: isVertical ? constraints.maxWidth : (constraints.maxWidth - 20) * 0.35,
                  child: _chartCard(
                    title: 'Department Split',
                    subtitle: '${empProvider.totalEmployees} employees total',
                    child: SizedBox(
                      height: 260,
                      child: PieChart(PieChartData(
                        sections: deptSections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 3,
                      )),
                    ),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _chartCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ─── Employees ────────────────────────────────────────────────────────────

  Widget _buildEmployeesModule() {
    return Consumer2<EmployeeProvider, DepartmentProvider>(
      builder: (context, empProvider, deptProvider, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => empProvider.setSearch(v),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true, fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int?>(
                    value: null,
                    hint: const Text('Filter by Dept'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Departments')),
                      ...deptProvider.departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                    ],
                    onChanged: (val) => empProvider.setDepartmentFilter(val),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageEmployeeScreen()));
                      empProvider.fetchEmployees();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Employee'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: empProvider.filteredEmployees.isEmpty
                    ? Center(child: Text(empProvider.employees.isEmpty ? 'No employees found. Add your first!' : 'No results for current filter.', style: const TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        itemCount: empProvider.filteredEmployees.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final emp = empProvider.filteredEmployees[index];
                          return _employeeCard(context, emp, empProvider);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _employeeCard(BuildContext context, emp, EmployeeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
            radius: 24,
            child: Text(emp.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${emp.role} · ${emp.email}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ],
            ),
          ),
          Text('\$${emp.salary.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF10B981))),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF4F46E5)),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => ManageEmployeeScreen(employee: emp)));
              provider.fetchEmployees();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () async {
              bool? confirmed = await _showDeleteConfirm(context, emp.name);
              if (confirmed == true) provider.deleteEmployee(emp.id!);
            },
          ),
        ],
      ),
    );
  }

  // ─── Departments ──────────────────────────────────────────────────────────

  Widget _buildDepartmentsModule() {
    return Consumer<DepartmentProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Company Departments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDeptDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New Department'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: provider.departments.isEmpty
                    ? const Center(child: Text('No departments defined yet.'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 1000 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const ScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount, 
                              childAspectRatio: 1.4, 
                              crossAxisSpacing: 16, 
                              mainAxisSpacing: 16
                            ),
                            itemCount: provider.departments.length,
                            itemBuilder: (context, index) {
                              final d = provider.departments[index];
                              return _deptCard(context, d);
                            },
                          );
                        }
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _deptCard(BuildContext context, DepartmentModel d) {
    final iconColors = [const Color(0xFF4F46E5), const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFFEF4444)];
    final color = iconColors[d.id! % iconColors.length];
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DepartmentEmployeesScreen(department: d))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.business, color: color, size: 18)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
            ]),
            const SizedBox(height: 10),
            Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(d.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ─── Attendance ───────────────────────────────────────────────────────────

  Widget _buildAttendanceModule() {
    return Consumer2<EmployeeProvider, AttendanceProvider>(
      builder: (context, empProvider, attProvider, _) {
        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month}-${now.day}';
        final todayLogs = attProvider.allAttendance.where((a) => a.date == todayStr).toList();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Today\'s Attendance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${now.day}/${now.month}/${now.year}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                  ]),
                  const Spacer(),
                  _attBadge('Present', todayLogs.length.toString(), const Color(0xFF10B981)),
                  const SizedBox(width: 12),
                  _attBadge('Absent', (empProvider.employees.length - todayLogs.length).toString(), const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: empProvider.employees.isEmpty
                    ? const Center(child: Text('No employees found.'))
                    : ListView.separated(
                        itemCount: empProvider.employees.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final emp = empProvider.employees[index];
                          final log = todayLogs.where((a) => a.employeeId == emp.id).firstOrNull;
                          final isPresent = log != null;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isPresent ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                                  child: Icon(isPresent ? Icons.check : Icons.close, color: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  Text(emp.role, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                ])),
                                if (isPresent) Text('In: ${log.checkIn}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isPresent ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(isPresent ? 'Present' : 'Absent', style: TextStyle(color: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 13)),
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
    );
  }

  Widget _attBadge(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(count, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  // ─── Salary ───────────────────────────────────────────────────────────────

  Widget _buildSalaryModule() {
    return Consumer2<EmployeeProvider, SalaryProvider>(
      builder: (context, empProvider, salaryProvider, _) {
        // Filter state
        return StatefulBuilder(
          builder: (context, setSalaryState) {
            String filter = 'All';
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Payroll Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ...['All', 'Pending', 'In Process', 'Paid'].map((s) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(s),
                          selected: filter == s,
                          onSelected: (sel) => setSalaryState(() => filter = sel ? s : 'All'),
                          selectedColor: const Color(0xFF4F46E5),
                          labelStyle: TextStyle(color: filter == s ? Colors.white : null),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: empProvider.employees.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final emp = empProvider.employees[index];
                        final history = salaryProvider.allSalaries.where((s) => s.employeeId == emp.id).lastOrNull;
                        final currentStatus = history?.status ?? 'Not Processed';

                        // Filter
                        if (filter != 'All' && currentStatus != filter) return const SizedBox.shrink();

                        final statusColor = currentStatus == 'Paid' ? const Color(0xFF10B981)
                            : currentStatus == 'In Process' ? const Color(0xFFF59E0B)
                            : currentStatus == 'Pending' ? const Color(0xFFEF4444)
                            : const Color(0xFF94A3B8);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                                child: Text(emp.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                Text('Base: \$${emp.salary.toStringAsFixed(0)}/month', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                child: Text(currentStatus, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
                              ),
                              const SizedBox(width: 12),
                              if (currentStatus == 'Not Processed')
                                ElevatedButton(
                                  onPressed: () {
                                    final monthStr = '${DateTime.now().year}-${DateTime.now().month}';
                                    context.read<SalaryProvider>().paySalary(emp.id!, emp.salary, monthStr);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                                  child: const Text('Process'),
                                )
                              else
                                DropdownButton<String>(
                                  value: currentStatus,
                                  underline: const SizedBox(),
                                  items: ['Pending', 'In Process', 'Paid'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  onChanged: (val) {
                                    if (val != null && history != null) {
                                      context.read<SalaryProvider>().updateSalaryStatus(history.id!, val);
                                    }
                                  },
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
        );
      },
    );
  }

  // ─── Queries ──────────────────────────────────────────────────────────────

  Widget _buildQueriesModule() {
    return Consumer<QueryProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Support Queries', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Search + filter row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => provider.setSearchQuery(v),
                      decoration: InputDecoration(
                        hintText: 'Search by employee name or subject...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true, fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...['All', 'Pending', 'In Process', 'Resolved'].map((s) {
                    final selected = provider.statusFilter == s;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(s),
                        selected: selected,
                        onSelected: (sel) => provider.setStatusFilter(sel ? s : 'All'),
                        selectedColor: _queryStatusColor(s),
                        labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: provider.filteredQueries.isEmpty
                    ? const Center(child: Text('No queries found.', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        itemCount: provider.filteredQueries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final q = provider.filteredQueries[index];
                          return _queryCard(context, q, provider);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _queryCard(BuildContext context, SupportQueryModel q, QueryProvider provider) {
    final statusColor = _queryStatusColor(q.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            child: Text(q.employeeName.isNotEmpty ? q.employeeName[0].toUpperCase() : '?', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(q.employeeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(q.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(q.subject.isNotEmpty ? q.subject : '(No subject)', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 4),
                Text(q.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 4),
                Text(_formatDate(q.createdAt), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(query: q, currentUserId: 0, senderType: 'Admin'))),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                child: const Text('Reply'),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: q.status,
                underline: const SizedBox(),
                icon: const Icon(Icons.expand_more, size: 18),
                items: ['Pending', 'In Process', 'Resolved'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) { if (val != null) provider.updateQueryStatus(q.id!, val); },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _queryStatusColor(String status) {
    switch (status) {
      case 'Pending': return const Color(0xFFEF4444);
      case 'In Process': return const Color(0xFFF59E0B);
      case 'Resolved': return const Color(0xFF10B981);
      default: return const Color(0xFF64748B);
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<bool?> _showDeleteConfirm(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Delete'),
        content: Text('Remove $name from the system?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddDeptDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Department Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await context.read<DepartmentProvider>().addDepartment(DepartmentModel(name: nameController.text.trim(), description: descController.text.trim()));
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
