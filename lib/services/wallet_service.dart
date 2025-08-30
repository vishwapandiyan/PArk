import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';
import '../models/wallet_model.dart';

class WalletService {
  static SupabaseClient get _client => AppSupabase.client;

  /// Get user's wallet
  static Future<Wallet?> getUserWallet(String userId) async {
    try {
      final response = await _client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create wallet if it doesn't exist
        return await createWallet(userId);
      }

      return Wallet.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch wallet: $e');
    }
  }

  /// Create a new wallet for user
  static Future<Wallet> createWallet(String userId) async {
    try {
      final response = await _client
          .from('wallets')
          .insert({
            'user_id': userId,
            'balance': 1000, // Starting balance
          })
          .select()
          .single();

      return Wallet.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create wallet: $e');
    }
  }

  /// Add money to wallet (fake transaction)
  static Future<void> addMoney(String userId, int amount, String description) async {
    try {
      // Start transaction
      await _client.rpc('add_wallet_balance', params: {
        'user_id_param': userId,
        'amount_param': amount,
      });

      // Record transaction
      await _client.from('transactions').insert({
        'user_id': userId,
        'transaction_type': 'credit',
        'amount': amount,
        'description': description,
      });
    } catch (e) {
      throw Exception('Failed to add money: $e');
    }
  }

  /// Deduct money from wallet
  static Future<bool> deductMoney(String userId, int amount, String description, {String? referenceId}) async {
    try {
      // Check balance first
      final wallet = await getUserWallet(userId);
      if (wallet == null || wallet.balance < amount) {
        return false; // Insufficient balance
      }

      // Deduct from wallet
      await _client.rpc('deduct_wallet_balance', params: {
        'user_id_param': userId,
        'amount_param': amount,
      });

      // Record transaction
      await _client.from('transactions').insert({
        'user_id': userId,
        'transaction_type': 'debit',
        'amount': amount,
        'description': description,
        'reference_id': referenceId,
      });

      return true;
    } catch (e) {
      throw Exception('Failed to deduct money: $e');
    }
  }

  /// Get user's transactions
  static Future<List<Transaction>> getUserTransactions(String userId, {int limit = 10}) async {
    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  /// Get recent transactions (last 3)
  static Future<List<Transaction>> getRecentTransactions(String userId) async {
    return await getUserTransactions(userId, limit: 3);
  }

  /// Process payment (for parking bookings)
  static Future<bool> processPayment(String userId, int amount, String description, {String? referenceId}) async {
    return await deductMoney(userId, amount, description, referenceId: referenceId);
  }

  /// Process income (for parking owners)
  static Future<void> processIncome(String userId, int amount, String description, {String? referenceId}) async {
    await addMoney(userId, amount, description);
  }
}
