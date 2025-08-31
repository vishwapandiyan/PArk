import 'package:flutter/material.dart';
import '../models/wallet_model.dart';

class WalletCard extends StatelessWidget {
  final Wallet? wallet;
  final List<Transaction> recentTransactions;
  final bool isLoading;
  final VoidCallback? onAddMoney;
  final VoidCallback? onViewHistory;

  const WalletCard({
    super.key,
    this.wallet,
    this.recentTransactions = const [],
    this.isLoading = false,
    this.onAddMoney,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: theme.colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Wallet',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        Text(
                          'Test Currency Balance',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onViewHistory,
                    icon: Icon(
                      Icons.history_outlined,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Balance Display
              if (isLoading)
                Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              else ...[
                Text(
                  'Available Balance',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  wallet?.formattedBalance ?? '₹0',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAddMoney,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.onPrimary,
                        foregroundColor: theme.colorScheme.primary,
                      ),
                      icon: const Icon(Icons.add_outlined, size: 20),
                      label: const Text('Add Money'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewHistory,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onPrimary,
                        side: BorderSide(color: theme.colorScheme.onPrimary),
                      ),
                      icon: const Icon(Icons.receipt_long_outlined, size: 20),
                      label: const Text('History'),
                    ),
                  ),
                ],
              ),

              // Recent Transactions (if any)
              if (recentTransactions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Divider(color: theme.colorScheme.onPrimary.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text(
                  'Recent Transactions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...recentTransactions.take(2).map((transaction) => 
                  _buildTransactionItem(context, transaction)
                ),
                if (recentTransactions.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+${recentTransactions.length - 2} more transactions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              transaction.isCredit ? Icons.add_outlined : Icons.remove_outlined,
              color: theme.colorScheme.onPrimary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.formattedAmount,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
