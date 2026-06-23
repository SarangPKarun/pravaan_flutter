import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_card.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletDataProvider);
    final txAsync = ref.watch(walletTransactionsProvider);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _WalletHeader(wallet: wallet, fmt: fmt),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
            sliver: SliverList.list(
              children: [
                // ── Progress ring + target info ──────────────────────────
                _ProgressSection(wallet: wallet, fmt: fmt)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 400.ms),

                const SizedBox(height: 20),

                // ── Redeem button ─────────────────────────────────────────
                _RedeemButton(wallet: wallet, fmt: fmt)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 28),

                // ── Transaction history ────────────────────────────────────
                const _SectionLabel(label: 'Transaction History'),
                const SizedBox(height: 12),

                txAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                  error: (_, _) => const _EmptyTransactions(),
                  data: (txs) => txs.isEmpty
                      ? const _EmptyTransactions()
                      : _TransactionList(transactions: txs),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _WalletHeader extends StatelessWidget {
  const _WalletHeader({required this.wallet, required this.fmt});
  final WalletData wallet;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF004D38), AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('💰', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 10),
                  Text(
                    'Goal Wallet',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Total Saved',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: wallet.balance),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOut,
                builder: (_, v, _) => Text(
                  fmt.format(v),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.5,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${fmt.format(wallet.dailySavings)} saved per day',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.08, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

// ── Progress section ──────────────────────────────────────────────────────────
class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.wallet, required this.fmt});
  final WalletData wallet;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final pct = wallet.progressPercent;
    final dateFmt = wallet.quitDate != null
        ? DateFormat('d MMM yyyy').format(wallet.quitDate!)
        : '—';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Donut ring ─────────────────────────────────────────────────
          SizedBox(
            width: 110,
            height: 110,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: wallet.progressFraction),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOut,
              builder: (_, frac, _) => Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 0,
                      centerSpaceRadius: 38,
                      sections: [
                        PieChartSectionData(
                          value: frac * 100,
                          color: AppColors.primary,
                          radius: 16,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: (1 - frac) * 100,
                          color: AppColors.surfaceContainerHigh,
                          radius: 16,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // ── Info ────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Target', value: fmt.format(wallet.targetAmount)),
                const SizedBox(height: 10),
                _InfoRow(label: 'Saved', value: fmt.format(wallet.balance)),
                const SizedBox(height: 10),
                _InfoRow(label: 'Remaining', value: fmt.format((wallet.targetAmount - wallet.balance).clamp(0, double.infinity))),
                const SizedBox(height: 10),
                _InfoRow(label: 'Quit date', value: dateFmt),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

// ── Redeem button ─────────────────────────────────────────────────────────────
class _RedeemButton extends ConsumerWidget {
  const _RedeemButton({required this.wallet, required this.fmt});
  final WalletData wallet;
  final NumberFormat fmt;

  static const _options = [
    '🛍️  Buy a wellness product',
    '🎁  Gift it to a friend',
    '📦  Order a nicotine patch kit',
    '🏋️  Pay for a gym session',
    '🍽️  Treat yourself to a meal',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final redeemState = ref.watch(redeemProvider);
    final isLoading = redeemState is AsyncLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: wallet.balance <= 0 || isLoading
            ? null
            : () => _showRedeemSheet(context, ref),
        icon: const Icon(Icons.redeem_rounded),
        label: const Text('Withdraw / Redeem Savings'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
    );
  }

  void _showRedeemSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => _RedeemSheet(
        balance: wallet.balance,
        fmt: fmt,
        options: _options,
        onRedeem: (option) async {
          Navigator.of(ctx).pop();
          await ref.read(redeemProvider.notifier).redeem(option, wallet.balance);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Redemption recorded! 🎉'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ));
          }
        },
      ),
    );
  }
}

class _RedeemSheet extends StatelessWidget {
  const _RedeemSheet({
    required this.balance,
    required this.fmt,
    required this.options,
    required this.onRedeem,
  });

  final double balance;
  final NumberFormat fmt;
  final List<String> options;
  final ValueChanged<String> onRedeem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Redeem Your Savings',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Available: ${fmt.format(balance)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          ...options.map(
            (opt) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(opt,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.outline),
              onTap: () => onRedeem(opt),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction list ──────────────────────────────────────────────────────────
class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.transactions});
  final List transactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (_, i) =>
              WalletCard(transaction: transactions[i]),
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Column(
        children: [
          Text('🧾', style: TextStyle(fontSize: 36)),
          SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your daily savings will appear here\nonce the table is set up in Supabase.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
