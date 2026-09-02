import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payroll.dart';
import '../providers/employee_provider.dart';
import '../providers/payroll_provider.dart';

class PayrollProcessingScreen extends StatefulWidget {
  const PayrollProcessingScreen({super.key});

  @override
  State<PayrollProcessingScreen> createState() =>
      _PayrollProcessingScreenState();
}

class _PayrollProcessingScreenState extends State<PayrollProcessingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PayrollProvider>(context, listen: false).fetchPayrolls();
      Provider.of<EmployeeProvider>(context, listen: false).fetchEmployees();
    });
  }

  void _showGeneratePayrollDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const GeneratePayrollDialog(),
    );
  }

  Future<void> _postPayroll(BuildContext context, String payrollId) async {
    final payrollProvider = Provider.of<PayrollProvider>(
      context,
      listen: false,
    );
    final success = await payrollProvider.postPayrollToAccounting(payrollId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payroll voucher posted and ledgers updated successfully!',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error posting payroll: ${payrollProvider.errorMessage}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payrollProvider = Provider.of<PayrollProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Processing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => payrollProvider.fetchPayrolls(),
          ),
        ],
      ),
      body: payrollProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : payrollProvider.errorMessage != null
          ? Center(
              child: Text(
                'Error: ${payrollProvider.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : payrollProvider.payrolls.isEmpty
          ? const Center(
              child: Text(
                'No payroll batches found. Click + to generate one.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payrollProvider.payrolls.length,
              itemBuilder: (ctx, index) {
                final payroll = payrollProvider.payrolls[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Text(
                          'Period: ${payroll.payPeriod}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: payroll.status == 'posted'
                                ? Colors.green.shade100
                                : Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            payroll.status.toUpperCase(),
                            style: TextStyle(
                              color: payroll.status == 'posted'
                                  ? Colors.green.shade800
                                  : Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Total Net Pay: \$${payroll.totalAmount.toStringAsFixed(2)} • Items: ${payroll.items.length}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    trailing: payroll.status != 'posted'
                        ? ElevatedButton.icon(
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('Post Payroll Voucher'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _postPayroll(context, payroll.id),
                          )
                        : const Chip(
                            label: Text('Posted'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Line-Item Calculations Preview:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Table(
                              border: TableBorder.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(1),
                                2: FlexColumnWidth(1),
                                3: FlexColumnWidth(1),
                                4: FlexColumnWidth(1),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                  ),
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Employee',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Base',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Allow.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Deduct.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Net Pay',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ...payroll.items.map((item) {
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          item.employeeName ?? 'Employee',
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          '\$${item.baseSalary.toStringAsFixed(2)}',
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          '\$${item.allowances.toStringAsFixed(2)}',
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          '\$${item.deductions.toStringAsFixed(2)}',
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          '\$${item.netPay.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGeneratePayrollDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GeneratePayrollDialog extends StatefulWidget {
  const GeneratePayrollDialog({super.key});

  @override
  State<GeneratePayrollDialog> createState() => _GeneratePayrollDialogState();
}

class _GeneratePayrollDialogState extends State<GeneratePayrollDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _payPeriodController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final formattedPeriod =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _payPeriodController = TextEditingController(text: formattedPeriod);
  }

  @override
  void dispose() {
    _payPeriodController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final payrollProvider = Provider.of<PayrollProvider>(
      context,
      listen: false,
    );
    final success = await payrollProvider.generatePayroll(
      _payPeriodController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payroll batch generated successfully!')),
      );
    } else if (mounted && payrollProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${payrollProvider.errorMessage}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Monthly Payroll'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will generate a payroll batch for all active employees based on their configured salaries, allowances, and deductions.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _payPeriodController,
              decoration: const InputDecoration(
                labelText: 'Pay Period (YYYY-MM)',
                helperText: 'e.g. 2026-09',
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter pay period';
                }
                if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(val)) {
                  return 'Format must be YYYY-MM';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _generate,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate'),
        ),
      ],
    );
  }
}
