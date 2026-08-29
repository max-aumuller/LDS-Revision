import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app_large_data_set/services/lds_import_service.dart';

Excel _buildWorkbook(Map<String, List<List<Object?>>> sheetsData) {
  final excel = Excel.createExcel();
  final defaultSheetName = excel.sheets.keys.first;

  for (final entry in sheetsData.entries) {
    final sheet = excel[entry.key];
    for (var r = 0; r < entry.value.length; r++) {
      final row = entry.value[r];
      for (var c = 0; c < row.length; c++) {
        final raw = row[c];
        CellValue? value;
        if (raw == null) {
          value = null;
        } else if (raw is String) {
          value = TextCellValue(raw);
        } else if (raw is int) {
          value = IntCellValue(raw);
        } else if (raw is double) {
          value = DoubleCellValue(raw);
        } else if (raw is DateTime) {
          value = DateCellValue(year: raw.year, month: raw.month, day: raw.day);
        }
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
          value,
        );
      }
    }
  }

  excel.delete(defaultSheetName);
  return excel;
}

List<int> _encode(Excel excel) {
  final bytes = excel.encode();
  expect(bytes, isNotNull);
  return bytes!;
}

void main() {
  final service = LdsImportService();

  test('imports rows with keyword-matched, case/spacing-tolerant headers', () {
    final excel = _buildWorkbook({
      'Camborne': [
        [
          'Date',
          'Daily Mean Temperature (C)',
          'Daily Total Rainfall (mm)',
          'Daily Total Sunshine (hrs)',
          'Daily Mean Windspeed (knots)',
          'Wind Speed (Beaufort)',
          'Daily Mean Wind Direction (compass)',
          'Daily Max Gust (knots)',
          'Daily Max Relative Humidity (%)',
          'Cloud Cover (Oktas)',
          'Visibility (dam)',
          'Daily Mean Pressure (hPa)',
        ],
        [
          '1987-05-01',
          10.7,
          3.1,
          null, // blank sunshine — should become null, not skip the row
          null,
          '3',
          'NNE',
          null,
          100.0,
          7,
          2000.0,
          1018.4,
        ],
        [
          '1987-05-02',
          8.85,
          0.1,
          5.2,
          12.0,
          '4',
          90,
          33.0,
          95.0,
          5,
          1500.0,
          1015.0,
        ],
      ],
    });

    final result = service.importFromBytes(_encode(excel));

    expect(result.rowsImported, 2);
    expect(result.locationsFound, 1);
    expect(result.records[0].location, 'Camborne');
    expect(result.records[0].date, '1987-05-01');
    expect(result.records[0].year, 1987);
    expect(result.records[0].dailyMeanTemp, 10.7);
    expect(result.records[0].dailyTotalSunshine, isNull);
    expect(result.records[0].windSpeedBeaufort, '3');
    expect(result.records[0].windDirectionCardinal, 'NNE');
    expect(result.records[0].windDirectionDegrees, isNull);
    expect(result.records[0].cloudCoverOktas, 7);

    // Second row: direction given as a numeric bearing instead of compass.
    expect(result.records[1].windDirectionDegrees, 90);
    expect(result.records[1].windDirectionCardinal, isNull);
    expect(result.records[1].dailyMaxGust, 33.0);

    expect(result.warnings, isEmpty);
  });

  test('combines multiple sheets, using the sheet name as location', () {
    final excel = _buildWorkbook({
      'Heathrow': [
        ['Date', 'Temp'],
        ['2020-01-01', 5.0],
      ],
      'Jacksonville': [
        ['Date', 'Temp'],
        ['2020-01-01', 22.0],
        ['2020-01-02', 23.0],
      ],
    });

    final result = service.importFromBytes(_encode(excel));

    expect(result.rowsImported, 3);
    expect(result.locationsFound, 2);
    expect(result.records.map((r) => r.location).toSet(), {'Heathrow', 'Jacksonville'});
    // ids assigned sequentially across all sheets combined.
    expect(result.records.map((r) => r.id).toList(), [1, 2, 3]);
  });

  test('warns about missing columns instead of failing', () {
    final excel = _buildWorkbook({
      'Perth': [
        ['Date', 'Temp'],
        ['2020-06-01', 15.0],
      ],
    });

    final result = service.importFromBytes(_encode(excel));

    expect(result.rowsImported, 1);
    expect(result.warnings, isNotEmpty);
    expect(result.warnings.any((w) => w.contains('Perth') && w.contains('wind speed')), isTrue);
    expect(result.warnings.any((w) => w.contains('humidity')), isTrue);
  });

  test('skips rows with an unparseable date but keeps the rest', () {
    final excel = _buildWorkbook({
      'Leuchars': [
        ['Date', 'Temp'],
        ['2020-06-01', 15.0],
        ['not a date', 16.0],
        [null, 17.0],
        ['2020-06-03', 18.0],
      ],
    });

    final result = service.importFromBytes(_encode(excel));

    expect(result.rowsImported, 2);
    expect(result.records.map((r) => r.date).toList(), ['2020-06-01', '2020-06-03']);
    expect(result.warnings.any((w) => w.contains('Leuchars') && w.contains('skipped 2')), isTrue);
  });

  test('parses UK-style dd/mm/yyyy text dates', () {
    final excel = _buildWorkbook({
      'Leeming': [
        ['Date', 'Temp'],
        ['25/12/2019', 2.0],
      ],
    });

    final result = service.importFromBytes(_encode(excel));

    expect(result.records.single.date, '2019-12-25');
  });

  test('parses genuine DateCellValue cells', () {
    final excel = _buildWorkbook({
      'Beijing': [
        ['Date', 'Temp'],
        [DateTime(2018, 3, 4), 9.0],
      ],
    });

    final result = service.importFromBytes(_encode(excel));

    expect(result.records.single.date, '2018-03-04');
    expect(result.records.single.year, 2018);
  });

  test('a sheet with no date column is skipped with a warning and does not throw', () {
    final excel = _buildWorkbook({
      'Notes': [
        ['Some', 'Cover', 'Sheet'],
        ['not', 'weather', 'data'],
      ],
    });

    final result = service.importFromBytes(_encode(excel));

    expect(result.rowsImported, 0);
    expect(result.locationsFound, 0);
    expect(result.warnings.any((w) => w.contains('Notes') && w.contains('no date column')), isTrue);
  });

  test('finds the header row past leading station-metadata rows, and resolves location from a compound sheet name', () {
    final excel = _buildWorkbook({
      'Camborne May-Oct 1987': [
        ['CAMBORNE                     © Crown Copyright Met Office 2015'],
        ['NGR = 1627E 4067N'],
        ['Altitude = 87 metres'],
        ['Latitude = 50:22N Longitude = 05:33W'],
        [],
        ['Date', 'Daily Mean Temperature (0900-0900) (°C)'],
        ['1987-05-01', 10.7],
        ['1987-05-02', 8.85],
      ],
    });

    final result = service.importFromBytes(_encode(excel));

    expect(result.rowsImported, 2);
    expect(result.records.every((r) => r.location == 'Camborne'), isTrue);
    expect(result.records[0].date, '1987-05-01');
    expect(result.records[0].dailyMeanTemp, 10.7);
  });

  test('claims a bare "Cardinal Direction" column adjacent to its numeric bearing column', () {
    final excel = _buildWorkbook({
      'Heathrow May-Oct 2015': [
        [
          'Date',
          'Daily Mean Wind Direction (o)',
          'Cardinal Direction',
          'Daily Max Gust Corresponding Direction (o)',
          'Cardinal Direction',
        ],
        ['2015-05-01', 270, 'W', 280, 'WNW'],
      ],
    });

    final result = service.importFromBytes(_encode(excel));

    final record = result.records.single;
    expect(record.windDirectionDegrees, 270);
    expect(record.windDirectionCardinal, 'W');
    expect(record.gustDirectionDegrees, 280);
    expect(record.gustDirectionCardinal, 'WNW');
  });

  test('throws LdsImportException for a non-Excel file', () {
    expect(
      () => service.importFromBytes([1, 2, 3, 4, 5]),
      throwsA(isA<LdsImportException>()),
    );
  });
}
