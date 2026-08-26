class LdsRecord {
  final int id;
  final String location;
  final int year;
  final String date;
  final double? dailyMeanTemp;
  final double? dailyTotalRainfall;
  final double? dailyMeanPressure;
  final double? dailyMeanWindSpeed;
  final String? windSpeedBeaufort;
  final double? dailyTotalSunshine;
  final double? dailyMaxGust;
  final double? dailyMaxRelativeHumidity;
  final int? cloudCoverOktas;
  final double? visibilityDam;
  final int? windDirectionDegrees;
  final String? windDirectionCardinal;
  final int? gustDirectionDegrees;
  final String? gustDirectionCardinal;

  LdsRecord({
    required this.id,
    required this.location,
    required this.year,
    required this.date,
    this.dailyMeanTemp,
    this.dailyTotalRainfall,
    this.dailyMeanPressure,
    this.dailyMeanWindSpeed,
    this.windSpeedBeaufort,
    this.dailyTotalSunshine,
    this.dailyMaxGust,
    this.dailyMaxRelativeHumidity,
    this.cloudCoverOktas,
    this.visibilityDam,
    this.windDirectionDegrees,
    this.windDirectionCardinal,
    this.gustDirectionDegrees,
    this.gustDirectionCardinal,
  });

  factory LdsRecord.fromJson(Map<String, dynamic> json) {
    return LdsRecord(
      id: json['id'],
      location: json['location'],
      year: json['year'],
      date: json['date'],
      dailyMeanTemp: json['dailyMeanTemp']?.toDouble(),
      dailyTotalRainfall: json['dailyTotalRainfall']?.toDouble(),
      dailyMeanPressure: json['dailyMeanPressure']?.toDouble(),
      dailyMeanWindSpeed: json['dailyMeanWindSpeed']?.toDouble(),
      windSpeedBeaufort: json['windSpeedBeaufort'],
      dailyTotalSunshine: json['dailyTotalSunshine']?.toDouble(),
      dailyMaxGust: json['dailyMaxGust']?.toDouble(),
      dailyMaxRelativeHumidity: json['dailyMaxRelativeHumidity']?.toDouble(),
      cloudCoverOktas: json['cloudCoverOktas'],
      visibilityDam: json['visibilityDam']?.toDouble(),
      windDirectionDegrees: json['windDirectionDegrees'],
      windDirectionCardinal: json['windDirectionCardinal'],
      gustDirectionDegrees: json['gustDirectionDegrees'],
      gustDirectionCardinal: json['gustDirectionCardinal'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'location': location,
      'year': year,
      'date': date,
      'dailyMeanTemp': dailyMeanTemp,
      'dailyTotalRainfall': dailyTotalRainfall,
      'dailyMeanPressure': dailyMeanPressure,
      'dailyMeanWindSpeed': dailyMeanWindSpeed,
      'windSpeedBeaufort': windSpeedBeaufort,
      'dailyTotalSunshine': dailyTotalSunshine,
      'dailyMaxGust': dailyMaxGust,
      'dailyMaxRelativeHumidity': dailyMaxRelativeHumidity,
      'cloudCoverOktas': cloudCoverOktas,
      'visibilityDam': visibilityDam,
      'windDirectionDegrees': windDirectionDegrees,
      'windDirectionCardinal': windDirectionCardinal,
      'gustDirectionDegrees': gustDirectionDegrees,
      'gustDirectionCardinal': gustDirectionCardinal,
    };
  }
}