import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/measurement_template.dart';
import '../models/measurement_record.dart';
import '../models/customer_model.dart';
import '../../main.dart';
import '../core/utils/connectivity_helper.dart';
import '../core/utils/supabase_error_handler.dart';

class TemplateProvider extends ChangeNotifier {
  SupabaseClient get _supabase => Supabase.instance.client;
  
  List<ProductTemplate> _templates = [];
  List<MeasurementRecord> _measurements = [];
  bool _isLoading = false;
  DateTime? _lastMeasurementFetch;

  final Set<String> _archivedTemplateIds = {};
  int _cacheVersion = 0;

  // Cache: template ID -> measurement count (avoids iterating _measurements repeatedly)
  Map<String, int> _templateMeasurementCounts = {};
  bool _templateCountsValid = false;

  // Cache: "$customerId|$templateId" -> latest MeasurementRecord (avoids repeated sorting)
  final Map<String, MeasurementRecord?> _latestMeasurementCache = {};
  bool _latestCacheValid = false;

  List<ProductTemplate> get templates => [
    ...systemTemplates.where((t) => !_archivedTemplateIds.contains(t.id)),
    ..._templates.where((t) => !_archivedTemplateIds.contains(t.id)),
  ];
  List<ProductTemplate> get myTemplates =>
      _templates.where((t) => !_archivedTemplateIds.contains(t.id)).toList();
  List<ProductTemplate> get allTemplatesWithArchived => [
    ...systemTemplates,
    ..._templates,
  ];
  List<MeasurementRecord> get measurements => _measurements;
  bool get isLoading => _isLoading;
  int get cacheVersion => _cacheVersion;
  Set<String> get archivedTemplateIds => Set.unmodifiable(_archivedTemplateIds);

  Customer? _selectedCustomer;
  Customer? get selectedCustomer => _selectedCustomer;
  String? get selectedCustomerId => _selectedCustomer?.id;

  void setSelectedCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  int _activeIndex = 0;
  int get activeIndex => _activeIndex;

  void setIndex(int index) {
    _activeIndex = index;
    notifyListeners();
  }

  /// Full reset for logout/user switch — clears all state safely.
  void clearState() {
    _templates = [];
    _measurements = [];
    _isLoading = false;
    _lastMeasurementFetch = null;
    _archivedTemplateIds.clear();
    _cacheVersion = 0;
    _templateMeasurementCounts = {};
    _templateCountsValid = false;
    _latestMeasurementCache.clear();
    _latestCacheValid = false;
    _selectedCustomer = null;
    _activeIndex = 0;
    notifyListeners();
  }

  Future<bool> _ensureOnline() async {
    final isOnline = await ConnectivityHelper.hasInternet();
    if (!isOnline) {
      showGlobalSnackBar('Internet required. Please connect and try again.', isError: true);
      return false;
    }
    return true;
  }

  bool _isStale() {
    if (_lastMeasurementFetch == null) return true;
    return DateTime.now().difference(_lastMeasurementFetch!).inSeconds > 60;
  }

  Future<void> fetchMeasurements() async {
    if (!_isStale() && _measurements.isNotEmpty) return;
    await _forceFetchMeasurements();
  }

  Future<void> forceRefresh() async {
    await _forceFetchMeasurements();
  }

  void _invalidateMeasurementCaches() {
    _templateCountsValid = false;
    _latestCacheValid = false;
  }

  void _buildTemplateMeasurementCounts() {
    _templateMeasurementCounts = {};
    for (final m in _measurements) {
      _templateMeasurementCounts[m.templateId] =
          (_templateMeasurementCounts[m.templateId] ?? 0) + 1;
    }
    _templateCountsValid = true;
  }

  void _buildLatestMeasurementCache() {
    _latestMeasurementCache.clear();
    for (final m in _measurements) {
      final key = '${m.customerId}|${m.templateId}';
      final existing = _latestMeasurementCache[key];
      if (existing == null || m.date.isAfter(existing.date)) {
        _latestMeasurementCache[key] = m;
      }
    }
    _latestCacheValid = true;
  }

