import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../exceptions/wallet_exceptions.dart';
import '../models/goal_wallet_model.dart';
import '../models/wallet_credit_model.dart';

class WalletRepository {
  const WalletRepository(this._client);

  final SupabaseClient _client;

  /// Inserts a new goal wallet. The [wallet.id] field is ignored — Supabase
  /// generates the UUID via gen_random_uuid(). Returns the persisted row.
  Future<Result<GoalWalletModel, String>> createWallet(
    GoalWalletModel wallet,
    String userId,
  ) async {
    try {
      final payload = wallet.toJson()
        ..remove('id')
        ..['user_id'] = userId;
      final row = await _client
          .from('goal_wallets')
          .insert(payload)
          .select()
          .single();
      return Ok(GoalWalletModel.fromJson(row));
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }

  /// Returns the goal wallet for [habitId], or null if none exists yet.
  Future<Result<GoalWalletModel?, String>> getWallet(
    String habitId,
    String userId,
  ) async {
    try {
      final row = await _client
          .from('goal_wallets')
          .select()
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .maybeSingle();
      return Ok(
        row != null
            ? GoalWalletModel.fromJson(Map<String, dynamic>.from(row))
            : null,
      );
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }

  /// Returns every goal wallet owned by [userId], across all habits.
  Future<Result<List<GoalWalletModel>, String>> getWallets(String userId) async {
    try {
      final rows = await _client
          .from('goal_wallets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return Ok(
        rows.map((r) => GoalWalletModel.fromJson(Map<String, dynamic>.from(r))).toList(),
      );
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }

  /// Live view of every goal wallet owned by [userId] — re-emits the full
  /// list on any Realtime insert/update/delete via Supabase Postgres Changes
  /// (e.g. when the daily-wallet-credit Edge Function credits a balance).
  Stream<List<GoalWalletModel>> watchWallets(String userId) {
    return _client
        .from('goal_wallets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(GoalWalletModel.fromJson).toList());
  }

  Future<Result<double, String>> getBalance(
    String habitId,
    String userId,
  ) async {
    final result = await getWallet(habitId, userId);
    return switch (result) {
      Ok(value: final wallet) => Ok(wallet?.currentBalance ?? 0),
      Err(error: final e) => Err(e),
    };
  }

  /// Unlocks the wallet once its target has been reached.
  ///
  /// Throws [WalletLockedException] if no wallet exists for [habitId], the
  /// balance hasn't reached the target, or the wallet is already unlocked.
  Future<Result<GoalWalletModel, String>> requestWithdrawal(
    String habitId,
    String userId, {
    String? upiId,
  }) async {
    final walletResult = await getWallet(habitId, userId);
    if (walletResult case Err(:final error)) {
      return Err(error);
    }
    final wallet = (walletResult as Ok<GoalWalletModel?, String>).value;

    if (wallet == null ||
        !(wallet.currentBalance >= wallet.targetAmount && wallet.isLocked)) {
      throw const WalletLockedException();
    }

    try {
      final row = await _client
          .from('goal_wallets')
          .update({
            'is_locked': false,
            'withdrawn_at': DateTime.now().toUtc().toIso8601String(),
            'upi_id': ?upiId,
          })
          .eq('id', wallet.id)
          .select()
          .single();
      return Ok(GoalWalletModel.fromJson(row));
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }
  /// Forfeits and unlocks the wallet before the target is reached.
  ///
  /// Zeroes [GoalWalletModel.currentBalance] rather than releasing it — early
  /// withdrawal is a deliberate commitment-device penalty, not a payout.
  Future<Result<GoalWalletModel, String>> forceEarlyWithdrawal(
    String habitId,
    String userId,
  ) async {
    final walletResult = await getWallet(habitId, userId);
    if (walletResult case Err(:final error)) {
      return Err(error);
    }
    final wallet = (walletResult as Ok<GoalWalletModel?, String>).value;

    if (wallet == null || !wallet.isLocked) {
      return const Err('No active locked wallet to withdraw from');
    }

    try {
      final row = await _client
          .from('goal_wallets')
          .update({
            'current_balance': 0,
            'is_locked': false,
            'withdrawn_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', wallet.id)
          .select()
          .single();
      return Ok(GoalWalletModel.fromJson(row));
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }

  /// Returns the credit history for [habitId]'s wallet, most recent first.
  Future<Result<List<WalletCreditModel>, String>> getCreditHistory(
    String habitId,
    String userId,
  ) async {
    try {
      final rows = await _client
          .from('wallet_credits')
          .select()
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .order('credit_date', ascending: false);
      return Ok(
        rows
            .map((r) => WalletCreditModel.fromJson(Map<String, dynamic>.from(r)))
            .toList(),
      );
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }

  /// Returns every wallet credit across all of [userId]'s habits/wallets,
  /// oldest first — the basis for a cumulative savings-over-time chart.
  Future<Result<List<WalletCreditModel>, String>> getAllCreditHistory(
    String userId,
  ) async {
    try {
      final rows = await _client
          .from('wallet_credits')
          .select()
          .eq('user_id', userId)
          .order('credit_date', ascending: true);
      return Ok(
        rows
            .map((r) => WalletCreditModel.fromJson(Map<String, dynamic>.from(r)))
            .toList(),
      );
    } on PostgrestException catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }
}

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(supabaseClientProvider)),
);
