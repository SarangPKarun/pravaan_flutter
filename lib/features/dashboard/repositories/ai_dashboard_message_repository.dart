import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';

class AiDashboardMessageRepository {
  const AiDashboardMessageRepository(this._client);

  final SupabaseClient _client;

  /// Calls the `ai-dashboard-message` Edge Function. The caller is derived
  /// server-side from the forwarded JWT — no body/userId needed.
  Future<Result<String, String>> getMessage() async {
    try {
      final res = await _client.functions.invoke('ai-dashboard-message');
      final message = (res.data as Map?)?['message'] as String?;
      if (message == null || message.isEmpty) {
        return const Err('Empty response from ai-dashboard-message');
      }
      return Ok(message);
    } on FunctionException catch (e) {
      final details = e.details;
      final error = details is Map ? details['error'] as String? : null;
      return Err(error ?? e.toString());
    } catch (e) {
      return Err(e.toString());
    }
  }
}

final aiDashboardMessageRepositoryProvider =
    Provider<AiDashboardMessageRepository>(
  (ref) => AiDashboardMessageRepository(ref.watch(supabaseClientProvider)),
);
