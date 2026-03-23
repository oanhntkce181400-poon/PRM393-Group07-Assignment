import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  const AddEditTransactionScreen({super.key, this.existingTransaction});

  final Map<String, dynamic>? existingTransaction;

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int? _walletId;
  String _transactionType = 'EXPENSE';
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  bool get _isEditMode => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    _prefillFormIfNeeded();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _prefillFormIfNeeded() {
    final existing = widget.existingTransaction;
    if (existing == null) {
      return;
    }

    _walletId = (existing['walletId'] as num).toInt();
    _transactionType = (existing['transactionType'] as String?) ?? 'EXPENSE';
    _amountController.text = (existing['amount'] as num).toString();
    _noteController.text = (existing['note'] as String?) ?? '';

    final parsedDate = DateTime.tryParse(existing['date'] as String);
    if (parsedDate != null) {
      _selectedDate = parsedDate;
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    final provider = context.read<TransactionProvider>();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_walletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a wallet.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      final tx = Transaction(
        id: _isEditMode
            ? (widget.existingTransaction!['id'] as num).toInt()
            : null,
        walletId: _walletId!,
        amount: amount,
        transactionType: _transactionType,
        date: _selectedDate.toIso8601String(),
        note: _noteController.text.trim(),
      );

      if (_isEditMode) {
        await provider.updateTransaction(tx);
      } else {
        await provider.addTransaction(tx);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save transaction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (!_isEditMode) {
      return;
    }

    final transactionId = (widget.existingTransaction!['id'] as num).toInt();
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: const Text('You cannot undo this action.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete || !mounted) {
      return;
    }

    await context.read<TransactionProvider>().deleteTransaction(transactionId);
    if (!mounted) {
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Transaction' : 'Add Transaction',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        centerTitle: true,
      ),
      body: provider.wallets.isEmpty && !provider.isLoading
          ? const Center(
              child: Text('No wallet available. Please create wallets first.'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final raw = value?.trim() ?? '';
                            if (raw.isEmpty) {
                              return 'Amount is required.';
                            }

                            final parsed = double.tryParse(raw);
                            if (parsed == null || parsed <= 0) {
                              return 'Amount must be a positive number.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _transactionType,
                          items: const [
                            DropdownMenuItem(
                              value: 'EXPENSE',
                              child: Text('Expense'),
                            ),
                            DropdownMenuItem(
                              value: 'INCOME',
                              child: Text('Income'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Transaction Type',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _transactionType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _walletId,
                          items: provider.wallets
                              .map(
                                (wallet) => DropdownMenuItem<int>(
                                  value: wallet.id,
                                  child: Text(wallet.name),
                                ),
                              )
                              .toList(),
                          decoration: const InputDecoration(
                            labelText: 'Wallet',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _walletId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a wallet.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(4),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_month),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => Navigator.pop(context, false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(_isEditMode ? 'Update' : 'Save'),
                              ),
                            ),
                          ],
                        ),
                        if (_isEditMode) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _confirmDelete,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete transaction'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
