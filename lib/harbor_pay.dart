library harbor_pay;
import 'package:flutter/material.dart';
import 'package:harbor_pay/hp_io.dart';
export 'src/hp.dart';

void showHPSheet(context) {
  showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) {
        return Container(
            height: 180,
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                )),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: appText(
                        'Choose a payment method.', 15, FontWeight.w600,
                        align: TextAlign.center),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RaisedButton(
                      onPressed: () => showMomoSheet(context),
                      color: Color(0xFF24b4c4),
                      child: appText('Mobile Money', 15, FontWeight.w600,
                          col: Colors.white),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    SizedBox(width: 10),
                    FlatButton(
                      onPressed: () {},
                      color: Color(0xFF24b4c4).withOpacity(0.4),
                      child: appText('Debit Card', 15, FontWeight.w600,
                          col: Colors.white),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    )
                  ],
                ),
                SizedBox(height: 40),
              ],
            ));
      });
}

void showMomoSheet(context) {
  Navigator.pop(context);
  showModalBottomSheet(
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.hardEdge,
      context: context,
      builder: (_) {
        return Container(
            height: 160,
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                )),
            child: ListView(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RaisedButton(
                      onPressed: (){},
                      color: Color(0xFF24b4c4),
                      child: appText('Make Payment', 15, FontWeight.w600,
                          col: Colors.white),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                  ],
                ),
              ],
            ));
      });
}

void showCardSheet(context) {
  Navigator.pop(context);

  showModalBottomSheet(
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.hardEdge,
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (BuildContext context, StateSetter setBState) {
          return AnimatedContainer(
            duration: Duration(microseconds: 500),
            curve: Curves.bounceIn,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                )),
            height: MOMO_SHEET_HEIGHT,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        'assets/hp.png',
                        package: 'harbor_pay',
                        width: 30,
                        height: 30,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: appText('Choose a mobile money platform.', 15,
                        FontWeight.normal,
                        align: TextAlign.center),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RaisedButton(
                      onPressed: () {},
                      color: Color(0xFF24b4c4),
                      child: appText('Make Payment', 15, FontWeight.w600,
                          col: Colors.white),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        });
      });
}
