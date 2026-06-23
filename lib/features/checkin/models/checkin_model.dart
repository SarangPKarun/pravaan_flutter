class CheckinModel {
  const CheckinModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.isClean,
    required this.mood,
    this.note,
  });

  final String id;
  final String userId;
  final DateTime date;
  final bool isClean;

  /// 1 (worst) → 5 (best)
  final int mood;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date.toIso8601String(),
        'is_clean': isClean,
        'mood': mood,
        'note': note,
      };

  factory CheckinModel.fromJson(Map<String, dynamic> json) => CheckinModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        date: DateTime.parse(json['date'] as String),
        isClean: json['is_clean'] as bool,
        mood: json['mood'] as int,
        note: json['note'] as String?,
      );
}
