import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../providers/cost_center_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/ledger_provider.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeProvider>(context, listen: false).fetchEmployees();
      Provider.of<CostCenterProvider>(
        context,
        listen: false,
      ).fetchCostCenters();
      Provider.of<LedgerProvider>(context, listen: false).fetchLedgers();
    });
  }

  void _showAddEmployeeDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const AddEmployeeDialog());
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => employeeProvider.fetchEmployees(),
          ),
        ],
      ),
      body: employeeProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : employeeProvider.errorMessage != null
          ? Center(
              child: Text(
                'Error: ${employeeProvider.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : employeeProvider.employees.isEmpty
          ? const Center(
              child: Text(
                'No employees found. Click + to add one.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: employeeProvider.employees.length,
              itemBuilder: (ctx, index) {
                final employee = employeeProvider.employees[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                employee.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: employee.isActive
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                employee.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: employee.isActive
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email: ${employee.email} ${employee.phone != null ? '• Phone: ${employee.phone}' : ''}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Department: ${employee.department ?? 'N/A'} • Designation: ${employee.designation ?? 'N/A'}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildInfoChip(
                              'Base: \$${employee.baseSalary.toStringAsFixed(2)}',
                              Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              'Allowances: \$${employee.allowances.toStringAsFixed(2)}',
                              Colors.green,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              'Deductions: \$${employee.deductions.toStringAsFixed(2)}',
                              Colors.orange,
                            ),
                          ],
                        ),
                        if (employee.bankAccount != null &&
                            employee.bankAccount!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Bank Account: ${employee.bankAccount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEmployeeDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class AddEmployeeDialog extends StatefulWidget {
  const AddEmployeeDialog({super.key});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  final _baseSalaryController = TextEditingController();
  final _allowancesController = TextEditingController(text: '0.0');
  final _deductionsController = TextEditingController(text: '0.0');
  final _bankAccountController = TextEditingController();

  String? _selectedLedgerId;
  String? _selectedCostCenterId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    _baseSalaryController.dispose();
    _allowancesController.dispose();
    _deductionsController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final employeeProvider = Provider.of<EmployeeProvider>(
      context,
      listen: false,
    );

    final success = await employeeProvider.addEmployee(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      department: _departmentController.text.trim().isEmpty
          ? null
          : _departmentController.text.trim(),
      designation: _designationController.text.trim().isEmpty
          ? null
          : _designationController.text.trim(),
      baseSalary: double.tryParse(_baseSalaryController.text.trim()) ?? 0.0,
      allowances: double.tryParse(_allowancesController.text.trim()) ?? 0.0,
      deductions: double.tryParse(_deductionsController.text.trim()) ?? 0.0,
      bankAccount: _bankAccountController.text.trim().isEmpty
          ? null
          : _bankAccountController.text.trim(),
      ledgerId: _selectedLedgerId,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee added successfully!')),
      );
    } else if (mounted && employeeProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${employeeProvider.errorMessage}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledgerProvider = Provider.of<LedgerProvider>(context);
    final costCenterProvider = Provider.of<CostCenterProvider>(context);

    return AlertDialog(
      title: const Text('Add Employee'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Please enter name' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Please enter email' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                TextFormField(
                  controller: _designationController,
                  decoration: const InputDecoration(labelText: 'Designation'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _baseSalaryController,
                        decoration: const InputDecoration(
                          labelText: 'Base Salary *',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(val) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _allowancesController,
                        decoration: const InputDecoration(
                          labelText: 'Allowances',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _deductionsController,
                        decoration: const InputDecoration(
                          labelText: 'Deductions',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _bankAccountController,
                        decoration: const InputDecoration(
                          labelText: 'Bank Account',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Ledger Mapping Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedLedgerId,
                  decoration: const InputDecoration(
                    labelText: 'Linked Employee Ledger',
                    helperText: 'For payroll liabilities',
                  ),
                  items: ledgerProvider.ledgers.map((ledger) {
                    return DropdownMenuItem<String>(
                      value: ledger.id,
                      child: Text(ledger.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedLedgerId = val;
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Cost Center Tag Assignment Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCostCenterId,
                  decoration: const InputDecoration(
                    labelText: 'Cost Center Tag',
                    helperText: 'Assign employee to department cost center',
                  ),
                  items: costCenterProvider.costCenters.map((cc) {
                    return DropdownMenuItem<String>(
                      value: cc.id,
                      child: Text(cc.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCostCenterId = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Employee'),
        ),
      ],
    );
  }
}
