import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill.dart';
import '../providers/bill_provider.dart';

class AgingReportScreen extends StatefulWidget {
  const AgingReportScreen({super.key});

  @override
  State<AgingReportScreen> createState() => _AgingReportScreenState();
}

class _AgingReportScreenState extends State<AgingReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BillProvider>(context, listen: false).fetchAgingAnalysis();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatBracketTitle(String bracket) {
    switch (bracket) {
      case 'not_due':
        return 'Not Due';
      case '0_to_30_days':
        return '0 - 30 Days';
      case '31_to_60_days':
        return '31 - 60 Days';
      case 'over_60_days':
        return 'Over 60 Days';
      default:
        return bracket;
    }
  }

  Widget _buildBillList(List<Bill> bills, String billType) {
    // Filter by type (receivable or payable)
    final filteredBills = bills.where((b) {
      if (billType == 'receivable') {
        return (b.billType == 'receivable' || b.billType == null) &&
            b.pendingAmount > 0;
      } else {
        return b.billType == 'payable' && b.pendingAmount > 0;
      }
    }).toList();

    if (filteredBills.isEmpty) {
      return Center(
        child: Text(
          'No outstanding ${billType == 'receivable' ? 'receivables' : 'payables'} found.',
        ),
      );
    }

    // Group by aging_bracket
    final Map<String, List<Bill>> grouped = {};
    for (var bill in filteredBills) {
      final bracket = bill.agingBracket ?? 'not_due';
      if (!grouped.containsKey(bracket)) {
        grouped[bracket] = [];
      }
      grouped[bracket]!.add(bill);
    }

    final bracketsOrder = [
      'not_due',
      '0_to_30_days',
      '31_to_60_days',
      'over_60_days',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: bracketsOrder.map((bracket) {
        final bracketBills = grouped[bracket] ?? [];
        if (bracketBills.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _formatBracketTitle(bracket),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            ...bracketBills.map(
              (bill) => Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    bill.ledgerName ?? 'Unknown Ledger',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Reference No: ${bill.referenceNo}'),
                      Text(
                        'Due Date: ${bill.dueDate.toLocal().toString().split(' ')[0]}',
                      ),
                    ],
                  ),
                  trailing: Text(
                    '\$${bill.pendingAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = Provider.of<BillProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill-Wise Aging Report'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Receivables'),
            Tab(text: 'Payables'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => billProvider.fetchAgingAnalysis(),
          ),
        ],
      ),
      body: billProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBillList(billProvider.agingBills, 'receivable'),
                _buildBillList(billProvider.agingBills, 'payable'),
              ],
            ),
    );
  }
}
