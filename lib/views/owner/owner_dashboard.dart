import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/wallet_card.dart';
import '../../models/wallet_model.dart';
import '../../services/wallet_service.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  Wallet? _wallet;
  List<Transaction> _recentTransactions = [];
  bool _isLoadingWallet = true;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    try {
      final authState = context.read<AuthController>().state;
      if (authState.profile?.id != null) {
        final wallet = await WalletService.getUserWallet(authState.profile!.id);
        final transactions = await WalletService.getRecentTransactions(authState.profile!.id);
        
        setState(() {
          _wallet = wallet;
          _recentTransactions = transactions;
          _isLoadingWallet = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingWallet = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load wallet: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _addMoney() async {
    // Show dialog to add test money
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => _AddMoneyDialog(),
    );
    
    if (amount != null && amount > 0) {
      try {
        final authState = context.read<AuthController>().state;
        await WalletService.addMoney(
          authState.profile!.id,
          amount,
          'Test money added',
        );
        await _loadWalletData(); // Refresh wallet data
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('₹$amount added to wallet successfully!'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add money: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _viewTransactionHistory() {
    // TODO: Navigate to transaction history screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction history coming soon!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Owner Dashboard',
          style: theme.textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await context.read<AuthController>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wallet Card
            WalletCard(
              wallet: _wallet,
              recentTransactions: _recentTransactions,
              isLoading: _isLoadingWallet,
              onAddMoney: _addMoney,
              onViewHistory: _viewTransactionHistory,
            ),

            const SizedBox(height: 32),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Action Cards
            Column(
              children: [
                _buildActionCard(
                  context,
                  title: 'Manage Spaces',
                  subtitle: 'Add, edit, or remove parking spots',
                  icon: Icons.edit_location_outlined,
                  color: theme.colorScheme.primary,
                  onTap: () => Navigator.of(context).pushNamed('/manage_space'),
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  context,
                  title: 'Analytics',
                  subtitle: 'View earnings and usage statistics',
                  icon: Icons.analytics_outlined,
                  color: theme.colorScheme.secondary,
                  onTap: () => Navigator.of(context).pushNamed('/analytics'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Earnings Overview Section
            Text(
              'Earnings Overview',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Today',
                    value: '\$0',
                    icon: Icons.calendar_today_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'This Week',
                    value: '\$0',
                    icon: Icons.calendar_view_week_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'This Month',
                    value: '\$0',
                    icon: Icons.calendar_month_outlined,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Recent Bookings Section
            Text(
              'Recent Bookings',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_outlined,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'No recent bookings',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Space Management Section
            Text(
              'Space Management',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Active Spaces',
                    value: '0',
                    icon: Icons.local_parking_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Total Earnings',
                    value: '\$0',
                    icon: Icons.attach_money_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Tips Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: theme.colorScheme.tertiary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Pro Tips',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Set competitive pricing to attract more drivers\n• Keep your spaces well-maintained for better ratings\n• Respond quickly to booking requests\n• Use analytics to optimize your parking business',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_outlined,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMoneyDialog extends StatefulWidget {
  @override
  State<_AddMoneyDialog> createState() => _AddMoneyDialogState();
}

class _AddMoneyDialogState extends State<_AddMoneyDialog> {
  int _selectedAmount = 500;
  final List<int> _predefinedAmounts = [100, 250, 500, 1000, 2000, 5000];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(
        'Add Money to Wallet',
        style: theme.textTheme.headlineSmall,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select amount to add to your wallet:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _predefinedAmounts.map((amount) {
              final isSelected = amount == _selectedAmount;
              return InkWell(
                onTap: () => setState(() => _selectedAmount = amount),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    '₹$amount',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedAmount),
          child: Text('Add Money'),
        ),
      ],
    );
  }
}




