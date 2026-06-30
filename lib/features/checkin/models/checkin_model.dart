class CheckinModel {
  const CheckinModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.isClean,
    required this.mood,
    this.cravingIntensity,
    this.cravingTrigger,
    this.cravingTime,
    this.note,
  });

  final String id;
  final String userId;
  final DateTime date;
  final bool isClean;

  /// 1 (worst) → 5 (best)
  final int mood;

  /// 1 (mild) → 5 (overwhelming) — only set when !isClean
  final int? cravingIntensity;

  /// 'stress' | 'boredom' | 'social' | 'other' — only set when !isClean
  final String? cravingTrigger;

  /// "HH:mm" string, time when the craving hit — only set when !isClean
  final String? cravingTime;

  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date.toIso8601String(),
        'is_clean': isClean,
        'mood': mood,
        'craving_intensity': cravingIntensity,
        'craving_trigger': cravingTrigger,
        'craving_time': cravingTime,
        'note': note,
      };

  factory CheckinModel.fromJson(Map<String, dynamic> json) => CheckinModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        date: DateTime.parse(json['date'] as String),
        isClean: json['is_clean'] as bool,
        mood: json['mood'] as int,
        cravingIntensity: json['craving_intensity'] as int?,
        cravingTrigger: json['craving_trigger'] as String?,
        cravingTime: json['craving_time'] as String?,
        note: json['note'] as String?,
      );
}
