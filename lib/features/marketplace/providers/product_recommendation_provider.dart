import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../models/product_model.dart';
import '../repositories/product_recommendation_repository.dart';

final productRecommendationProvider =
    FutureProvider<List<ProductCategory>>((ref) async {
  final result = await ref
      .watch(productRecommendationRepositoryProvider)
      .getRecommendedCategories();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw Exception(error),
  };
});
