import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../habits/providers/habits_provider.dart';
import '../models/goal_wallet_model.dart';
import '../models/wallet_credit_model.dart';
import '../providers/wallet_home_provider.dart';
import '../providers/wallet_withdraw_provider.dart';

final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _dateFmt = DateFormat('d MMM yyyy');

class WalletDetailScreen extends ConsumerWidget {
  const WalletDetailScreen({super.key, required this.habitId});
  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(goalWalletProvider(habitId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Wallet')),
      body: walletAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(child: Text('Failed to load wallet: $error')),
        data: (wallet) {
          if (wallet == null) {
            return _NoWalletState(habitId: habitId);
          }
          return _WalletContent(wallet: wallet);
        },
      ),
    );
  }
}

class _NoWalletState extends StatelessWidget {
  const _NoWalletState({required this.habitId});
  final String habitId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text(
              'No goal wallet yet',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Set a savings goal for this habit to start tracking progress.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Create goal wallet',
              onPressed: () => context.push('/wallet/create', extra: habitId),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletContent extends ConsumerStatefulWidget {
  const _WalletContent({required this.wallet});
  final GoalWalletModel wallet;

  @override
  ConsumerState<_WalletContent> createState() => _WalletContentState();
}

class _WalletContentState extends ConsumerState<_WalletContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  bool _showConfetti = false;
  int _milestoneToken = 0;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _onMilestone(int milestone) {
    final token = ++_milestoneToken;
    setState(() => _showConfetti = true);
    _confettiCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && token == _milestoneToken) {
        setState(() => _showConfetti = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallet;
    final historyAsync = ref.watch(walletCreditHistoryProvider(wallet.habitId));

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _GoalCard(wallet: wallet, onMilestone: _onMilestone),
            const SizedBox(height: AppSpacing.lg),
            _WithdrawSection(wallet: wallet),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Transaction History',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            historyAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              error: (_, _) => const _EmptyHistory(),
              data: (credits) =>
                  credits.isEmpty ? const _EmptyHistory() : _CreditList(credits: credits),
            ),
          ],
        ),
        if (_showConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: Lottie.asset(
                'assets/lottie/confetti.json',
                controller: _confettiCtrl,
                repeat: false,
                fit: BoxFit.cover,
              ),
            ),
          ),
      ],
    );
  }
}

class _WithdrawSection extends ConsumerStatefulWidget {
  const _WithdrawSection({required this.wallet});
  final GoalWalletModel wallet;

  @override
  ConsumerState<_WithdrawSection> createState() => _WithdrawSectionState();
}

class _WithdrawSectionState extends ConsumerState<_WithdrawSection> {
  static final _upiRegex = RegExp(r'^[\w.\-]+@[\w]+$');

