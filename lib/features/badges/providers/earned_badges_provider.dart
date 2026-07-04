import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/local/hive_service.dart';

/// Reactive view of `HiveService.badgesBox` — maps earned badge ids to the
/// timestamp they were earned at. Re-emits whenever the box changes, so a
/// badge earned while the badges screen is open shows up immediately.
final earnedBadgesProvider = StreamProvider<Map<String, DateTime>>((ref) async* {
  final box = HiveService.badgesBox;

  Map<String, DateTime> snapshot() => {
        for (final key in box.keys.cast<String>())
          key: DateTime.parse(box.get(key) as String),
      };

  yield snapshot();
  await for (final _ in box.watch()) {
    yield snapshot();
  }
});
