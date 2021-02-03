import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

const base = "https://pay.harborstores.com";
const appLightGray = Color(0xFFE7ECF2);
const appGray = Color(0xFFadb4b9);
const appDarkText = Color(0xFF2F2F2F);

const BASE_SHEET_HEIGHT = 160.00;
const MOMO_SHEET_HEIGHT = 180.00;
const MOMO_PAY_METHOD = 'momo';
const CARD_PAY_METHOD = 'card';
const MOMO_MTN = 'MTN';
const MOMO_VODAFONE = 'VOD';
const MOMO_AIRTELTIGO = 'AIR';

String payMethod = CARD_PAY_METHOD;
String selectedMomo = MOMO_MTN;

doPost(String urlAfterBase, Map bod, {Map headers}) async {
  var body = stripNulls(bod);
  var js = await http.post("$base/$urlAfterBase", body: jsonEncode(body), headers: headers);
  var decoded = jsonDecode(js.body);
  return decoded;
}
doGet(String urlAfterBase, {Map headers}) async {
  var js = await http.get('$base/$urlAfterBase', headers: headers);
  var decoded;
  try {
    decoded = jsonDecode(js.body);
  } catch(e) {
    print(e);
  }
  return decoded;
}
Map stripNulls(Map m) {
  Map finMap = {};
  for (var i in m.keys) {
    if (m[i] is String) {
      if (m[i] != '') {
        finMap[i] = m[i];
      }
    } else if (m[i] == null) {

    } else if (m[i] is double) {
      finMap[i] = m[i].toString();
    } else {
      finMap[i] = jsonEncode(m[i]);
    }
  }
  return finMap;
}

appText(String word, double z, FontWeight w, {Color col = appDarkText, TextAlign align = TextAlign.left, int maxLines = 5, int shadow = 0}) {
  return Text(
    word,
    softWrap: true,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    textAlign: align,
    style: TextStyle(
      color: col,
      fontFamily: 'Open Sans',
      fontSize: z,
      fontWeight: w,
      shadows: shadow > 0 ? elevation(Colors.black38, shadow) : [],
    ),
  );
}

List<BoxShadow> elevation(Color col, int elevation) {
  return [
    BoxShadow(color: col.withOpacity(0.6), offset: Offset(0.0, 4.0), blurRadius: 3.0 * elevation, spreadRadius: -1.0 * elevation),
    BoxShadow(color: col.withOpacity(0.44), offset: Offset(0.0, 1.0), blurRadius: 2.2 * elevation, spreadRadius: 1.5),
    BoxShadow(color: col.withOpacity(0.12), offset: Offset(0.0, 1.0), blurRadius: 4.6 * elevation, spreadRadius: 0.0),
  ];
}
Widget progress({double size = 30}) {
  return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(backgroundColor: appLightGray,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9c9c9c)))
  );
}

appWidth(con) {
  return MediaQuery.of(con).size.width;
}

EdgeInsets verticalPadding(double size) {
  return EdgeInsets.symmetric(vertical: size);
}