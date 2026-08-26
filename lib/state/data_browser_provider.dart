import 'package:flutter/foundation.dart';
import '../models/lds_record.dart';
import '../services/query_service.dart';

class DataBrowserProvider extends ChangeNotifier {
  final QueryService _queryService = QueryService();

  List<LdsRecord> _records = [];
  String _sortField = 'date';
  bool _ascending = true;
  bool _isLoading = false;
  String? _selectedLocation;
  String? _rangeField;
  double? _rangeMin;
  double? _rangeMax;

  List<LdsRecord> get records => _records;
  String get sortField => _sortField;
  bool get ascending => _ascending;
  bool get isLoading => _isLoading;
  String? get selectedLocation => _selectedLocation;
  String? get rangeField => _rangeField;
  double? get rangeMin => _rangeMin;
  double? get rangeMax => _rangeMax;

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    _records = await _queryService.getFilteredSortedRecords(
      location: _selectedLocation,
      rangeField: _rangeField,
      rangeMin: _rangeMin,
      rangeMax: _rangeMax,
      sortField: _sortField,
      ascending: _ascending,
    );

    _isLoading = false;
    notifyListeners();
  }

  void sortBy(String field) {
    if (_sortField == field) {
      _ascending = !_ascending;
    } else {
      _sortField = field;
      _ascending = true;
    }
    loadRecords();
  }

  Future<void> filterByLocation(String? location) async {
    _selectedLocation = location;
    await loadRecords();
  }

  Future<void> filterByRange(String? field, double? min, double? max) async {
    _rangeField = field;
    _rangeMin = min;
    _rangeMax = max;
    await loadRecords();
  }
}