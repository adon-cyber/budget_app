import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ledger_provider.dart';
import '../models/account_group.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fromDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LedgerProvider>(
        context,
        listen: false,
      ).fetchChartOfAccounts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Statements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trial Balance'),
            Tab(text: 'Profit & Loss'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: Consumer<LedgerProvider>(
        builder: (context, ledgerProvider, child) {
          if (ledgerProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ledgerProvider.errorMessage != null) {
            return Center(
              child: Text(
                'Error: ${ledgerProvider.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTrialBalance(ledgerProvider),
              _buildProfitAndLoss(ledgerProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrialBalance(LedgerProvider provider) {
    final groups = provider.accountGroups;
    final ledgers = provider.ledgers;

    // Map group id to group object
    final groupMap = {for (var g in groups) g.id: g};

    // Aggregate Debit and Credit by Primary Group (or group type/name)
    // In Tally, Trial Balance groups by Account Groups (Assets, Liabilities, Capital, Loans, etc.)
    Map<String, double> groupBalances = {};

    for (var ledger in ledgers) {
      final group = groupMap[ledger.groupId];
      final groupName = group?.name ?? 'Primary / Unknown';

      groupBalances.update(
        groupName,
        (value) => value + ledger.currentBalance,
        ifAbsent: () => ledger.currentBalance,
      );
    }

    double totalDebit = 0;
    double totalCredit = 0;

    List<Widget> rows = groupBalances.entries.map((entry) {
      final groupName = entry.key;
      final balance = entry.value;

      // Find group type to determine if it sits on Debit or Credit side standardly,
      // or simply show debit if positive, credit if negative, or based on group type.
      // Assets & Expenses usually normal Debit balance. Liabilities, Capital & Incomes usually normal Credit balance.
      final group = groups.firstWhere(
        (g) => g.name == groupName,
        orElse: () => AccountGroup(
          id: '',
          name: '',
          type: 'asset',
          createdAt: DateTime.now(),
        ),
      );

      double debit = 0;
      double credit = 0;

      if (group.type == 'asset' || group.type == 'expense') {
        if (balance >= 0) {
          debit = balance;
          totalDebit += debit;
        } else {
          credit = balance.abs();
          totalCredit += credit;
        }
      } else {
        if (balance >= 0) {
          credit = balance;
          totalCredit += credit;
        } else {
          debit = balance.abs();
          totalDebit += debit;
        }
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                groupName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                debit > 0 ? debit.toStringAsFixed(2) : '-',
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                credit > 0 ? credit.toStringAsFixed(2) : '-',
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            'Trial Balance as of ${_toDate.toLocal().toString().split(' ')[0]}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Particulars (Group)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Debit',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Credit',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: rows.isNotEmpty
                ? rows
                : const [
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No ledger data available.'),
                      ),
                    ),
                  ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  totalDebit.toStringAsFixed(2),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  totalCredit.toStringAsFixed(2),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfitAndLoss(LedgerProvider provider) {
    final groups = provider.accountGroups;
    final ledgers = provider.ledgers;

    final groupMap = {for (var g in groups) g.id: g};

    double totalIncome = 0;
    double totalExpense = 0;

    List<Widget> incomeWidgets = [];
    List<Widget> expenseWidgets = [];

    for (var ledger in ledgers) {
      final group = groupMap[ledger.groupId];
      if (group == null) continue;

      if (group.type == 'income') {
        totalIncome += ledger.currentBalance.abs();
        incomeWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ledger.name),
                Text(ledger.currentBalance.abs().toStringAsFixed(2)),
              ],
            ),
          ),
        );
      } else if (group.type == 'expense') {
        totalExpense += ledger.currentBalance.abs();
        expenseWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ledger.name),
                Text(ledger.currentBalance.abs().toStringAsFixed(2)),
              ],
            ),
          ),
        );
      }
    }

    double netProfitOrLoss = totalIncome - totalExpense;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Center(
          child: Text(
            'Profit & Loss Statement\nFrom ${_fromDate.toLocal().toString().split(' ')[0]} To ${_toDate.toLocal().toString().split(' ')[0]}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Income',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const Divider(),
        ...incomeWidgets.isNotEmpty
            ? incomeWidgets
            : [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No income recorded.'),
                ),
              ],
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Income',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              totalIncome.toStringAsFixed(2),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Text(
          'Expenses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const Divider(),
        ...expenseWidgets.isNotEmpty
            ? expenseWidgets
            : [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No expenses recorded.'),
                ),
              ],
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Expenses',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              totalExpense.toStringAsFixed(2),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const Divider(thickness: 2, height: 40),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: netProfitOrLoss >= 0
                ? Colors.green.shade50
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: netProfitOrLoss >= 0
                  ? Colors.green.shade200
                  : Colors.red.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                netProfitOrLoss >= 0 ? 'Net Profit' : 'Net Loss',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: netProfitOrLoss >= 0
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                ),
              ),
              Text(
                netProfitOrLoss.abs().toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: netProfitOrLoss >= 0
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
