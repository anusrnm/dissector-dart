import 'package:dissector_dart/dissector_dart.dart';
import 'package:test/test.dart';

void main() {
  final DateTime zTODBase = DateTime(1966, 1, 3);
  String zTODBaseIso = zTODBase.toIso8601String();
  
  final DateTime todBase = DateTime(2017, 2, 9, 7, 22, 53);
  String todBaseIso = todBase.toIso8601String();
  
  final DateTime parsBase = DateTime(2019, 10, 20);
  String parsBaseIso = parsBase.toIso8601String();

  print(zTODBaseIso);
  test('Convert to ZTOD', () {
    expect(Dissector.convertToZTOD('0000FFFF'),
        zTODBase.add(Duration(minutes: 65535)).toIso8601String());
    expect(() => Dissector.convertToZTOD('00FF'), throwsArgumentError);
  });

  test('Convert to TOD', () {
    expect(Dissector.convertToTOD('0000FFFF'), isNotEmpty);
    expect(Dissector.convertToTOD('D2124223FECD1335'), todBaseIso);
    expect(() => Dissector.convertToTOD('00FF'), throwsArgumentError);
  });

  test('Convert to ParsDate', () {
    expect(Dissector.convertToParsDate('4CC1'), parsBaseIso);
    expect(() => Dissector.convertToParsDate('00'), throwsArgumentError);
  });

  test('Get In Type', () {
    expect(Dissector.getInType('0A1E', Dissector.HHMM), '10:30');
    expect(Dissector.getInType('4CC1', Dissector.PARSD), parsBaseIso);
    expect(() => Dissector.getInType('', Dissector.HHMM), throwsArgumentError);
  });
}
