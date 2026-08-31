import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ledger.dart';
import '../providers/ledger_provider.dart';
import '../providers/voucher_provider.dart';

class VoucherEntryDialog extends StatefulWidget {
  const VoucherEntryDialog({super.key});

  @override
  State<VoucherEntryDialog> createState() => _VoucherEntryDialogState();
}

class _VoucherEntryDialogState extends State<VoucherEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  String _voucherType = 'Payment'; // Payment, Receipt, Contra, Journal
  final _voucherNumberController = TextEditingController();
  final _narrationController = TextEditingController();
  DateTime _date = DateTime.now();

  // List of entry rows: each row has ledgerId, isDebit (true = Debit, false = Credit), amount, description
  final List<_VoucherRowItem> _rows = [_VoucherRowItem(), _VoucherRowItem()];

  @override
  void initState() {
    super.initState();
    // Generate default voucher number
    _voucherNumberController.text =
        'V-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _voucherNumberController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  double get _totalDebit {
    double sum = 0;
    for (var row in _rows) {
      if (row.isDebit) {
        sum += double.tryParse(row.amountController.text) ?? 0.0;
      }
    }
    return sum;
  }

  double get _totalCredit {
    double sum = 0;
    for (var row in _rows) {
      if (!row.isDebit) {
        sum += double.tryParse(row.amountController.text) ?? 0.0;
      }
    }
    return sum;
  }

  bool get _isBalanced {
    return (_totalDebit - _totalCredit).abs() < 0.01 && _totalDebit > 0;
  }

  void _addRow() {
    setState(() {
      _rows.add(_VoucherRowItem());
    });
  }

  void _removeRow(int index) {
    if (_rows.length > 2) {
      setState(() {
        _rows.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A voucher must have at least 2 entry lines.'),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isBalanced) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total Debits (\$_totalDebit) must equal Total Credits (\$_totalCredit)!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prepare items list
    List<Map<String, dynamic>> items = [];
    for (var row in _rows) {
      if (row.ledgerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a ledger for all rows.')),
        );
        return;
      }
      final amt = double.tryParse(row.amountController.text) ?? 0.0;
      if (amt <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount must be greater than zero.')),
        );
        return;
      }

      items.add({
        'ledger_id': row.ledgerId,
        'debit': row.isDebit ? amt : 0.0,
        'credit': !row.isDebit ? amt : 0.0,
        'description': row.descController.text.trim().isEmpty
            ? null
            : row.descController.text.trim(),
      });
    }

    final voucherProvider = Provider.of<VoucherProvider>(
      context,
      listen: false,
    );
    final success = await voucherProvider.postVoucher(
      voucherNumber: _voucherNumberController.text.trim(),
      voucherType: _voucherType,
      date: _date,
      narration: _narrationController.text.trim().isEmpty
          ? null
          : _narrationController.text.trim(),
      items: items,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Voucher posted successfully! Ledger balances updated.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error posting voucher: ${voucherProvider.errorMessage}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledgerProvider = Provider.of<LedgerProvider>(context);
    final ledgers = ledgerProvider.ledgers;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Voucher Entry',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              // Voucher Type and Number Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _voucherType,
                      decoration: const InputDecoration(
                        labelText: 'Voucher Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Payment',
                          child: Text('Payment Voucher'),
                        ),
                        DropdownMenuItem(
                          value: 'Receipt',
                          child: Text('Receipt Voucher'),
                        ),
                        DropdownMenuItem(
                          value: 'Contra',
                          child: Text('Contra Voucher'),
                        ),
                        DropdownMenuItem(
                          value: 'Journal',
                          child: Text('Journal Voucher'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _voucherType = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _voucherNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Voucher Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text('${_date.toLocal()}'.split(' ')[0]),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _narrationController,
                decoration: const InputDecoration(
                  labelText: 'Narration / Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'Voucher Entries (Double-Entry)',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                color: Colors.grey[200],
                child: const Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Ledger',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Type (Dr / Cr)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Amount',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),
              // Rows list
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _rows.length,
                  itemBuilder: (context, index) {
                    final row = _rows[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          // Ledger Dropdown
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: row.ledgerId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              hint: const Text('Select Ledger'),
                              items: ledgers.map((Ledger ledger) {
                                return DropdownMenuItem<String>(
                                  value: ledger.id,
                                  child: Text(
                                    ledger.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => row.ledgerId = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Dr / Cr Selector
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<bool>(
                              initialValue: row.isDebit,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: true,
                                  child: Text(
                                    'Debit (Dr)',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: false,
                                  child: Text(
                                    'Credit (Cr)',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => row.isDebit = val ?? true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Amount
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: row.amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                hintText: '0.00',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) =>
                                  val == null || double.tryParse(val) == null
                                  ? 'Invalid'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Description
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: row.descController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                hintText: 'Optional item memo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeRow(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Entry Line'),
                ),
              ),
              const Divider(),
              // Totals and validation banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Debit: \$$_totalDebit',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'Total Credit: \$$_totalCredit',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isBalanced
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isBalanced ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Text(
                      _isBalanced
                          ? 'Balanced ✓'
                          : 'Unbalanced (Dr must equal Cr)',
                      style: TextStyle(
                        color: _isBalanced
                            ? Colors.green[800]
                            : Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isBalanced ? _submit : null,
                        child: const Text('Post Voucher'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoucherRowItem {
  String? ledgerId;
  bool isDebit = true;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descController = TextEditingController();
}
