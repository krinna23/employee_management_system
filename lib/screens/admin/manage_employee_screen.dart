import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/department_provider.dart';
import '../../models/employee_model.dart';
import '../../widgets/custom_textfield.dart';

class ManageEmployeeScreen extends StatefulWidget {
  final EmployeeModel? employee;

  const ManageEmployeeScreen({Key? key, this.employee}) : super(key: key);

  @override
  State<ManageEmployeeScreen> createState() => _ManageEmployeeScreenState();
}

class _ManageEmployeeScreenState extends State<ManageEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();
  final _salaryController = TextEditingController();
  final _passwordController = TextEditingController();
  
  int? _selectedDepartmentId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      _emailController.text = widget.employee!.email;
      _phoneController.text = widget.employee!.phone;
      _roleController.text = widget.employee!.role;
      _salaryController.text = widget.employee!.salary.toString();
      _passwordController.text = widget.employee!.password;
      _selectedDepartmentId = widget.employee!.departmentId;
    }
    _loadDepartments();
  }

  void _loadDepartments() {
    Future.microtask(() => context.read<DepartmentProvider>().fetchDepartments());
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    final empProvider = context.read<EmployeeProvider>();

    final employee = EmployeeModel(
      id: widget.employee?.id,
      departmentId: _selectedDepartmentId,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _roleController.text.trim(),
      salary: double.tryParse(_salaryController.text.trim()) ?? 0,
      joiningDate: widget.employee?.joiningDate ?? DateTime.now().toIso8601String().split('T')[0],
      password: _passwordController.text,
    );

    bool success;
    if (widget.employee == null) {
      int id = await empProvider.addEmployee(employee);
      success = id != -1;
    } else {
      success = await empProvider.updateEmployee(employee);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save employee. Email may already exist.'), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;
    final departments = context.watch<DepartmentProvider>().departments;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Update Employee' : 'New Employee'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        hintText: 'John Doe',
                        prefixIcon: Icons.person_outline,
                        validator: (v) => v!.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _emailController,
                              labelText: 'Email Address',
                              hintText: 'john@company.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v!.isEmpty ? 'Email is required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _phoneController,
                              labelText: 'Phone Number',
                              hintText: '+1 234 567 890',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v!.isEmpty ? 'Phone is required' : null,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 64),
                      const Text('Employment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      if (departments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'You haven\'t added any departments yet. Please add one in the Departments tab first.',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _selectedDepartmentId,
                                decoration: const InputDecoration(
                                  labelText: 'Department',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.business_outlined),
                                ),
                                items: departments.map((d) {
                                  return DropdownMenuItem<int>(
                                    value: d.id,
                                    child: Text(d.name),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedDepartmentId = val),
                                validator: (v) => v == null ? 'Please select a department' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _roleController,
                                labelText: 'Job Role',
                                hintText: 'e.g. Senior Developer',
                                prefixIcon: Icons.work_outline,
                                validator: (v) => v!.isEmpty ? 'Role is required' : null,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _salaryController,
                              labelText: 'Monthly Salary',
                              hintText: '5000',
                              prefixIcon: Icons.monetization_on_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Salary is required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _passwordController,
                              labelText: isEditing ? 'Update Password' : 'Login Password',
                              hintText: isEditing ? 'Leave empty to keep unchanged' : 'Min. 6 chars',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              validator: (v) {
                                if (!isEditing && (v == null || v.length < 6)) {
                                  return 'Min. 6 chars required';
                                }
                                if (isEditing && v != null && v.isNotEmpty && v.length < 6) {
                                  return 'Min. 6 chars required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: (_isLoading || departments.isEmpty) ? null : _saveEmployee,
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(isEditing ? 'Update Employee Record' : 'Create Employee Profile', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
