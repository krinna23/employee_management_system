import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/salary_provider.dart';
import '../../providers/query_provider.dart';
import '../../models/employee_model.dart';
import '../../widgets/layout_scaffold.dart';
import '../shared/chat_detail_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  final int employeeId;
  const EmployeeDashboard({Key? key, required this.employeeId}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;
  final TextEditingController _passController = TextEditingController();

  final List<SidebarItem> _sidebarItems = [
    const SidebarItem(title: 'Home', icon: Icons.home_outlined),
    const SidebarItem(title: 'Attendance', icon: Icons.event_available_outlined),
    const SidebarItem(title: 'Salary', icon: Icons.monetization_on_outlined),
    const SidebarItem(title: 'Support', icon: Icons.help_outline),
    const SidebarItem(title: 'Profile', icon: Icons.person_outline),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
  }

  void _loadData() {
    Future.microtask(() {
      context.read<AttendanceProvider>().fetchEmployeeAttendance(widget.employeeId);
      context.read<SalaryProvider>().fetchEmployeeSalaries(widget.employeeId);
      context.read<QueryProvider>().fetchEmployeeQueries(widget.employeeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final employee = auth.employee;
        if (employee == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return LayoutScaffold(
          title: _sidebarItems[_selectedIndex].title,
          selectedIndex: _selectedIndex,
          onIndexSelected: (index) => setState(() => _selectedIndex = index),
          items: _sidebarItems,
          body: _buildCurrentModule(employee),
        );
      },
    );
  }

  Widget _buildCurrentModule(EmployeeModel employee) {
    switch (_selectedIndex) {
      case 0: return _buildHomeView(employee);
      case 1: return _buildAttendanceView();
      case 2: return _buildSalaryView();
      case 3: return _buildSupportView(employee);
      case 4: return _buildProfileView(employee);
      default: return Container();
    }
  }

  // ─── Home ─────────────────────────────────────────────────────────────────

  Widget _buildHomeView(EmployeeModel employee) {
    return Consumer<AttendanceProvider>(
      builder: (context, attProvider, _) {
        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month}-${now.day}';
        final todayLog = attProvider.userAttendance.where((a) => a.date == todayStr).firstOrNull;
        final checkedIn = todayLog != null;

        // Calculate monthly attendance %
        final thisMonth = '${now.year}-${now.month}';
        final monthLogs = attProvider.userAttendance.where((a) => a.date.startsWith(thisMonth.length == 6 ? thisMonth : thisMonth)).length;
        final workingDays = now.day; // Approx
        final attPct = workingDays > 0 ? ((monthLogs / workingDays) * 100).clamp(0, 100).round() : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, ${employee.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(employee.role, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(employee.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats
              Row(
                children: [
                  Expanded(child: _empStatCard('Today', checkedIn ? 'Present' : 'Absent', checkedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444), checkedIn ? Icons.check_circle_outline : Icons.cancel_outlined)),
                  const SizedBox(width: 16),
                  Expanded(child: _empStatCard('Monthly', '$attPct%', const Color(0xFF4F46E5), Icons.calendar_month_outlined)),
                  const SizedBox(width: 16),
                  Expanded(child: _empStatCard('Salary', '\$${employee.salary.toStringAsFixed(0)}', const Color(0xFFF59E0B), Icons.monetization_on_outlined)),
                ],
              ),
              const SizedBox(height: 24),

              // Check-in button
              if (!checkedIn)
                ElevatedButton.icon(
                  onPressed: () async {
                    bool success = await context.read<AttendanceProvider>().checkIn(widget.employeeId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '✅ Checked in successfully!' : '❌ Already checked in for today.'),
                          backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      );
                      if (success) setState(() {});
                    }
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Mark Attendance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    Text('Checked in at ${todayLog.checkIn}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _empStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 8))],
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        ],
      ),
    );
  }

  // ─── Attendance ───────────────────────────────────────────────────────────

  Widget _buildAttendanceView() {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        if (provider.userAttendance.isEmpty) {
          return const Center(child: Text('No attendance records found.', style: TextStyle(color: Color(0xFF94A3B8))));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: provider.userAttendance.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final log = provider.userAttendance[index];
            final isLate = log.status == 'Late';
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
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isLate ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(log.date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text('Check In: ${log.checkIn}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isLate ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(log.status, style: TextStyle(color: isLate ? const Color(0xFFF59E0B) : const Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Salary ───────────────────────────────────────────────────────────────

  Widget _buildSalaryView() {
    return Consumer<SalaryProvider>(
      builder: (context, provider, _) {
        if (provider.userSalaries.isEmpty) {
          return const Center(child: Text('No salary history found.', style: TextStyle(color: Color(0xFF94A3B8))));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: provider.userSalaries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final sal = provider.userSalaries[index];
            final statusColor = sal.status == 'Paid' ? const Color(0xFF10B981)
                : sal.status == 'In Process' ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444);
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.account_balance_wallet_rounded, color: statusColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(sal.month, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Processed on: ${sal.datePaid}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('\$${sal.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(sal.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11)),
                    ),
                  ]),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Support ──────────────────────────────────────────────────────────────

  Widget _buildSupportView(EmployeeModel employee) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('My Queries', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showRaiseQueryDialog(employee),
                icon: const Icon(Icons.add),
                label: const Text('New Query'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<QueryProvider>(
              builder: (context, provider, _) {
                if (provider.userQueries.isEmpty) {
                  return const Center(child: Text('No queries raised yet.', style: TextStyle(color: Color(0xFF94A3B8))));
                }
                return ListView.separated(
                  itemCount: provider.userQueries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final q = provider.userQueries[index];
                    final statusColor = q.status == 'Resolved' ? const Color(0xFF10B981)
                        : q.status == 'In Process' ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444);
                    return InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(query: q, currentUserId: widget.employeeId, senderType: 'Employee'),
                      )),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                          border: Border(left: BorderSide(color: statusColor, width: 4)),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(q.subject.isNotEmpty ? q.subject : '(No subject)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(q.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                            ])),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: Text(q.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11)),
                              ),
                              const SizedBox(height: 8),
                              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                            ]),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRaiseQueryDialog(EmployeeModel employee) {
    final subjectController = TextEditingController();
    final msgController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Raise Support Query'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject (optional)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: msgController, maxLines: 3, decoration: const InputDecoration(labelText: 'Your message *', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (msgController.text.isNotEmpty) {
                await context.read<QueryProvider>().raiseQuery(
                  widget.employeeId, employee.name,
                  subjectController.text.trim().isNotEmpty ? subjectController.text.trim() : 'General Query',
                  msgController.text.trim(),
                );
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  Widget _buildProfileView(EmployeeModel employee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Center(child: Text(employee.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 16),
                Text(employee.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(employee.role, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                _detailRow(Icons.email_outlined, 'Email', employee.email),
                _detailRow(Icons.phone_outlined, 'Phone', employee.phone),
                _detailRow(Icons.monetization_on_outlined, 'Salary', '\$${employee.salary.toStringAsFixed(0)}/month'),
                _detailRow(Icons.calendar_today_outlined, 'Joined', employee.joiningDate),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Change password card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.lock_outline, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.key_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_passController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
                        return;
                      }
                      bool success = await context.read<AuthProvider>().changePassword(_passController.text);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? '✅ Password updated!' : '❌ Failed to update password'), backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444)));
                        _passController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        const SizedBox(width: 12),
        Text('$label:', style: const TextStyle(color: Color(0xFF64748B))),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ]),
    );
  }
}
