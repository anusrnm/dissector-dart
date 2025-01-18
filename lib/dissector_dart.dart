import 'dart:io';
import 'package:xml/xml.dart';

class Dissector {
  static const String DSECT = "dsect";
  static const String VERSION = "version";
  static const String COUNTER = "counter";
  static const String STRUC = "struc";
  static const String GROUP = "group";
  static const String LENGTH = "length";
  static const String FILLER = "filler";
  static const String START = "start";
  static const String END = "end";
  static const String PARSD = "parsd";
  static const String TOD = "tod";
  static const String ZTOD = "ztod";
  static const String MINS = "mins";
  static const String HHMM = "hhmm";
  static const double TOD_ADJUST = 1.048576;
  static const int MAX_COUNTER = 500;
  static final DateTime zTODBase = DateTime(1966, 1, 3);
  static final DateTime tODBase = DateTime(1900, 1, 1);
  static final DateTime parsBase = DateTime(1966, 1, 2);

  final XmlDocument doc;
  final String layoutType;
  final String layoutDir;
  final String formatting;
  late StringBuffer res;
  late String inputStr;
  int displ = 0;
  int fillerLen = -1;
  bool trackLen = false;
  int useFieldLen = 0;

  Dissector(File layout, [this.formatting = ""])
      : layoutDir = layout.parent.path,
        doc = XmlDocument.parse(layout.readAsStringSync()),
        layoutType = XmlDocument.parse(layout.readAsStringSync())
                .rootElement
                .getAttribute("type") ??
            "";

  static String getInType(String fieldValue, String fieldType) {
    if (fieldValue.isEmpty) {
      throw ArgumentError("empty input");
    }
    switch (fieldType.toLowerCase()) {
      case PARSD:
        return convertToParsDate(fieldValue);
      case TOD:
        return convertToTOD(fieldValue);
      case ZTOD:
        return convertToZTOD(fieldValue);
      case MINS:
        int mins = int.parse(fieldValue, radix: 16);
        return "${(mins ~/ 60).toString().padLeft(2, '0')}:${(mins % 60).toString().padLeft(2, '0')}";
      case HHMM:
        return convertToHHMM(fieldValue);
      case "b":
        int b = int.parse(fieldValue, radix: 16);
        return b.toRadixString(2).padLeft(8, '0');
      case "d":
        return int.parse(fieldValue, radix: 16).toString();
      case "n":
        int n = int.parse(fieldValue, radix: 16);
        int highNibble = n >> 4;
        int lowNibble = n & 0x0F;
        return "$highNibble,$lowNibble";
      default:
        return fieldValue;
    }
  }

  static String convertToHHMM(String fieldValue) {
    if (fieldValue.length < 4) {
      throw ArgumentError("minimum 4 hex chars are required");
    }
    int hh = int.parse(fieldValue.substring(0, 2), radix: 16);
    int mm = int.parse(fieldValue.substring(2, 4), radix: 16);
    return hh != 0 || mm != 0
        ? "${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}"
        : "";
  }

/// Formats the ztod value in hex string to ISO format
  static String convertToZTOD(String fieldValue) {
    if (fieldValue.length < 8) {
      throw ArgumentError("minimum 8 hex chars are required");
    }
    BigInt ztod = BigInt.parse(fieldValue.substring(0, 8), radix: 16);
    if (ztod == BigInt.zero) return "";
    DateTime baseDate = zTODBase;
    return baseDate.add(Duration(minutes: ztod.toInt())).toIso8601String();
  }

  static String convertToTOD(String fieldValue) {
    if (fieldValue.length < 8) {
      throw ArgumentError("minimum 8 hex chars are required");
    }
    BigInt tod = BigInt.parse(fieldValue.substring(0, 8), radix: 16);
    if (tod == BigInt.zero) return "";

    double actualSeconds = TOD_ADJUST * tod.toDouble();
    // double minutes = (actualSeconds / 60).ceilToDouble();
    double minutes = (actualSeconds / 60);
    double seconds = actualSeconds % 60;
    Duration duration =
        Duration(minutes: minutes.toInt(), seconds: seconds.toInt());
    DateTime baseDate = tODBase.add(duration);
    return baseDate.toIso8601String();
  }

  static String convertToParsDate(String fieldValue) {
    if (fieldValue.length < 4) {
      throw ArgumentError("minimum 4 hex chars are required");
    }
    int parsd = int.parse(fieldValue, radix: 16);
    return parsd != 0
        ? parsBase.add(Duration(days: parsd)).toIso8601String()
        : "";
  }

  String parseWith(String hexString) {
    res = StringBuffer();
    inputStr = hexString;
    parseWithElement(doc.rootElement);
    return res.toString();
  }

  void parseWithElement(XmlElement parent) {
    List<XmlElement> fields = parent.findElements("field").toList();
    if (fields.isEmpty) {
      res.writeln(
          "Warning: No fields found in the layout to parse\n${getFieldValue(-1)}\n");
    }
    for (var field in fields) {
      String fieldName = field.getAttribute("name") ?? "";
      String fieldType = field.getAttribute("type") ?? "";
      String fieldLength = field.getAttribute(LENGTH) ?? "";
      int fieldLengthInt = int.tryParse(fieldLength) ?? 0;
      String fieldValue = getFieldValue(fieldLengthInt);
      res.writeln("$fieldName: $fieldValue");
    }
  }

  String getFieldValue(int fieldLength) {
    if (fieldLength <= 0 || inputStr.length < fieldLength) {
      String value = inputStr;
      inputStr = "";
      return value;
    }
    String value = inputStr.substring(0, fieldLength);
    inputStr = inputStr.substring(fieldLength);
    return value;
  }
}
