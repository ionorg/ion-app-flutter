import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:quiver/strings.dart';

Color string2Color(String colorString) {
  int value = 0x00000000;
  if (isNotEmpty(colorString)) {
    if (colorString[0] == '#') {
      colorString = colorString.substring(1);
    }
    value = int.tryParse(colorString, radix: 16)!;
    if (value < 0xFF000000) {
      value += 0xFF000000;
    }
  }
  return Color(value);
}

void printObject(Object object) {
  // Encode your object and then decode your object to Map variable
  Map jsonMapped = json.decode(json.encode(object));

  // Using JsonEncoder for spacing
  JsonEncoder encoder = new JsonEncoder.withIndent('  ');

  // encode it to string
  String prettyPrint = encoder.convert(jsonMapped);

  // print or debugPrint your object
  debugPrint(prettyPrint);
}
