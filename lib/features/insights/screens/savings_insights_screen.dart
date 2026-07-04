import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/opportunity_items.dart';
import '../../../core/theme.dart';
import '../../checkin/models/checkin_model.dart';
import '../../habits/providers/habits_provider.dart';
import '../../streak/providers/streak_provider.dart';
import '../../wallet/providers/wallet_list_provider.dart';
import '../providers/mood_insights_provider.dart';
import '../providers/savings_insights_provider.dart';

const _maxBarChartPoints = 30;

final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _compactCurrencyFmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
const _sectionTitleStyle = TextStyle(
  fontFamily: 'Inter',
  fontSize: 18,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
);

class SavingsInsightsScreen extends ConsumerWidget {
  const SavingsInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cumulativePoints = ref.watch(cumulativeSavingsProvider);
    final checkinHistoryAsync = ref.watch(checkinHistoryProvider);
    final streak = ref.watch(streakProvider);
    final totalSaved = ref.watch(totalSavingsProvider);
    final dailySpend = ref.watch(dailySpendProvider);
    final projectedYearSavings = dailySpend * 365;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Savings Insights')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Savings over time', style: _sectionTitleStyle),
            const SizedBox(height: AppSpacing.md),
            cumulativePoints.isEmpty
                ? const _EmptyChartCard(
                    message: 'No savings yet — check in daily to start building your wallet.',
                  )
                : _SavingsLineChart(points: cumulativePoints),
            const SizedBox(height: AppSpacing.xl),

            const Text('Check-in history', style: _sectionTitleStyle),
            const SizedBox(height: AppSpacing.md),
            checkinHistoryAsync.when(
              loading: () => const _EmptyChartCard(message: 'Loading…'),
              error: (_, _) => const _EmptyChartCard(message: 'Failed to load check-in history.'),
              data: (history) => history.isEmpty
                  ? const _EmptyChartCard(message: 'No check-ins yet.')
                  : Column(
                      children: [
                        _CheckinBarChart(history: history),
                        const SizedBox(height: AppSpacing.sm),
                        const _CheckinLegend(),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),

            const Text('Summary', style: _sectionTitleStyle),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.6,
              children: [
                _StatTile(emoji: '💰', label: 'Total Saved', value: _currencyFmt.format(totalSaved)),
                _StatTile(
                  emoji: '🔥',
                  label: 'Longest Streak',
                  value: '${streak.longestStreak} days',
                ),
                _StatTile(
                  emoji: '📅',
                  label: 'Total Clean Days',
                  value: '${streak.totalCleanDays} days',
                ),
                _StatTile(
                  emoji: '📈',
                  label: 'Projected 1-Year Savings',
                  value: _currencyFmt.format(projectedYearSavings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            const Text('What else could this buy?', style: _sectionTitleStyle),
            const SizedBox(height: AppSpacing.md),
            _OpportunityCostCard(dailySpend: dailySpend),
          ],
        ),
      ),
    );
  }
}

class _SavingsLineChart extends StatelessWidget {
  const _SavingsLineChart({required this.points});
  final List<CumulativeSavingsPoint> points;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM');
    final lastIndex = points.length - 1;
    final maxAmount = points.last.cumulativeAmount;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: lastIndex.toDouble().clamp(1, double.infinity),
          minY: 0,
          maxY: maxAmount <= 0 ? 1 : maxAmount * 1.15,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => Text(
                  _compactCurrencyFmt.format(value),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i != 0 && i != lastIndex && i != lastIndex ~/ 2) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      dateFmt.format(points[i].date),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              dotData: const FlDotData(show: false),
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].cumulativeAmount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckinBarChart extends StatelessWidget {
  const _CheckinBarChart({required this.history});
  final List<CheckinModel> history;

  @override
  Widget build(BuildContext context) {
    final recent = history.length > _maxBarChartPoints
        ? history.sublist(history.length - _maxBarChartPoints)
        : history;
    final dateFmt = DateFormat('d MMM');
    final lastIndex = recent.length - 1;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: 1,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: const BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i != 0 && i != lastIndex && i != lastIndex ~/ 2) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      dateFmt.format(recent[i].date),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < recent.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: 1,
                    color: recent[i].isClean ? AppColors.primary : AppColors.error,
                    width: 10,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckinLegend extends StatelessWidget {
  const _CheckinLegend();

  @override
  Widget build(BuildContext context) {
    Widget dot(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );

    return Row(
      children: [
        dot(AppColors.primary, 'Clean'),
        const SizedBox(width: AppSpacing.md),
        dot(AppColors.error, 'Slipped'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.emoji, required this.label, required this.value});
  final String emoji, label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The priciest catalog item still affordable within [budget] (the catalog
/// is sorted ascending by price), or null if even the cheapest isn't yet.
OpportunityItem? _bestAffordable(double budget) {
  OpportunityItem? best;
  for (final item in opportunityItems) {
    if (item.price <= budget) {
      best = item;
    } else {
      break;
    }
  }
  return best;
}

class _OpportunityCostCard extends StatelessWidget {
  const _OpportunityCostCard({required this.dailySpend});
  final double dailySpend;

  static const _horizons = [(label: 'In 3 months', days: 90), (label: 'In 6 months', days: 180), (label: 'In 12 months', days: 365)];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'At ${_currencyFmt.format(dailySpend)}/day, here\'s what your savings could buy:',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < _horizons.length; i++) ...[
            if (i > 0) const Divider(height: 20, color: AppColors.outlineVariant),
            _OpportunityRow(
              label: _horizons[i].label,
              amount: dailySpend * _horizons[i].days,
            ),
          ],
        ],
      ),
    );
  }
}

class _OpportunityRow extends StatelessWidget {
  const _OpportunityRow({required this.label, required this.amount});
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final item = _bestAffordable(amount);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _currencyFmt.format(amount),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (item != null)
          Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(
                item.name,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          )
        else
          const Text(
            'Keep saving — your first treat is close.',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _EmptyChartCard extends StatelessWidget {
  const _EmptyChartCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