  Future<void> _forceFetchMeasurements() async {
    if (!await _ensureOnline()) return;

    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final templateRes = await _supabase
          .from('measurement_templates')
          .select()
          .eq('tailor_id', user.id);
      
      _templates = (templateRes as List).map((e) => ProductTemplate.fromMap(e)).toList();

      final measurementRes = await _supabase
          .from('measurement_records')
          .select()
          .eq('tailor_id', user.id)
          .order('date', ascending: false)
          .range(0, 199);
          
      _measurements = (measurementRes as List).map((e) => MeasurementRecord.fromJson(e)).toList();
      _lastMeasurementFetch = DateTime.now();
      _cacheVersion++;
      _invalidateMeasurementCaches();
      
    } catch (e, stackTrace) {
      debugPrint('TemplateProvider Error: $e\n$stackTrace');
      final handled = classifySupabaseError(e);
      showGlobalSnackBar(handled.userMessage, isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Paginated measurement fetch for future scaling.
  /// Replaces local measurements for the given customerId with limited results.
  Future<void> fetchCustomerMeasurementsPaginated({
    required String customerId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (!await _ensureOnline()) return;
    _isLoading = true;
    notifyListeners();
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final measurementRes = await _supabase
          .from('measurement_records')
          .select()
          .eq('tailor_id', user.id)
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final batch = (measurementRes as List)
          .map((e) => MeasurementRecord.fromJson(e))
          .toList();

      // Replace existing records for this customer with fresh paginated batch
      _measurements.removeWhere((m) => m.customerId == customerId);
      _measurements.insertAll(0, batch);
      _cacheVersion++;
      _invalidateMeasurementCaches();
    } catch (e) {
      debugPrint('Paginated fetch error: $e');
      final handled = classifySupabaseError(e);
      showGlobalSnackBar(handled.userMessage, isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Template Management ---

  List<ProductTemplate> getAllTemplates() => templates;

  List<ProductTemplate> getSystemTemplates() => systemTemplates
      .where((t) => !_archivedTemplateIds.contains(t.id))
      .toList();

  List<ProductTemplate> getCustomTemplates() => myTemplates;

  bool isTemplateArchived(String id) => _archivedTemplateIds.contains(id);

  Future<bool> archiveTemplate(String id) async {
    if (_archivedTemplateIds.contains(id)) return true;
    _archivedTemplateIds.add(id);
    _cacheVersion++;
    notifyListeners();
    return true;
  }

  Future<bool> unarchiveTemplate(String id) async {
    if (!_archivedTemplateIds.remove(id)) return false;
    _cacheVersion++;
    notifyListeners();
    return true;
  }

  Future<ProductTemplate?> addTemplate(ProductTemplate template) async {
    if (!await _ensureOnline()) return null;
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      final finalTemplate = template.copyWith(id: template.id.isEmpty ? const Uuid().v4() : template.id);
      
      final data = finalTemplate.toMap();
      if (user != null) data['tailor_id'] = user.id;

      final response = await _supabase.from('measurement_templates').insert(data).select().single();
      final newT = ProductTemplate.fromMap(response);
      _templates.insert(0, newT);
      _cacheVersion++;
      
      showGlobalSnackBar('Template added successfully.');
      return newT;
    } catch (e) {
      debugPrint('Error adding template: $e');
      final handled = classifySupabaseError(e);
      showGlobalSnackBar(handled.userMessage, isError: true);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProductTemplate?> cloneTemplate(ProductTemplate template, String newName) async {
    final cloned = template.copyWith(
      id: '',
      name: newName,
    );
    return addTemplate(cloned);
  }

  Future<bool> deleteTemplate(String id) async {
    if (!await _ensureOnline()) return false;
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('measurement_templates').delete().eq('id', id);
      _templates.removeWhere((t) => t.id == id);
      _archivedTemplateIds.remove(id);
      _cacheVersion++;
      showGlobalSnackBar('Template deleted.');
      return true;
    } catch (e) {
      debugPrint('Error deleting template: $e');
      showGlobalSnackBar('Delete failed.', isError: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTemplate(ProductTemplate template) async {
    if (!await _ensureOnline()) return false;
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('measurement_templates').update(template.toMap()).eq('id', template.id);
      
      final index = _templates.indexWhere((t) => t.id == template.id);
      if (index != -1) {
        _templates[index] = template;
      }
      _cacheVersion++;
      
      showGlobalSnackBar('Template updated successfully.');
      return true;
    } catch (e) {
      debugPrint('Error updating template: $e');
      showGlobalSnackBar('Failed to update template.', isError: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Customer-Specific Template Caching ---

  String? _lastCustomerId;
  List<ProductTemplate> _cachedExistingTemplates = [];
  List<ProductTemplate> _cachedUnusedTemplates = [];
  int _cacheVersionAtCustomerCache = 0;

  ProductTemplate? getActiveDefaultTemplate(String customerId) {
    final existing = _getOrCacheCustomerTemplates(customerId).existing;
    return existing.isNotEmpty ? existing.first : null;
  }

  ({List<ProductTemplate> existing, List<ProductTemplate> unused}) getTemplatesForCustomer(String customerId) {
    return _getOrCacheCustomerTemplates(customerId);
  }

  ({List<ProductTemplate> existing, List<ProductTemplate> unused}) _getOrCacheCustomerTemplates(String customerId) {
    if (_lastCustomerId == customerId && _cacheVersionAtCustomerCache == _cacheVersion) {
      return (existing: _cachedExistingTemplates, unused: _cachedUnusedTemplates);
    }

    final customerRecordIds = _measurements
        .where((m) => m.customerId == customerId)
        .map((r) => r.templateId)
        .toSet();

    final activeTemplates = templates;
    final existing = activeTemplates.where((t) => customerRecordIds.contains(t.id)).toList();
    final unused = activeTemplates.where((t) => !customerRecordIds.contains(t.id)).toList();

    _lastCustomerId = customerId;
    _cachedExistingTemplates = existing;
    _cachedUnusedTemplates = unused;
    _cacheVersionAtCustomerCache = _cacheVersion;

    return (existing: existing, unused: unused);
  }

  // --- Measurement Operations ---

  List<MeasurementRecord> getCustomerMeasurements(String customerId) {
    return _measurements.where((m) => m.customerId == customerId).toList();
  }

  List<MeasurementRecord> getMeasurementVersions(String customerId, String templateId) {
    final list = _measurements
        .where((m) => m.customerId == customerId && m.templateId == templateId)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  int getMeasurementCountForTemplate(String templateId) {
    if (!_templateCountsValid) _buildTemplateMeasurementCounts();
    return _templateMeasurementCounts[templateId] ?? 0;
  }

  Future<MeasurementRecord?> saveMeasurement(MeasurementRecord record) async {
    if (!await _ensureOnline()) return null;
    
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      final finalRecord = record.copyWith(
        id: record.id.startsWith('temp_') ? const Uuid().v4() : record.id,
        tailorId: user?.id,
      );

      await _supabase.from('measurement_records').upsert(finalRecord.toJson());
      
      final index = _measurements.indexWhere((m) => m.id == record.id);
      if (index != -1) {
        _measurements[index] = finalRecord;
      } else {
        _measurements.insert(0, finalRecord);
      }
      _cacheVersion++;
      _invalidateMeasurementCaches();
      
      showGlobalSnackBar('Measurement saved successfully.');
      return finalRecord;
    } catch (e) {
      debugPrint('Error saving measurement: $e');
      final handled = classifySupabaseError(e);
      showGlobalSnackBar(handled.userMessage, isError: true);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MeasurementRecord?> updateMeasurementInDB(MeasurementRecord record) async {
    return saveMeasurement(record);
  }

  Future<MeasurementRecord?> addMeasurementToDB(MeasurementRecord record) async {
    return saveMeasurement(record);
  }

  MeasurementRecord? getLatestMeasurement(String customerId, String templateId) {
    if (!_latestCacheValid) _buildLatestMeasurementCache();
    return _latestMeasurementCache['$customerId|$templateId'];
  }

  List<ProductTemplate> getMostUsedTemplates() {
    if (!_templateCountsValid) _buildTemplateMeasurementCounts();
    final sorted = List<ProductTemplate>.from(templates);
    sorted.sort((a, b) {
      final countA = _templateMeasurementCounts[a.id] ?? 0;
      final countB = _templateMeasurementCounts[b.id] ?? 0;
      if (countA != countB) return countB.compareTo(countA);
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  MeasurementRecord? getLatestForCustomer(String customerId) {
    final list = _measurements.where((m) => m.customerId == customerId).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => b.date.compareTo(a.date));
    return list.first;
  }

  Map<String, Map<String, double>> compareMeasurementValues(Map<String, double> oldValues, Map<String, double> newValues) {
    final diff = <String, Map<String, double>>{};
    
    final allKeys = {...oldValues.keys, ...newValues.keys};
    
    for (final key in allKeys) {
      final oldVal = oldValues[key] ?? 0.0;
      final newVal = newValues[key] ?? 0.0;
      
      if (oldVal != newVal) {
        diff[key] = {
          'old': oldVal,
          'new': newVal,
          'delta': newVal - oldVal,
        };
      }
    }
    return diff;
  }

  MeasurementRecord? getMeasurementById(String id) {
    try {
      return _measurements.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
}
