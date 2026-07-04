import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../habits/models/habit_model.dart';
import '../providers/onboarding_provider.dart';

// ── Habit catalogue ─────────────────────────────────────────────────────────
typedef _HabitEntry = ({HabitType type, String emoji, String label, String unit});

const _habitCatalogue = <_HabitEntry>[
  (type: HabitType.cigarette, emoji: '🚬', label: 'Cigarette',  unit: 'cigarettes'),
  (type: HabitType.alcohol,   emoji: '🍺', label: 'Alcohol',    unit: 'drinks'),
  (type: HabitType.gutka,     emoji: '🟤', label: 'Tobacco',    unit: 'pieces'),
  (type: HabitType.junkFood,  emoji: '🍔', label: 'Junk Food',  unit: 'servings'),
  (type: HabitType.gambling,  emoji: '🎰', label: 'Gambling',   unit: 'sessions'),
  (type: HabitType.custom,    emoji: '✏️',  label: 'Custom',     unit: 'units'),
];

String _unitFor(HabitType? t) =>
    _habitCatalogue.where((h) => h.type == t).firstOrNull?.unit ?? 'units';

String _emojiFor(HabitType? t) =>
    _habitCatalogue.where((h) => h.type == t).firstOrNull?.emoji ?? '🔥';

// ── Screen ───────────────────────────────────────────────────────────────────
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  bool _submitting = false;

  // Step-0 name controller
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider);
    _nameCtrl = TextEditingController(text: data.fullName ?? '');
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  static const int _totalSteps = 4;

  // ── Navigation helpers ──────────────────────────────────────────────────
  void _next() {
    final data = ref.read(onboardingProvider);

    if (_page == 0) {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) {
        _snack('Please enter your full name.');
        return;
      }
      if (data.dateOfBirth == null) {
        _snack('Please select your date of birth.');
        return;
      }
      if (data.gender == null) {
        _snack('Please select your gender.');
        return;
      }
      ref.read(onboardingProvider.notifier).setFullName(name);
    }

    if (_page == 1) {
      if (data.habitTypes.isEmpty) {
        _snack('Please pick at least one habit.');
        return;
      }
      if (data.habitTypes.contains(HabitType.custom) &&
          (data.customHabitName?.trim().isEmpty ?? true)) {
        _snack('Please describe your custom habit.');
        return;
      }
    }

    if (_page == 2) {
      final hasZeroCost = data.habitTypes.any(
        (t) => (data.habitDetails[t]?.unitCost ?? 0) <= 0,
      );
      if (hasZeroCost) {
        _snack('Enter a cost for each habit.');
        return;
      }
    }

    if (_page == 3) {
      _complete();
      return;
    }

    setState(() => _page++);
    _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  void _back() {
    if (_page == 0) return;
    setState(() => _page--);
    _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  Future<void> _complete() async {
    final data = ref.read(onboardingProvider);
    if (data.goalTargetDate == null) {
      _snack('Please pick a target date for your goal.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(onboardingProvider.notifier).complete();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _snack('Error saving: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(page: _page, onBack: _page > 0 ? _back : null),
            _ProgressBar(page: _page, total: _totalSteps),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step0(data: data, nameCtrl: _nameCtrl),
                  _Step1(data: data),
                  const _Step2(),
                  const _Step3(),
                ],
              ),
            ),
            _BottomBar(
              page: _page,
              total: _totalSteps,
              isLoading: _submitting || data.isUploadingAvatar,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.page, this.onBack});
  final int page;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          Text(
            'Step ${page + 1} of 4',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ── Progress bar ─────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.page, required this.total});
  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (page + 1) / total),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        builder: (_, value, _) => ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 5,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.page,
    required this.total,
    required this.isLoading,
    required this.onNext,
  });
  final int page;
  final int total;
  final bool isLoading;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      child: AppButton(
        label: page == total - 1 ? 'Start my journey 🚀' : 'Continue',
        isLoading: isLoading,
        onPressed: onNext,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Step 0 — Personal details
// ════════════════════════════════════════════════════════════════════════════
class _Step0 extends ConsumerStatefulWidget {
  const _Step0({required this.data, required this.nameCtrl});
  final OnboardingData data;
  final TextEditingController nameCtrl;

  @override
  ConsumerState<_Step0> createState() => _Step0State();
}

class _Step0State extends ConsumerState<_Step0> {
  File? _localImage;

  static const _genderOptions = [
    ('male', 'Male'),
    ('female', 'Female'),
    ('other', 'Other'),
    ('prefer_not_to_say', 'Prefer not to say'),
  ];

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    setState(() => _localImage = File(picked.path));
    try {
      await ref
          .read(onboardingProvider.notifier)
          .uploadAvatar(File(picked.path));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Photo upload failed. You can add it later.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ));
      }
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: 'Select your date of birth',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(onboardingProvider.notifier).setDateOfBirth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final dobChosen = data.dateOfBirth != null;
    final dobFmt = dobChosen
        ? DateFormat('d MMM yyyy').format(data.dateOfBirth!)
        : null;

    ImageProvider? avatarImage;
    if (_localImage != null) {
      avatarImage = FileImage(_localImage!);
    } else if (data.avatarUrl != null) {
      avatarImage = NetworkImage(data.avatarUrl!);
    }

    final initials = widget.nameCtrl.text.trim().isNotEmpty
        ? widget.nameCtrl.text.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about\nyourself 👋',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text('We need these details for your wallet and health insights.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),

          // ── Avatar picker ──────────────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.successTint,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? initials != null
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.person_rounded,
                                color: AppColors.primary, size: 40)
                        : null,
                  ),
                  if (data.isUploadingAvatar)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black26,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Optional — add photo later',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Full name ──────────────────────────────────────────────────
          _SectionCard(
            title: 'Full name',
            child: TextFormField(
              controller: widget.nameCtrl,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Your full name',
                prefixIcon: Icon(Icons.person_outline_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
              onChanged: (_) => setState(() {}), // refresh initials
            ),
          ),
          const SizedBox(height: 14),

          // ── Date of birth ──────────────────────────────────────────────
          _SectionCard(
            title: 'Date of birth',
            child: GestureDetector(
              onTap: _pickDob,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: dobChosen ? AppColors.successTint : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: dobChosen
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                    width: dobChosen ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cake_rounded,
                      size: 20,
                      color: dobChosen
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dobChosen ? dobFmt! : 'Select date of birth',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: dobChosen
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: dobChosen
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: dobChosen
                          ? AppColors.primary
                          : AppColors.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Gender ─────────────────────────────────────────────────────
          _SectionCard(
            title: 'Gender',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _genderOptions.map((opt) {
                final selected = data.gender == opt.$1;
                return GestureDetector(
                  onTap: () => ref
                      .read(onboardingProvider.notifier)
                      .setGender(opt.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      opt.$2,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Step 1 — Habit selector grid (multi-select)
// ════════════════════════════════════════════════════════════════════════════
class _Step1 extends ConsumerStatefulWidget {
  const _Step1({required this.data});
  final OnboardingData data;

  @override
  ConsumerState<_Step1> createState() => _Step1State();
}

class _Step1State extends ConsumerState<_Step1> {
  late final TextEditingController _customCtrl;

  @override
  void initState() {
    super.initState();
    _customCtrl = TextEditingController(
      text: widget.data.customHabitName ?? '',
    );
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final showCustomInput = data.habitTypes.contains(HabitType.custom);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What are you\nquitting? 💪',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Select all that apply.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _habitCatalogue.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.15,
                    ),
                    itemBuilder: (_, i) {
                      final h = _habitCatalogue[i];
                      final selected = data.habitTypes.contains(h.type);
                      return _HabitTile(
                        emoji: h.emoji,
                        label: h.label,
                        isSelected: selected,
                        onTap: () => notifier.toggleHabitType(h.type),
                      );
                    },
                  ),
                  // Custom habit text input — shown when custom is selected
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: showCustomInput
                        ? Padding(
                            key: const ValueKey('custom-input'),
                            padding: const EdgeInsets.only(top: 16),
                            child: TextField(
                              controller: _customCtrl,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: 'Describe your habit…',
                                prefixIcon: Icon(Icons.edit_rounded,
                                    color: AppColors.textSecondary, size: 20),
                              ),
                              onChanged: notifier.setCustomHabitName,
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-input')),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String emoji, label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Step 2 — Per-habit quantity + cost
// ════════════════════════════════════════════════════════════════════════════
class _Step2 extends ConsumerStatefulWidget {
  const _Step2();

  @override
  ConsumerState<_Step2> createState() => _Step2State();
}

class _Step2State extends ConsumerState<_Step2> {
  // One controller per selected HabitType, keyed by type.
  final Map<HabitType, TextEditingController> _costCtrls = {};

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider);
    for (final type in data.habitTypes) {
      final existing = data.habitDetails[type]?.unitCost ?? 0.0;
      _costCtrls[type] = TextEditingController(
        text: existing > 0 ? existing.toStringAsFixed(0) : '',
      );
    }
  }

  @override
  void dispose() {
    for (final ctrl in _costCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final fmt = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your daily habits',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text('Help us calculate how much you can save.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),

          // One card per selected habit
          for (final type in data.habitTypes) ...[
            _HabitDetailCard(
              type: type,
              detail: data.habitDetails[type] ?? const HabitDetail(),
              costCtrl: _costCtrls[type]!,
              fmt: fmt,
            ),
            const SizedBox(height: 16),
          ],

          // Total row — only when multiple habits selected
          if (data.habitTypes.length > 1 && data.dailySpend > 0) ...[
            const SizedBox(height: 4),
            _TotalSpendRow(totalSpend: data.dailySpend, fmt: fmt),
          ],
        ],
      ),
    );
  }
}

class _HabitDetailCard extends ConsumerWidget {
  const _HabitDetailCard({
    required this.type,
    required this.detail,
    required this.costCtrl,
    required this.fmt,
  });
  final HabitType type;
  final HabitDetail detail;
  final TextEditingController costCtrl;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingProvider.notifier);
    final unit = _unitFor(type);
    final emoji = _emojiFor(type);
    final label = _habitCatalogue
        .where((h) => h.type == type)
        .firstOrNull
        ?.label ?? type.name;

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
          // Habit pill header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successTint,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$emoji  $label',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quantity stepper
          Text(
            'How many $unit per day?',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _QtyStepperRow(
            qty: detail.dailyQty,
            onDecrement: () => notifier.setHabitQty(type, detail.dailyQty - 1),
            onIncrement: () => notifier.setHabitQty(type, detail.dailyQty + 1),
          ),
          const SizedBox(height: 16),

          // Cost field
          Text(
            'Cost per $unit (₹)',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: costCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: const InputDecoration(
              prefixText: '₹ ',
              hintText: '0',
            ),
            onChanged: (v) {
              final cost = double.tryParse(v.trim()) ?? 0;
              notifier.setHabitCost(type, cost);
            },
          ),

          // Live daily spend
          if (detail.dailySpend > 0) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily spend',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  fmt.format(detail.dailySpend),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalSpendRow extends StatelessWidget {
  const _TotalSpendRow({required this.totalSpend, required this.fmt});
  final double totalSpend;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total daily spend',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            fmt.format(totalSpend),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

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
          Text(title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _QtyStepperRow extends StatelessWidget {
  const _QtyStepperRow(
      {required this.qty, required this.onDecrement, required this.onIncrement});
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(icon: Icons.remove_rounded, onTap: onDecrement),
        Expanded(
          child: Center(
            child: Text(
              '$qty',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        _StepBtn(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.successTint,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Step 3 — Goal + target date + projected savings
// ════════════════════════════════════════════════════════════════════════════
class _Step3 extends ConsumerStatefulWidget {
  const _Step3();

  @override
  ConsumerState<_Step3> createState() => _Step3State();
}

class _Step3State extends ConsumerState<_Step3> {
  late final TextEditingController _goalCtrl;
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _dateFmt = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider);
    _goalCtrl = TextEditingController(text: data.savingGoal ?? '');
  }

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 10),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(onboardingProvider.notifier).setGoalTargetDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final dateChosen = data.goalTargetDate != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set your goal 🎯',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('What will you do with your savings?',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),

          // ── Goal name field ──────────────────────────────────────────
          _SectionCard(
            title: 'What are you saving for?',
            child: TextField(
              controller: _goalCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. New phone, Family trip',
                prefixIcon: Icon(Icons.star_outline_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
              onChanged: ref.read(onboardingProvider.notifier).setGoal,
            ),
          ),
          const SizedBox(height: 14),

          // ── Target date tile ─────────────────────────────────────────
          GestureDetector(
            onTap: _pickTargetDate,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: dateChosen ? AppColors.successTint : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: dateChosen
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: dateChosen ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.calendar_today_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateChosen ? 'Target date' : 'Choose your target date',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (dateChosen) ...[
                          const SizedBox(height: 2),
                          Text(
                            _dateFmt.format(data.goalTargetDate!),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: dateChosen ? AppColors.primary : AppColors.outline,
                  ),
                ],
              ),
            ),
          ),

          // ── Projection card — fades in once target date is set ───────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: dateChosen
                ? Padding(
                    key: const ValueKey('projection'),
                    padding: const EdgeInsets.only(top: 20),
                    child: _GoalProjectionCard(
                      goal: data.savingGoal,
                      amount: data.savingsBy(data.goalTargetDate!),
                      targetDate: data.goalTargetDate!,
                      fmt: _fmt,
                      dateFmt: _dateFmt,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-projection')),
          ),
        ],
      ),
    );
  }
}

class _GoalProjectionCard extends StatelessWidget {
  const _GoalProjectionCard({
    required this.goal,
    required this.amount,
    required this.targetDate,
    required this.fmt,
    required this.dateFmt,
  });
  final String? goal;
  final double amount;
  final DateTime targetDate;
  final NumberFormat fmt;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final goalLine = (goal != null && goal!.isNotEmpty)
        ? 'Enough for $goal 🎉'
        : 'That\'s real money back in your pocket. 🎉';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D38), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Text(
            'By ${dateFmt.format(targetDate)} you could save',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(amount),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            goalLine,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
