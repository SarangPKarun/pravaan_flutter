// Static health benefit milestones keyed by days clean.
// Data based on well-documented nicotine/tobacco cessation research.

class HealthBenefit {
  const HealthBenefit({
    required this.emoji,
    required this.title,
    required this.detail,
  });

  final String emoji;

  /// Short label used in chips and list rows.
  final String title;

  /// One-sentence description used in expanded cards.
  final String detail;
}

const Map<int, List<HealthBenefit>> healthBenefits = {
  0: [
    HealthBenefit(
      emoji: '❤️',
      title: 'Heart rate drops',
      detail: 'Blood pressure and heart rate begin normalizing within 20 minutes of your last cigarette.',
    ),
  ],
  1: [
    HealthBenefit(
      emoji: '🩸',
      title: 'Blood oxygen normalizes',
      detail: 'Carbon monoxide leaves your blood and oxygen levels return to normal.',
    ),
    HealthBenefit(
      emoji: '⚡',
      title: 'Heart attack risk starts falling',
      detail: 'The risk of a cardiac event begins to decline within the first 24 hours.',
    ),
  ],
  2: [
    HealthBenefit(
      emoji: '👅',
      title: 'Taste & smell return',
      detail: 'Damaged nerve endings start to regrow and food tastes noticeably more vivid.',
    ),
  ],
  3: [
    HealthBenefit(
      emoji: '🚫',
      title: 'Nicotine fully cleared',
      detail: 'Your body is now 100% free of nicotine and its by-products.',
    ),
    HealthBenefit(
      emoji: '🌬️',
      title: 'Airways relax',
      detail: 'Bronchial tubes begin to relax and widen, making every breath easier.',
    ),
  ],
  7: [
    HealthBenefit(
      emoji: '📉',
      title: 'Cravings ease',
      detail: 'Acute cravings drop significantly in both frequency and intensity after one week.',
    ),
  ],
  10: [
    HealthBenefit(
      emoji: '😌',
      title: 'Withdrawal subsides',
      detail: 'Most physical withdrawal symptoms — irritability, headaches, restlessness — have faded.',
    ),
  ],
  14: [
    HealthBenefit(
      emoji: '🔄',
      title: 'Circulation improves',
      detail: 'Blood flow to your hands and feet improves noticeably; skin feels warmer.',
    ),
    HealthBenefit(
      emoji: '🫁',
      title: 'Lung function begins recovering',
      detail: 'Early measurable improvements in airway capacity and breathing efficiency.',
    ),
  ],
  21: [
    HealthBenefit(
      emoji: '🧠',
      title: 'Habit loop breaks',
      detail: 'Three weeks rewires the automatic craving response in the brain\'s reward circuit.',
    ),
  ],
  30: [
    HealthBenefit(
      emoji: '📈',
      title: 'Lung function +30%',
      detail: 'One month in: lung capacity shows a significant measurable improvement.',
    ),
    HealthBenefit(
      emoji: '🤧',
      title: 'Less coughing',
      detail: 'Mucus production normalises and the chronic smoker\'s cough begins to clear.',
    ),
  ],
  45: [
    HealthBenefit(
      emoji: '🌿',
      title: 'Sinuses clear',
      detail: 'Chronic sinus congestion caused by smoke irritation resolves.',
    ),
  ],
  60: [
    HealthBenefit(
      emoji: '🏃',
      title: 'Exercise easier',
      detail: 'Cardiovascular stamina and endurance improve noticeably during physical activity.',
    ),
  ],
  90: [
    HealthBenefit(
      emoji: '♻️',
      title: 'Cilia regrown',
      detail: 'Tiny hair-like cells lining the lungs have fully regenerated, clearing debris and reducing infections.',
    ),
  ],
  180: [
    HealthBenefit(
      emoji: '💪',
      title: 'Infection resistance up',
      detail: 'Lungs handle bacteria and viruses far more effectively than six months ago.',
    ),
  ],
  270: [
    HealthBenefit(
      emoji: '🛡️',
      title: 'Heart attack risk halved',
      detail: 'Nine months in: risk of myocardial infarction is dramatically reduced.',
    ),
  ],
  365: [
    HealthBenefit(
      emoji: '🏆',
      title: 'Heart disease risk halved',
      detail: 'One full year clean: your risk of coronary heart disease is now half that of a smoker.',
    ),
  ],
  730: [
    HealthBenefit(
      emoji: '🧩',
      title: 'Stroke risk normalizes',
      detail: 'Two years in: stroke risk has fallen to that of a lifelong non-smoker.',
    ),
  ],
  1825: [
    HealthBenefit(
      emoji: '🎗️',
      title: 'Cancer risk halved',
      detail: 'Five years: risk of cancers of the mouth, throat, and oesophagus is cut in half.',
    ),
  ],
  3650: [
    HealthBenefit(
      emoji: '🌟',
      title: 'Lung cancer risk halved',
      detail: 'Ten years: lung cancer death rate equals that of a non-smoker.',
    ),
  ],
  5475: [
    HealthBenefit(
      emoji: '👑',
      title: 'Heart disease risk = non-smoker',
      detail: 'Fifteen years: full cardiovascular recovery — your heart disease risk is identical to someone who never smoked.',
    ),
  ],
};

// ── Helpers ───────────────────────────────────────────────────────────────────

/// All milestones the user has already passed, in chronological order.
/// Returns records of (day, benefit) so the UI can label each entry.
List<(int day, HealthBenefit benefit)> unlockedBenefits(int daysClean) {
  final result = <(int, HealthBenefit)>[];
  for (final entry in healthBenefits.entries) {
    if (entry.key <= daysClean) {
      for (final b in entry.value) {
        result.add((entry.key, b));
      }
    }
  }
  result.sort((a, b) => a.$1.compareTo(b.$1));
  return result;
}

/// The very next milestone the user hasn't reached yet, or null if all unlocked.
(int day, HealthBenefit benefit)? nextBenefit(int daysClean) {
  final upcoming = healthBenefits.entries
      .where((e) => e.key > daysClean)
      .toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  if (upcoming.isEmpty) return null;
  final first = upcoming.first;
  return (first.key, first.value.first);
}
