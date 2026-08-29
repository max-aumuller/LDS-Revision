import 'dart:io';

import 'package:excel_plus/excel_plus.dart';

import '../models/lds_record.dart';

/// Thrown when a file can't be read as an .xlsx Large Data Set workbook at all
/// (as opposed to individual rows/columns being messy, which is reported via
/// [LdsImportResult.warnings] instead).
class LdsImportException implements Exception {
  final String message;
  LdsImportException(this.message);

  @override
  String toString() => message;
}

class LdsImportResult {
  final List<LdsRecord> records;
  final int rowsImported;
  final int locationsFound;
  final List<String> warnings;

  const LdsImportResult({
    required this.records,
    required this.rowsImported,
    required this.locationsFound,
    required this.warnings,
  });
}

/// Column indices discovered on one sheet's header row, keyed by field.
class _ColumnMap {
  int? date;
  int? meanTemp;
  int? rainfall;
  int? sunshine;
  int? windSpeed;
  int? windSpeedBeaufort;
  int? gust;
  int? humidity;
  int? cloud;
  int? visibility;
  int? pressure;
  List<int> windDirection = [];
  List<int> gustDirection = [];
}

/// Parses a Pearson Edexcel Large Data Set .xlsx workbook (one sheet per
/// location) into [LdsRecord]s, matching columns by keyword rather than
/// fixed position so it tolerates minor header wording changes between
/// dataset releases.
class LdsImportService {
  /// The dataset's real sheet names aren't just the location (e.g.
  /// "Camborne May-Oct 1987"), so this is used to pull the canonical
  /// location out rather than storing the whole sheet name verbatim.
  static const List<String> _knownLocations = [
    'Camborne',
    'Heathrow',
    'Hurn',
    'Leeming',
    'Leuchars',
    'Beijing',
    'Jacksonville',
    'Perth',
  ];

  /// How many leading rows to scan for the header row before giving up —
  /// real dataset sheets carry several rows of station metadata (name,
  /// copyright, grid reference, altitude, lat/long) above the actual
  /// column headers.
  static const int _maxHeaderSearchRows = 20;