  late final Razorpay _razorpay;
  String? _pendingUpiId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ));
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    ref
        .read(walletWithdrawProvider.notifier)
        .withdraw(widget.wallet.habitId, upiId: _pendingUpiId);
  }

  void _onPaymentError(PaymentFailureResponse response) {
    _snack('Payment failed: ${response.message ?? 'Unknown error'}');
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _snack('Payout confirmation cancelled.');
  }

  Future<void> _promptUpiIdThenPay() async {
    final controller = TextEditingController();
    final upiId = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isValid = _upiRegex.hasMatch(controller.text.trim());
          return AlertDialog(
            title: const Text('Enter your UPI ID'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'yourname@bank'),
              onChanged: (_) => setDialogState(() {}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    isValid ? () => Navigator.of(ctx).pop(controller.text.trim()) : null,
                child: const Text('Continue'),
              ),
            ],
          );
        },
      ),
    );
    if (upiId == null || !mounted) return;

    const keyId = String.fromEnvironment('RAZORPAY_KEY_ID');
    if (keyId.isEmpty) {
      _snack("Razorpay isn't configured for this demo — add RAZORPAY_KEY_ID to your .env");
      return;
    }

    _pendingUpiId = upiId;
    final wallet = widget.wallet;
    _razorpay.open({
      'key': keyId,
      'amount': (wallet.targetAmount * 100).round(),
      'name': 'Pravaan',
      'description': 'Goal wallet payout confirmation — ${wallet.goalName}',
      'prefill': {'vpa': upiId},
      'method': {
        'upi': true,
        'card': false,
        'netbanking': false,
        'wallet': false,
        'emi': false,
        'paylater': false,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallet;

    if (!wallet.isLocked) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.successTint,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_open_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                wallet.withdrawnAt != null
                    ? 'Withdrawn on ${_dateFmt.format(wallet.withdrawnAt!)}'
                        '${wallet.upiId != null ? ' to ${wallet.upiId}' : ''}'
                    : 'Wallet unlocked',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final habits = ref.watch(habitNotifierProvider).value ?? [];
    final habit = habits.where((h) => h.id == wallet.habitId).firstOrNull;
    final dailySpend = habit?.dailySpend ?? 0;
    final eligible = wallet.currentBalance >= wallet.targetAmount;
    final withdrawState = ref.watch(walletWithdrawProvider);

    ref.listen<WalletWithdrawState>(walletWithdrawProvider, (previous, next) {
      if (next.status == WalletWithdrawStatus.success) {
        ref.invalidate(goalWalletProvider(wallet.habitId));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Wallet unlocked! 🎉'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ));
      } else if (next.status == WalletWithdrawStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage ?? 'Something went wrong'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ));
      }
    });

    if (eligible) {
      return SizedBox(
        width: double.infinity,
        child: AppButton(
          label: 'Withdraw',
          isLoading: withdrawState.status == WalletWithdrawStatus.submitting,
          onPressed: _promptUpiIdThenPay,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.lock_outline_rounded, size: 18),
        label: const Text('Withdraw'),
        onPressed: () => _showLockedSheet(context, wallet, dailySpend),
      ),
    );
  }

  void _showLockedSheet(BuildContext context, GoalWalletModel wallet, double dailySpend) {
    final remaining = wallet.targetAmount - wallet.currentBalance;
    final daysAway = dailySpend > 0 ? (remaining / dailySpend).ceil() : null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text('🔒', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              'Your wallet unlocks when you reach ${_fmt.format(wallet.targetAmount)}. '
              'Withdrawing early defeats the purpose.',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              daysAway != null
                  ? "You're about $daysAway days away at your current pace."
                  : 'Keep checking in daily to build toward your goal.',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push('/wallet/early-withdraw', extra: wallet.habitId);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Withdraw anyway',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatefulWidget {
  const _GoalCard({required this.wallet, required this.onMilestone});
  final GoalWalletModel wallet;
  final ValueChanged<int> onMilestone;

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  static const _milestones = [25, 50, 75, 100];
  final _firedMilestones = <int>{};

  void _checkMilestones(double animatedPercent) {
    for (final milestone in _milestones) {
      if (!_firedMilestones.contains(milestone) && animatedPercent >= milestone) {
        _firedMilestones.add(milestone);
        WidgetsBinding.instance
            .addPostFrameCallback((_) => widget.onMilestone(milestone));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallet;
    final daysRemaining = wallet.targetDate.difference(DateTime.now()).inDays;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            wallet.goalName,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _fmt.format(wallet.currentBalance),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: const SizedBox.shrink().animate().custom(
                  duration: 1400.ms,
                  curve: Curves.easeOut,
                  begin: 0,
                  end: wallet.progressPercent,
                  builder: (context, value, child) {
                    _checkMilestones(value);
                    final clamped = value.clamp(0, 100).toDouble();
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            startDegreeOffset: -90,
                            sectionsSpace: 0,
                            centerSpaceRadius: 34,
                            sections: [
                              PieChartSectionData(
                                value: clamped,
                                color: AppColors.primary,
                                radius: 14,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: 100 - clamped,
                                color: AppColors.surfaceContainerHigh,
                                radius: 14,
                                showTitle: false,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${value.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'Target',
                      value: _fmt.format(wallet.targetAmount),
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      label: 'Days remaining',
                      value: daysRemaining > 0
                          ? '$daysRemaining days'
                          : 'Target date reached',
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      label: 'Target date',
                      value: _dateFmt.format(wallet.targetDate),
                    ),
                  ],
                ),
              ),
            ],
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
                fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
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

class _CreditList extends StatelessWidget {
  const _CreditList({required this.credits});
  final List<WalletCreditModel> credits;

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
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: credits.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.outlineVariant),
          itemBuilder: (_, i) => _CreditRow(credit: credits[i]),
        ),
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({required this.credit});
  final WalletCreditModel credit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.successTint,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: const Icon(Icons.savings_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily clean-day credit',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _dateFmt.format(credit.creditDate),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${_fmt.format(credit.amount)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

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
            'No credits yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Check in daily to start earning toward this goal.',
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
