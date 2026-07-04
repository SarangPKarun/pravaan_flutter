import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../repositories/ai_dashboard_message_repository.dart';

final aiDashboardMessageProvider = FutureProvider<String>((ref) async {
  final result =
      await ref.watch(aiDashboardMessageRepositoryProvider).getMessage();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw Exception(error),
  };
});