  Future<LdsImportResult> importFromFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return importFromBytes(bytes);
  }

  LdsImportResult importFromBytes(List<int> bytes) {
    final Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (e) {
      throw LdsImportException(
        'Could not read this file as an Excel workbook. Make sure you selected the Large Data Set (.xls or .xlsx) file downloaded from Pearson.',
      );
    }

    final records = <LdsRecord>[];
    final warnings = <String>[];
    var locationsFound = 0;
    var nextId = 1;

    for (final sheetName in excel.sheets.keys) {
      final sheet = excel.sheets[sheetName]!;
      final rows = sheet.rows;
      if (rows.isEmpty) continue;

      var headerRowIndex = -1;
      var columnMap = _ColumnMap();
      for (var r = 0; r < rows.length && r < _maxHeaderSearchRows; r++) {
        final candidateHeaders = _readHeaders(rows[r]);
        final candidateMap = _mapColumns(candidateHeaders);
        if (_looksLikeHeaderRow(candidateHeaders, candidateMap)) {
          headerRowIndex = r;
          columnMap = candidateMap;
          break;
        }
      }

      if (headerRowIndex == -1) {
        warnings.add('Sheet "$sheetName" was skipped: no date column found.');
        continue;
      }

      final location = _resolveLocation(sheetName);
      _warnMissingColumns(columnMap, sheetName, warnings);

      locationsFound++;
      var skippedRows = 0;

      for (var r = headerRowIndex + 1; r < rows.length; r++) {
        final row = rows[r];
        if (_isRowBlank(row)) continue;

        try {
          final dateStr = _parseDateFromCellValue(_cellValueAt(row, columnMap.date));
          if (dateStr == null) {
            skippedRows++;
            continue;
          }

          final windDirection = _mergedDirection(row, columnMap.windDirection);
          final gustDirection = _mergedDirection(row, columnMap.gustDirection);

          records.add(LdsRecord(
            id: nextId++,
            location: location,
            year: int.parse(dateStr.substring(0, 4)),
            date: dateStr,
            dailyMeanTemp: _asDouble(_cellValueAt(row, columnMap.meanTemp)),
            dailyTotalRainfall: _asDouble(_cellValueAt(row, columnMap.rainfall)),
            dailyMeanPressure: _asDouble(_cellValueAt(row, columnMap.pressure)),
            dailyMeanWindSpeed: _asDouble(_cellValueAt(row, columnMap.windSpeed)),
            windSpeedBeaufort: _asString(_cellValueAt(row, columnMap.windSpeedBeaufort)),
            dailyTotalSunshine: _asDouble(_cellValueAt(row, columnMap.sunshine)),
            dailyMaxGust: _asDouble(_cellValueAt(row, columnMap.gust)),
            dailyMaxRelativeHumidity: _asDouble(_cellValueAt(row, columnMap.humidity)),
            cloudCoverOktas: _asInt(_cellValueAt(row, columnMap.cloud)),
            visibilityDam: _asDouble(_cellValueAt(row, columnMap.visibility)),
            windDirectionDegrees: windDirection.$1,
            windDirectionCardinal: windDirection.$2,
            gustDirectionDegrees: gustDirection.$1,
            gustDirectionCardinal: gustDirection.$2,
          ));
        } catch (_) {
          skippedRows++;
        }
      }

      if (skippedRows > 0) {
        warnings.add('Sheet "$sheetName": skipped $skippedRows row(s) with an unparseable or missing date.');
      }
    }

    return LdsImportResult(
      records: records,
      rowsImported: records.length,
      locationsFound: locationsFound,
      warnings: warnings,
    );
  }

  // --- Header parsing -------------------------------------------------

  /// The real workbook's sheet names combine the location with a date range
  /// (e.g. "Camborne May-Oct 1987"), so pull out whichever known location
  /// name appears in it. Falls back to the raw sheet name if none match, so
  /// a simpler-named sheet (just "Camborne") still works.
  String _resolveLocation(String sheetName) {
    final lower = sheetName.toLowerCase();
    for (final location in _knownLocations) {
      if (lower.contains(location.toLowerCase())) return location;
    }
    return sheetName.trim();
  }

  /// Guards the header search against prose that happens to contain the
  /// word "date" (e.g. a cover sheet's "...on the date given..."). A real
  /// header cell is a short label like "Date"; a narrative paragraph cell
  /// runs to hundreds of characters.
  bool _looksLikeHeaderRow(List<String> headers, _ColumnMap map) {
    if (map.date == null) return false;
    return headers[map.date!].length <= 20;
  }

  List<String> _readHeaders(List<Data?> headerRow) {
    return headerRow.map((cell) {
      final value = cell?.value;
      if (value == null) return '';
      return value.toString().toLowerCase().trim();
    }).toList();
  }

  _ColumnMap _mapColumns(List<String> headers) {
    final map = _ColumnMap();
    final claimed = <int>{};

    int? findFirst(bool Function(String) test) {
      for (var i = 0; i < headers.length; i++) {
        if (claimed.contains(i)) continue;
        if (test(headers[i])) {
          claimed.add(i);
          return i;
        }
      }
      return null;
    }

    List<int> findAll(bool Function(String) test) {
      final result = <int>[];
      for (var i = 0; i < headers.length; i++) {
        if (claimed.contains(i)) continue;
        if (test(headers[i])) {
          claimed.add(i);
          result.add(i);
        }
      }
      return result;
    }

    // Ordered from most specific to least specific keyword, so a header
    // like "Wind Speed (Beaufort)" is claimed by the Beaufort field before
    // the generic "wind speed" rule gets a chance at it.
    map.date = findFirst((h) => h.contains('date'));
    map.windSpeedBeaufort = findFirst((h) => h.contains('beaufort'));
    map.gustDirection = findAll((h) => h.contains('gust') && h.contains('dir'));
    _claimAdjacentCardinal(map.gustDirection, headers, claimed);
    map.gust = findFirst((h) => h.contains('gust'));
    map.windDirection = findAll((h) => h.contains('wind') && h.contains('dir'));
    _claimAdjacentCardinal(map.windDirection, headers, claimed);
    map.windSpeed = findFirst((h) => h.contains('wind speed') || h.contains('windspeed'));
    map.meanTemp = findFirst((h) => h.contains('temp'));
    map.rainfall = findFirst((h) => h.contains('rainfall') || h.contains('rain'));
    map.sunshine = findFirst((h) => h.contains('sunshine') || h.contains('sun'));
    map.pressure = findFirst((h) => h.contains('pressure'));
    map.humidity = findFirst((h) => h.contains('humidity'));
    map.cloud = findFirst((h) => h.contains('cloud'));
    map.visibility = findFirst((h) => h.contains('visib'));

    return map;
  }

  /// The dataset sometimes splits a direction into two adjacent columns —
  /// a numeric bearing header (matched above) immediately next to a bare
  /// "Cardinal Direction" column that carries no "wind"/"gust" keyword of
  /// its own. Pull in a neighbour like that so it's not left unclaimed.
  void _claimAdjacentCardinal(List<int> group, List<String> headers, Set<int> claimed) {
    final additions = <int>[];
    for (final index in group) {
      for (final neighbor in [index + 1, index - 1]) {
        if (neighbor >= 0 &&
            neighbor < headers.length &&
            !claimed.contains(neighbor) &&
            headers[neighbor].contains('cardinal')) {
          claimed.add(neighbor);
          additions.add(neighbor);
          break;
        }
      }
    }
    group.addAll(additions);
  }

  void _warnMissingColumns(_ColumnMap map, String sheetName, List<String> warnings) {
    final checks = <String, bool>{
      'temperature': map.meanTemp != null,
      'rainfall': map.rainfall != null,
      'sunshine': map.sunshine != null,
      'wind speed': map.windSpeed != null,
      'pressure': map.pressure != null,
      'gust': map.gust != null,
      'humidity': map.humidity != null,
      'cloud cover': map.cloud != null,
      'visibility': map.visibility != null,
      'wind direction': map.windDirection.isNotEmpty,
    };
    for (final entry in checks.entries) {
      if (!entry.value) {
        warnings.add('Sheet "$sheetName": couldn\'t find a ${entry.key} column.');
      }
    }
  }

  // --- Row/cell helpers -------------------------------------------------

  bool _isRowBlank(List<Data?> row) {
    for (final cell in row) {
      final value = cell?.value;
      if (value == null) continue;
      if (value.toString().trim().isNotEmpty) return false;
    }
    return true;
  }

  CellValue? _cellValueAt(List<Data?> row, int? columnIndex) {
    if (columnIndex == null || columnIndex >= row.length) return null;
    return row[columnIndex]?.value;
  }

  /// A direction can be spread across more than one matched column (e.g. a
  /// numeric bearing in one and a compass letter in another, depending on
  /// dataset release) — merge whatever each column actually contains rather
  /// than only looking at the first match.
  (int?, String?) _mergedDirection(List<Data?> row, List<int> columnIndices) {
    int? degrees;
    String? cardinal;
    for (final index in columnIndices) {
      final split = _splitDirection(_cellValueAt(row, index));
      degrees ??= split.$1;
      cardinal ??= split.$2;
    }
    return (degrees, cardinal);
  }

  double? _asDouble(CellValue? value) {
    if (value == null) return null;
    if (value is IntCellValue) return value.value.toDouble();
    if (value is DoubleCellValue) return value.value;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  int? _asInt(CellValue? value) => _asDouble(value)?.round();

  String? _asString(CellValue? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// Splits a wind/gust direction cell into (degrees, cardinal) — the real
  /// dataset has used both a numeric bearing and a compass letter across
  /// different releases, sometimes even in separate columns, so we detect
  /// which one each cell actually holds rather than assuming.
  (int?, String?) _splitDirection(CellValue? value) {
    if (value == null) return (null, null);
    if (value is IntCellValue) return (value.value, null);
    if (value is DoubleCellValue) return (value.value.round(), null);
    final text = value.toString().trim();
    if (text.isEmpty) return (null, null);
    final asNumber = double.tryParse(text);
    if (asNumber != null) return (asNumber.round(), null);
    return (null, text.toUpperCase());
  }

  String? _parseDateFromCellValue(CellValue? value) {
    if (value == null) return null;
    if (value is DateCellValue) {
      return _formatDate(DateTime(value.year, value.month, value.day));
    }
    if (value is DateTimeCellValue) {
      return _formatDate(DateTime(value.year, value.month, value.day));
    }
    if (value is IntCellValue) {
      return _formatDate(_excelSerialToDate(value.value.toDouble()));
    }
    if (value is DoubleCellValue) {
      return _formatDate(_excelSerialToDate(value.value));
    }
    if (value is TextCellValue) {
      return _parseDateString(value.value.toString().trim());
    }
    return null;
  }

  String? _parseDateString(String raw) {
    if (raw.isEmpty) return null;

    // Already ISO (yyyy-mm-dd or yyyy/mm/dd).
    final iso = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})');
    final isoMatch = iso.firstMatch(raw);
    if (isoMatch != null) {
      final year = int.parse(isoMatch.group(1)!);
      final month = int.parse(isoMatch.group(2)!);
      final day = int.parse(isoMatch.group(3)!);
      if (_isValidDate(year, month, day)) return _formatDate(DateTime(year, month, day));
    }

    // UK day/month/year, slash or dash separated.
    final dmy = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$');
    final dmyMatch = dmy.firstMatch(raw);
    if (dmyMatch != null) {
      final day = int.parse(dmyMatch.group(1)!);
      final month = int.parse(dmyMatch.group(2)!);
      var year = int.parse(dmyMatch.group(3)!);
      if (year < 100) year += year < 50 ? 2000 : 1900;
      if (_isValidDate(year, month, day)) return _formatDate(DateTime(year, month, day));
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return _formatDate(parsed);

    return null;
  }

  bool _isValidDate(int year, int month, int day) {
    return month >= 1 && month <= 12 && day >= 1 && day <= 31 && year > 1900 && year < 2200;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Excel stores dates as a serial day count from 1899-12-30 (the classic
  /// Lotus 1-2-3 leap-year-bug epoch every spreadsheet app still honours).
  DateTime _excelSerialToDate(double serial) {
    return DateTime(1899, 12, 30).add(Duration(days: serial.round()));
  }
}
