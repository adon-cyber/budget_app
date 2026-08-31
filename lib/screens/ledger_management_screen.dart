import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ledger_provider.dart';

class LedgerManagementScreen extends StatefulWidget {
  const LedgerManagementScreen({super.key});

  @override
  State<LedgerManagementScreen> createState() => _LedgerManagementScreenState();
}

class _LedgerManagementScreenState extends State<LedgerManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LedgerProvider>(
        context,
        listen: false,
      ).fetchChartOfAccounts();
    });
  }

  void _showAddLedgerModal(BuildContext context) {
    final ledgerProvider = Provider.of<LedgerProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    String name = '';
    String? selectedGroupId;
    double openingBalance = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create New Ledger',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Ledger Name'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Please enter a name' : null,
                  onSaved: (val) => name = val!,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Account Group'),
                  items: ledgerProvider.accountGroups.map((group) {
                    return DropdownMenuItem<String>(
                      value: group.id,
                      child: Text(
                        '${group.name} (${group.type.toUpperCase()})',
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => selectedGroupId = val,
                  validator: (val) =>
                      val == null ? 'Please select an account group' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Opening Balance',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  initialValue: '0.00',
                  validator: (val) {
                    if (val == null || double.tryParse(val) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (val) => openingBalance = double.parse(val!),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      final success = await ledgerProvider.addLedger(
                        name: name,
                        groupId: selectedGroupId!,
                        openingBalance: openingBalance,
                      );
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ledger created successfully'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${ledgerProvider.errorMessage}',
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Save Ledger'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tally Chart of Accounts')),
      body: Consumer<LedgerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.accountGroups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.accountGroups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${provider.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Primary types: asset, liability, income, expense
          final primaryTypes = ['asset', 'liability', 'income', 'expense'];

          return RefreshIndicator(
            onRefresh: () => provider.fetchChartOfAccounts(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: primaryTypes.map((type) {
                final groupsForType = provider.accountGroups
                    .where((g) => g.type.toLowerCase() == type)
                    .toList();

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(
                      type.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    children: groupsForType.map((group) {
                      final ledgersForGroup = provider.ledgers
                          .where((l) => l.groupId == group.id)
                          .toList();

                      return ExpansionTile(
                        title: Text(
                          group.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${ledgersForGroup.length} ledgers'),
                        children: ledgersForGroup.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text(
                                    'No ledgers in this group',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ]
                            : ledgersForGroup.map((ledger) {
                                return ListTile(
                                  title: Text(ledger.name),
                                  trailing: Text(
                                    'Bal: \$${ledger.currentBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLedgerModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
