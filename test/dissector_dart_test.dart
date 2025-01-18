import 'package:dissector_dart/dissector_dart.dart';
import 'dart:io';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

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

  test('Test Child Elements', () async {
    // Load the XML file
    final file = File('test/test_data.xml');
    final xmlString = await file.readAsString();

    // Parse the XML
    final document = XmlDocument.parse(xmlString);
    final result =
        Dissector.getChildElementsByTagName(document.rootElement, 'field');
    final result2 =
        Dissector.getChildElementsByTagName(document.rootElement, 'group');
    print(result.length);
    expect(result, isNotNull);
    expect(result.length, 2);
    expect(result2.length, 2);
  });

  test('Get Matching Child Element', () {
    final parent = XmlDocument.parse(
            '<root><child name="test1" value="123" /><child name="test2" value="456" /></root>')
        .rootElement;

    final result =
        Dissector.getMatchingChildElement(parent, 'child', 'name', 'test1');
    expect(result, isNotNull);
    expect(result?.getAttribute('value'), '123');

    final noMatch = Dissector.getMatchingChildElement(
        parent, 'child', 'name', 'nonexistent');
    expect(noMatch, isNull);
  });
}
