import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/template_model.dart';
import 'package:flutter/foundation.dart';

class MarketplaceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<TemplateModel>> fetchPublicTemplates({int page = 0, int limit = 20}) async {
    try {
      final response = await _supabase
          .from('templates')
          .select()
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return (response as List).map((e) => TemplateModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching public templates: $e');
      return [];
    }
  }

  Future<TemplateModel?> fetchTemplateById(String id) async {
    try {
      final response = await _supabase
          .from('templates')
          .select()
          .eq('id', id)
          .single();

      return TemplateModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching template by id: $e');
      return null;
    }
  }

  Future<bool> shareTemplate(TemplateModel template) async {
    try {
      final data = template.toJson();
      data.remove('id'); // DB will generate ID
      data.remove('created_at');
      data.remove('updated_at');

      await _supabase.from('templates').insert(data);
      return true;
    } catch (e) {
      debugPrint('Error sharing template: $e');
      return false;
    }
  }
}
