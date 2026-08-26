import 'package:flutter/material.dart';
import '../models/lds_record.dart';

class RecordDetailScreen extends StatelessWidget {
  final LdsRecord record;

  const RecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${record.location} — ${record.date}')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildRow('Year', record.year.toString()),
          _buildRow('Mean Temperature', '${record.dailyMeanTemp ?? "n/a"} °C'),
          _buildRow('Total Rainfall', '${record.dailyTotalRainfall ?? "n/a"} mm'),
          _buildRow('Mean Pressure', '${record.dailyMeanPressure ?? "n/a"} hPa'),
          _buildRow('Mean Wind Speed', '${record.dailyMeanWindSpeed ?? "n/a"} kn'),
          _buildRow('Wind Speed (Beaufort)', record.windSpeedBeaufort ?? "n/a"),
          _buildRow('Total Sunshine', '${record.dailyTotalSunshine ?? "n/a"} hrs'),
          _buildRow('Max Gust', '${record.dailyMaxGust ?? "n/a"} kn'),
          _buildRow('Max Relative Humidity', '${record.dailyMaxRelativeHumidity ?? "n/a"} %'),
          _buildRow('Cloud Cover', '${record.cloudCoverOktas ?? "n/a"} oktas'),
          _buildRow('Visibility', '${record.visibilityDam ?? "n/a"} dam'),
          _buildRow('Wind Direction', '${record.windDirectionDegrees ?? "n/a"}° (${record.windDirectionCardinal ?? "n/a"})'),
          _buildRow('Gust Direction', '${record.gustDirectionDegrees ?? "n/a"}° (${record.gustDirectionCardinal ?? "n/a"})'),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}