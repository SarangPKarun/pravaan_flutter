import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../badges/providers/earned_badges_provider.dart';
import '../../habits/models/habit_model.dart';
import '../../wallet/providers/wallet_list_provider.dart';
import '../habit_display.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

const _genderLabel = {
  'male': 'Male',
  'female': 'Female',
  'other': 'Other',
  'prefer_not_to_say': 'Prefer not to say',
};

final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _dateFmt = DateFormat('d MMM yyyy');

String _maskPhone(String? phone) {
  if (phone == null || phone.length < 5) return phone ?? '—';
  final last4 = phone.substring(phone.length - 4);
  final prefix = phone.length > 10 ? phone.substring(0, phone.length - 10) : '';
  return '${prefix.isEmpty ? '' : '$prefix '}••••••$last4';
}

int _ageFrom(DateTime dob) {
  final now = DateTime.now();
  int age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _shareCardKey = GlobalKey();
  final _shareButtonKey = GlobalKey();

  Future<void> _shareSummary() async {
    try {
      final boundary =
          _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final image = await boundary?.toImage(pixelRatio: 3.0);
      final byteData = await image?.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final buttonBox =
          _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = buttonBox != null
          ? buttonBox.localToGlobal(Offset.zero) & buttonBox.size
          : null;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png', name: 'pravaan_summary.png')],
          text: 'My Pravaan journey so far! 🌱',
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      // Sharing is best-effort — a failure here shouldn't break the profile screen.
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text(
          'Delete your account?',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'This permanently deletes your account and all your data. This cannot be undone.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authNotifierProvider.notifier).deleteAccount();
            },
            child: const Text('Delete',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);
    final user = authAsync.asData?.value;
    final meta = user?.userMetadata ?? {};

    final String? fullName = meta['full_name'] as String?;
    final String? avatarUrl = meta['avatar_url'] as String?;
    final String? phone = user?.phone;
    final String? dobRaw = meta['date_of_birth'] as String?;
    final DateTime? dob = dobRaw != null ? DateTime.tryParse(dobRaw) : null;
    final String? gender = meta['gender'] as String?;

    final List<HabitType> habitTypes = parseHabitTypes(meta['habit_types']);
    final Map<HabitType, HabitDetail> habitDetails = parseHabitDetails(meta['habit_details']);
    final String? quitDateRaw = meta['quit_date'] as String?;
    final DateTime? quitDate = quitDateRaw != null ? DateTime.tryParse(quitDateRaw) : null;
    final int? daysQuit =
        quitDate != null ? DateTime.now().difference(quitDate).inDays : null;
    final double totalDailySpend = habitTypes.fold(0.0, (sum, type) {
      final detail = habitDetails[type];
      return sum + (detail != null ? detail.dailyQty * detail.unitCost : 0.0);
    });

    final DateTime? joinedDate =
        user?.createdAt != null ? DateTime.tryParse(user!.createdAt) : null;

    final earnedBadgeCount = ref.watch(earnedBadgesProvider).value?.length ?? 0;
    final totalSaved = ref.watch(totalSavingsProvider);

    final initials = fullName != null && fullName.isNotEmpty
        ? fullName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    final int? age = dob != null ? _ageFrom(dob) : null;

    final isLoading = authAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeader(
              fullName: fullName,
              phone: phone,
              avatarUrl: avatarUrl,
              initials: initials,
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Shareable summary card ──────────────────────────────
                const SizedBox(height: AppSpacing.lg),
                RepaintBoundary(
                  key: _shareCardKey,
                  child: _SummaryCard(
                    name: fullName ?? 'User',
                    joinedDate: joinedDate,
                    habitTypes: habitTypes,
                    badgeCount: earnedBadgeCount,
                    totalSaved: totalSaved,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  key: _shareButtonKey,
                  width: double.infinity,
                  child: AppButton(
                    label: 'Share your journey',
                    icon: const Icon(Icons.ios_share, size: 18, color: Colors.white),
                    onPressed: _shareSummary,
                  ),
                ),

                // ── Personal info ─────────────────────────────────────
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(title: 'Personal details'),
                const SizedBox(height: AppSpacing.sm),
                _InfoCard(children: [
                  if (dob != null)
                    _InfoRow(
                      icon: Icons.cake_rounded,
                      label: 'Date of birth',
                      value: _dateFmt.format(dob),
                    ),
                  if (dob != null && age != null)
                    _InfoRow(icon: Icons.person_rounded, label: 'Age', value: '$age years'),
                  if (gender != null)
                    _InfoRow(
                      icon: Icons.wc_rounded,
                      label: 'Gender',
                      value: _genderLabel[gender] ?? gender,
                    ),
                  if (joinedDate != null)
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Joined',
                      value: _dateFmt.format(joinedDate),
                      isLast: true,
                    ),
                  if (dob == null && gender == null && joinedDate == null)
                    const _EmptyRow(message: 'Personal details not filled'),
                ]),

                // ── Habit(s) summary ────────────────────────────────────
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(title: 'Habit(s) summary'),
                const SizedBox(height: AppSpacing.sm),
                _InfoCard(children: [
                  for (final type in habitTypes)
                    _InfoRow(
                      icon: Icons.local_fire_department_rounded,
                      label: habitDisplayInfo[type]!.label,
                      value: habitDetails[type] != null
                          ? '${habitDetails[type]!.dailyQty} ${habitDisplayInfo[type]!.unit}/day'
                          : '—',
                    ),
                  if (habitTypes.isNotEmpty)
                    _InfoRow(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Daily spend',
                      value: _currencyFmt.format(totalDailySpend),
                    ),
                  if (quitDate != null)
                    _InfoRow(
                      icon: Icons.flag_rounded,
                      label: 'Quit date',
                      value: _dateFmt.format(quitDate),
                    ),
                  if (daysQuit != null && daysQuit > 0)
                    _InfoRow(
                      icon: Icons.emoji_events_rounded,
                      label: 'Days quit',
                      value: '$daysQuit days',
                      isLast: true,
                    ),
                  if (habitTypes.isEmpty)
                    const _EmptyRow(message: 'Habit data not filled'),
                ]),

                // ── Settings ────────────────────────────────────────────
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(title: 'Settings'),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Notification Preferences',
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.push('/notification-preferences'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Edit Habits',
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.push('/edit-habits'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'My Badges',
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.push('/badges'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Community',
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.push('/community'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Sign Out',
                  variant: AppButtonVariant.outline,
                  isLoading: false,
                  onPressed:
                      isLoading ? null : () => ref.read(authNotifierProvider.notifier).signOut(),
                ),

                // ── Danger zone ───────────────────────────────────────
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Danger zone',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Permanently deletes your account and all associated data. This cannot be undone.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape:
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                          onPressed: isLoading ? null : () => _confirmDelete(context),
                          child: const Text(
                            'Delete Account',
                            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shareable summary card ──────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.name,
    required this.joinedDate,
    required this.habitTypes,
    required this.badgeCount,
    required this.totalSaved,
  });

  final String name;
  final DateTime? joinedDate;
  final List<HabitType> habitTypes;
  final int badgeCount;
  final double totalSaved;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            joinedDate != null ? 'Joined ${_dateFmt.format(joinedDate!)}' : 'Welcome to Pravaan',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (habitTypes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              children: [
                for (final type in habitTypes)
                  Text(
                    '${habitDisplayInfo[type]!.emoji} ${habitDisplayInfo[type]!.label}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(emoji: '🏅', label: 'Badges earned', value: '$badgeCount'),
              ),
              Expanded(
                child: _SummaryStat(
                  emoji: '💰',
                  label: 'Total saved',
                  value: _currencyFmt.format(totalSaved),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.emoji, required this.label, required this.value});
  final String emoji, label, value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
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
          style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Profile header ────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.fullName,
    required this.phone,
    required this.avatarUrl,
    required this.initials,
  });
  final String? fullName, phone, avatarUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.lg,
        bottom: AppSpacing.xl,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004D38), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl!,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                      errorWidget: (_, _, _) => _InitialsAvatar(initials: initials),
                    ),
                  )
                : _InitialsAvatar(initials: initials),
          ),
          const SizedBox(height: 14),
          Text(
            fullName ?? 'User',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _maskPhone(phone),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });
  final IconData icon;
  final String label, value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 48, color: AppColors.outlineVariant),
      ],
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
