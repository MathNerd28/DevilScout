import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum(valueField: 'value')
enum FrcMatchLevel {
  qualification('qm'),
  elimination('em'),
  quarterfinals('qf'),
  semifinals('sf'),
  finals('f');

  final String value;

  const FrcMatchLevel(this.value);

  @override
  String toString() => value;
}

@JsonEnum()
enum FrcAlliance {
  blue,
  red;

  @override
  String toString() => name;
}
