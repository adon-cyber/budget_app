import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cost_center_provider.dart';

class CostCenterScreen extends StatefulWidget {
  const CostCenterScreen({super.key});

  @override
  State<CostCenterScreen> createState() => _CostCenterScreenState();
}

class _CostCenterScreenState extends State<CostCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CostCenterProvider>(
        context,
        listen: false,
      ).fetchCostCenters();
    });
  }

  void _showAddCostCenterDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Cost Center'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Cost Center Name',
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success =
                    await Provider.of<CostCenterProvider>(
                      context,
                      listen: false,
                    ).addCostCenter(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );

                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();

                if (!mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cost center added successfully'),
                    ),
                  );
                } else {
                  final err = Provider.of<CostCenterProvider>(
                    context,
                    listen: false,
                  ).errorMessage;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding cost center: $err'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final costCenterProvider = Provider.of<CostCenterProvider>(context);
    final costCenters = costCenterProvider.costCenters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cost Centers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => costCenterProvider.fetchCostCenters(),
          ),
        ],
      ),
      body: costCenterProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : costCenters.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No cost centers found.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddCostCenterDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Cost Center'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: costCenters.length,
              itemBuilder: (context, index) {
                final cc = costCenters[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.business_center),
                    ),
                    title: Text(
                      cc.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(cc.description ?? 'No description provided'),
                    trailing: Text(
                      'Created: ${cc.createdAt.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCostCenterDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
