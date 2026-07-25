import 'package:json_annotation/json_annotation.dart';

/// `Duration` değerlerini JSON'da milisaniye tam sayısı olarak saklar.
///
/// `json_serializable` `Duration` tipini doğrudan desteklemediği için
/// [GameRulesConfig.turnDuration] gibi alanlarda bu converter kullanılır.
final class DurationJsonConverter implements JsonConverter<Duration, int> {
  const DurationJsonConverter();

  @override
  Duration fromJson(int json) => Duration(milliseconds: json);

  @override
  int toJson(Duration object) => object.inMilliseconds;
}

/// `Duration?` (nullable) alanlar için aynı dönüşümü sağlar.
final class NullableDurationJsonConverter
    implements JsonConverter<Duration?, int?> {
  const NullableDurationJsonConverter();

  @override
  Duration? fromJson(int? json) =>
      json == null ? null : Duration(milliseconds: json);

  @override
  int? toJson(Duration? object) => object?.inMilliseconds;
}
