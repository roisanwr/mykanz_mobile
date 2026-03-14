import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/category_model.dart';

part 'category_repository.g.dart';

class CategoryRepository {
  final SupabaseClient _client;

  final AuthService _authService;

  CategoryRepository(this._client, this._authService);

  Future<List<CategoryModel>> getCategories({String? type}) async {
    if (_authService.currentUserId == null) return [];
    var query = _client.from('categories').select().eq('user_id', _authService.currentUserId!).isFilter('deleted_at', null);
    
    if (type != null) {
      query = query.eq('type', type);
    }
    
    final response = await query.order('name', ascending: true);
    return (response as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<CategoryModel> createCategory({
    required String name,
    required String type,
  }) async {
    final response = await _client.from('categories').insert({
      'name': name,
      'type': type,
      'user_id': _authService.currentUserId,
    }).select().single();
    
    return CategoryModel.fromJson(response);
  }

  Future<void> deleteCategory(String id) async {
    await _client.from('categories').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('user_id', _authService.currentUserId!);
  }
}

@riverpod
CategoryRepository categoryRepository(Ref ref) {
  return CategoryRepository(ref.watch(supabaseClientProvider), ref.watch(authServiceProvider));
}
