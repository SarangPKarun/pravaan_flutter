import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result.dart';
import '../../../core/supabase_client.dart';
import '../models/product_model.dart';

class ProductRecommendationRepository {
  const ProductRecommendationRepository(this._client);

  final SupabaseClient _client;

  /// Calls the `ai-product-recommendations` Edge Function. The caller is
  /// derived server-side from the forwarded JWT — no body/userId needed.
  Future<Result<List<ProductCategory>, String>> getRecommendedCategories() async {
    try {
      final res = await _client.functions.invoke('ai-product-recommendations');
      final raw = (res.data as Map?)?['categories'] as List?;
      if (raw == null) {
        return const Err('Empty response from ai-product-recommendations');
      }

      final nameMap = ProductCategory.values.asNameMap();
      final categories = raw
          .whereType<String>()
          .map((name) => nameMap[name])
          .whereType<ProductCategory>()
          .toList();
      if (categories.isEmpty) {
        return const Err('No valid categories returned');
      }
      return Ok(categories);
    } on FunctionException catch (e) {
      final details = e.details;
      final error = details is Map ? details['error'] as String? : null;
      return Err(error ?? e.toString());
    } catch (e) {
      return Err(e.toString());
    }
  }
}

final productRecommendationRepositoryProvider =
    Provider<ProductRecommendationRepository>(
  (ref) => ProductRecommendationRepository(ref.watch(supabaseClientProvider)),
);
