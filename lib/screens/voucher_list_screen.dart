import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:google_fonts/google_fonts.dart';

import '../providers/voucher_provider.dart';
import '../models/voucher.dart';
import '../widgets/voucher_entry_dialog.dart';

class VoucherListScreen extends StatefulWidget {
  const VoucherListScreen({super.key});

  @override
  State<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends State<VoucherListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      legacy_provider.Provider.of<VoucherProvider>(
        context,
        listen: false,
      ).fetchVouchers();
    });
  }

  void _openNewVoucherDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const VoucherEntryDialog(),
    ).then((_) {
      if (!context.mounted) return;
      if (!mounted) return;
      legacy_provider.Provider.of<VoucherProvider>(
        context,
        listen: false,
      ).fetchVouchers();
    });
  }

  Color _getVoucherTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'receipt':
        return Colors.green;
      case 'payment':
        return Colors.red;
      case 'contra':
        return Colors.blue;
      case 'journal':
        return Colors.orange;
      default:
        return Colors.indigo;
    }
  }

  double _calculateTotalAmount(Voucher voucher) {
    double total = 0;
    for (var item in voucher.items) {
      total += item.debit;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Vouchers',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              legacy_provider.Provider.of<VoucherProvider>(
                context,
                listen: false,
              ).fetchVouchers();
            },
          ),
        ],
      ),
      body: legacy_provider.Consumer<VoucherProvider>(
        builder: (context, voucherProvider, child) {
          final vouchers = voucherProvider.vouchers;

          if (voucherProvider.isLoading && vouchers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (voucherProvider.errorMessage != null && vouchers.isEmpty) {
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
                        'Error: ${voucherProvider.errorMessage}',
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
              RefreshIndicator(
                onRefresh: () async {
                  await voucherProvider.fetchVouchers();
                  if (!context.mounted) return;
                },
                child: vouchers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No vouchers found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _openNewVoucherDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Create Voucher'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: vouchers.length,
                        itemBuilder: (context, index) {
                          final voucher = vouchers[index];
                          final typeColor = _getVoucherTypeColor(
                            voucher.voucherType,
                          );
                          final totalAmount = _calculateTotalAmount(voucher);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            voucher.voucherNumber,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: typeColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              voucher.voucherType,
                                              style: TextStyle(
                                                color: typeColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '\$${totalAmount.toStringAsFixed(2)}',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (voucher.narration != null &&
                                      voucher.narration!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      voucher.narration!,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${voucher.items.length} line items',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '${voucher.date.month}/${voucher.date.day}/${voucher.date.year}',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (voucherProvider.isLoading)
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewVoucherDialog(context),
        label: const Text('New Voucher'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}
