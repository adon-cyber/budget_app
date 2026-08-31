import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/report_provider.dart';
import '../models/report_balance.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).fetchReportBalances();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trial Balance'),
            Tab(text: 'Profit & Loss'),
            Tab(text: 'Balance Sheet'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<ReportProvider>(
              context,
              listen: false,
            ).fetchReportBalances(),
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          if (reportProvider.isLoading &&
              reportProvider.reportBalances.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reportProvider.errorMessage != null &&
              reportProvider.reportBalances.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Error: ${reportProvider.errorMessage}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  _buildTrialBalanceTab(reportProvider.reportBalances),
                  _buildProfitLossTab(reportProvider),
                  _buildBalanceSheetTab(reportProvider),
                ],
              ),
              if (reportProvider.isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrialBalanceTab(List<ReportBalance> balances) {
    double totalDebit = 0.0;
    double totalCredit = 0.0;

    final rows = balances.map((item) {
      final nature = item.nature.toLowerCase();
      final isDebitNature = nature == 'asset' || nature == 'expense';

      double debitVal = 0.0;
      double creditVal = 0.0;

      if (isDebitNature) {
        debitVal = item.currentBalance;
        totalDebit += debitVal;
      } else {
        creditVal = item.currentBalance;
        totalCredit += creditVal;
      }

      return DataRow(
        cells: [
          DataCell(Text(item.ledgerName)),
          DataCell(Text(item.groupName)),
          DataCell(
            Text(
              isDebitVal(debitVal) ? '\$${debitVal.toStringAsFixed(2)}' : '-',
            ),
          ),
          DataCell(
            Text(creditVal > 0 ? '\$${creditVal.toStringAsFixed(2)}' : '-'),
          ),
        ],
      );
    }).toList();

    // To ensure bottom totals match for trial balance in accounting demo if there's a diff or if totals should match
    // Standard trial balance debits and credits should naturally equal.

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(
                    label: Text(
                      'Ledger Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Group',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Debit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Credit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: rows,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey.shade200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Total Debit: \$${totalDebit.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Total Credit: \$${totalCredit.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool isDebitVal(double val) => val > 0;

  Widget _buildProfitLossTab(ReportProvider provider) {
    final expenses = provider.reportBalances
        .where((item) => item.nature.toLowerCase() == 'expense')
        .toList();
    final incomes = provider.reportBalances
        .where((item) => item.nature.toLowerCase() == 'income')
        .toList();

    final netProfit = provider.netProfit;
    final isNetProfit = netProfit >= 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expenses Card (Left)
                Expanded(
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expenses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: ListView.builder(
                              itemCount: expenses.length,
                              itemBuilder: (context, index) {
                                final exp = expenses[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(exp.ledgerName),
                                  trailing: Text(
                                    '\$${exp.currentBalance.toStringAsFixed(2)}',
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Expenses:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${provider.totalExpenses.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Incomes Card (Right)
                Expanded(
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Income',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: ListView.builder(
                              itemCount: incomes.length,
                              itemBuilder: (context, index) {
                                final inc = incomes[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(inc.ledgerName),
                                  trailing: Text(
                                    '\$${inc.currentBalance.toStringAsFixed(2)}',
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Income:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${provider.totalIncome.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isNetProfit ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isNetProfit ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isNetProfit ? 'Net Profit: ' : 'Net Loss: ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isNetProfit
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
                Text(
                  '\$${netProfit.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isNetProfit
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSheetTab(ReportProvider provider) {
    final liabilities = provider.reportBalances
        .where((item) => item.nature.toLowerCase() == 'liability')
        .toList();
    final assets = provider.reportBalances
        .where((item) => item.nature.toLowerCase() == 'asset')
        .toList();

    final netProfit = provider.netProfit;
    final totalLiabilities = provider.totalLiabilities + netProfit;
    final totalAssets = provider.totalAssets;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Liabilities & Equity (Left)
          Expanded(
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Liabilities & Equity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: [
                          ...liabilities.map(
                            (liab) => ListTile(
                              dense: true,
                              title: Text(liab.ledgerName),
                              trailing: Text(
                                '\$${liab.currentBalance.toStringAsFixed(2)}',
                              ),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            title: const Text(
                              'Net Profit / (Loss)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: Text(
                              '\$${netProfit.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: netProfit >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '\$${totalLiabilities.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Assets (Right)
          Expanded(
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: assets.length,
                        itemBuilder: (context, index) {
                          final asset = assets[index];
                          return ListTile(
                            dense: true,
                            title: Text(asset.ledgerName),
                            trailing: Text(
                              '\$${asset.currentBalance.toStringAsFixed(2)}',
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '\$${totalAssets.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
