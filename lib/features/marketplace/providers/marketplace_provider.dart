import 'package:flutter/material.dart';
import '../models/template_model.dart';
import '../services/marketplace_service.dart';

class MarketplaceProvider extends ChangeNotifier {
  final MarketplaceService _service = MarketplaceService();
  
  List<TemplateModel> _templates = [];
  bool _isLoading = false;
  int _currentPage = 0;
  bool _hasMore = true;

  List<TemplateModel> get templates => _templates;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> fetchPublicTemplates({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      _templates.clear();
      notifyListeners();
    }

    if (!_hasMore) return;

    _isLoading = true;
    notifyListeners();

    final newTemplates = await _service.fetchPublicTemplates(page: _currentPage);
    
    if (newTemplates.length < 20) {
      _hasMore = false;
    }

    _templates.addAll(newTemplates);
    _currentPage++;
    _isLoading = false;
    notifyListeners();
  }

  void clearState() {
    _templates.clear();
    _currentPage = 0;
    _hasMore = true;
    _isLoading = false;
    notifyListeners();
  }
}
