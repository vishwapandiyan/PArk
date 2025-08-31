import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/booking_controller.dart';
import '../../widgets/wallet_card.dart';
import '../../models/wallet_model.dart';
import '../../models/booking_model.dart';
import '../../services/wallet_service.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  Wallet? _wallet;
  List<Transaction> _recentTransactions = [];
  bool _isLoadingWallet = true;
  late BookingController _bookingController;

  @override
  void initState() {
    super.initState();
    _bookingController = context.read<BookingController>();
    _loadWalletData();
    _loadBookings();
  }

  Future<void> _loadWalletData() async {
    try {
      final authState = context.read<AuthController>().state;
      if (authState.profile?.id != null) {
        final wallet = await WalletService.getUserWallet(authState.profile!.id);
        final transactions = await WalletService.getRecentTransactions(
          authState.profile!.id,
        );

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
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadBookings() async {
    try {
      final authState = context.read<AuthController>().state;
      if (authState.profile?.id != null) {
        await _bookingController.fetchForUser(authState.profile!.id);
      }
    } catch (e) {
      print('Error loading bookings: $e');
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
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add money: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewTransactionHistory() {
    // TODO: Navigate to transaction history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction history coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: theme.textTheme.headlineMedium),
        actions: [
          IconButton(
            onPressed: () async {
              await context.read<AuthController>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign Out',
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
            Text('Quick Actions', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),

            // Action Cards Grid
            Column(
              children: [
                _buildActionCard(
                  context,
                  title: 'Book Parking',
                  subtitle: 'Find and reserve parking spots',
                  icon: Icons.local_parking_outlined,
                  color: theme.colorScheme.primary,
                  onTap: () => Navigator.of(context).pushNamed('/booking'),
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  context,
                  title: 'Recent Bookings',
                  subtitle: 'View your parking history',
                  icon: Icons.history_outlined,
                  color: theme.colorScheme.secondary,
                  onTap: () => Navigator.of(context).pushNamed('/bookings'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Stats Section
            Text('Your Stats', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Total Bookings',
                    value: '${_bookingController.state.bookings.length}',
                    icon: Icons.bookmark_outline,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Active Bookings',
                    value:
                        '${_bookingController.state.bookings.where((b) => b.status == BookingStatus.active).length}',
                    icon: Icons.favorite_outline,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Recent Bookings Section
            Text('Recent Bookings', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),

            BlocBuilder<BookingController, BookingState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.bookings.isEmpty) {
                  return Card(
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
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: state.bookings
                      .take(3)
                      .map((booking) => _buildBookingCard(context, booking))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 32),

            // Help & Support
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text('Need Help?', style: theme.textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Contact our support team for assistance with bookings, payments, or any other questions.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement help/support functionality
                      },
                      icon: const Icon(Icons.support_agent_outlined),
                      label: const Text('Contact Support'),
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
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
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
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(color: color),
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

  Widget _buildBookingCard(BuildContext context, BookingModel booking) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              booking.status == BookingStatus.active
                  ? Icons.directions_car_outlined
                  : Icons.history_outlined,
              color: booking.status == BookingStatus.active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Parking Slot', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${booking.startTime.toLocal().toString().substring(0, 10)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: ₹${booking.price.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${booking.status.name}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: booking.status == BookingStatus.active
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.7),
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
      title: Text('Add Test Money', style: theme.textTheme.headlineSmall),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select amount to add to your wallet:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _predefinedAmounts.map((amount) {
              final isSelected = amount == _selectedAmount;
              return ChoiceChip(
                label: Text('₹$amount'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedAmount = amount);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.tertiary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is test currency for development purposes only.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedAmount),
          child: Text('Add ₹$_selectedAmount'),
        ),
      ],
    );
  }
}
