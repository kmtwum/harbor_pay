import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:harbor_pay/hp_io.dart';

class HPay {
  HPay(
      {required this.clientKey,
      this.transactionType = '',
      this.customerNumber = '',
      this.buttonColors = const Color(0xFF24b4c4),
      this.bottomSheetBackgroundColor = const Color(0xff787878)});


  String clientKey;
  double amount = 0;
  String transactionType; //momo or card
  String transactionPlatform = 'MTN'; //AIR, MTN or VOD;
  String customerNumber;
  Color buttonColors;
  Color bottomSheetBackgroundColor;

  initialize(HPay options) {
    this.clientKey = options.clientKey;
    this.amount = options.amount;
  }

  appendToInitializer(options) {
    if (options.transactionType != null)
      this.transactionType = options.transactionType;
    if (options.transactionPlatform != null)
      this.transactionPlatform = options.transactionPlatform;
    if (options.customerNumber != null)
      this.customerNumber = options.customerNumber;
    if (options.amount) this.amount = options.amount;
  }

  prepareTransaction(context, {Map extra: const {}}) async {
    if (this.amount <= 0) {
      return {
        'success': false,
        'message': 'amount should be more than zero',
      };
    }

    var finalLoad = {
      "client": this.clientKey,
      "transaction_type": MOMO_PAY_METHOD,
      "customer_number": this.customerNumber,
      "amount": this.amount
    };

    if (selectedMomo != '') {
      this.transactionPlatform = selectedMomo;
      finalLoad['transaction_platform'] = this.transactionPlatform;
    }

    if (extra.length > 0) finalLoad['meta'] = extra;

    var x = await doPost('pay', finalLoad, headers: headers());

    if (this.transactionType == 'paypal') return x;

    if (x['success']) {
      var responseMap = await queryTransStatus(extra['order_id']);
      Navigator.pop(context, responseMap);
    } else {
      Navigator.pop(context, x);
    }
  }

  Future<Map<String, dynamic>> queryTransStatus(transId) async {
    for (int i = 0; i < 5; i++) {
      await Future.delayed(Duration(seconds: 6));
      var dec = await doGet('pay/status', queries: {'id': transId}, headers: headers());
      if (dec['transactionStatus'] == '1') {
        return {'success': true, 'message': 'Payment Received. Thank you'};
      } else if (dec['transactionStatus'] == 'Failed') {
        return {
          'success': false,
          'message': 'Payment Failed. User did not confirm'
        };
      }
    }
    return {'success': false, 'message': 'Payment Failed. Timed out'};
  }

  paymentCaptured(BuildContext context) {
    if (this.transactionType == 'paypal') {
      Future.delayed(Duration(seconds: 7), () {
        Navigator.pop(
            context, {'success': true, 'transactionStatus': 'Completed'});
      });
    }
  }

  Future processPayment(
      {required BuildContext context,
      required double amount,
      required String customerNumber,
      Map extra = const {}}) async {
    if (amount != 0) this.amount = amount;
    if (customerNumber != '') this.customerNumber = customerNumber;

    int currentStep = 0;
    double height = 340;

    return await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) =>
                  Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: this.bottomSheetBackgroundColor,
                      ),
                      child: Stepper(
                        elevation: 0,
                        currentStep: currentStep,
                        type: StepperType.horizontal,
                        onStepContinue: () {
                          setState(() => currentStep = currentStep + 1);
                        },
                        onStepCancel: () {
                          setState(() => currentStep = currentStep - 1);
                        },
                        steps: [
                          Step(
                            isActive: currentStep == 0,
                            title: Text('Provider'),
                            content: Container(
                              height: 300,
                              child: ListView(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      appText('Payment for:', 12,
                                          FontWeight.normal),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: appText(
                                            'GHS${this.amount.toString()}',
                                            30,
                                            FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      appText('Select mobile money platform:',
                                          12, FontWeight.normal),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        margin: verticalPadding(10),
                                        width: appWidth(context) * 0.6,
                                        decoration: BoxDecoration(
                                          color: appLightGray.withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(40),
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: DropdownButton(
                                              isExpanded: true,
                                              underline: Container(),
                                              items: [
                                                DropdownMenuItem(
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 15,
                                                        backgroundImage: AssetImage(
                                                            'assets/airteltigo.jpg',
                                                            package:
                                                                'harbor_pay'),
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      appText('AirtelTigo', 15,
                                                          FontWeight.w600),
                                                    ],
                                                  ),
                                                  value: 'AIR',
                                                ),
                                                DropdownMenuItem(
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 15,
                                                        backgroundImage:
                                                            AssetImage(
                                                                'assets/mtn.png',
                                                                package:
                                                                    'harbor_pay'),
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      appText('MTN', 15,
                                                          FontWeight.w600),
                                                    ],
                                                  ),
                                                  value: 'MTN',
                                                ),
                                                DropdownMenuItem(
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 15,
                                                        backgroundImage: AssetImage(
                                                            'assets/vodafone.jpg',
                                                            package:
                                                                'harbor_pay'),
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      appText('Vodafone', 15,
                                                          FontWeight.w600),
                                                    ],
                                                  ),
                                                  value: 'VOD',
                                                )
                                              ],
                                              value: selectedMomo,
                                              onChanged: (val) {
                                                setState(() {
                                                  this.transactionType =
                                                      MOMO_PAY_METHOD;
                                                  this.transactionPlatform =
                                                      val.toString();
                                                  selectedMomo = val.toString();
                                                });
                                              }),
                                        ),
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            currentStep = 1;
                                            // height = 300;
                                            this.prepareTransaction(context,
                                                extra: extra);
                                          });
                                        },
                                        style: bStyle(this.buttonColors,
                                            radius: 50),
                                        child: appText(
                                            'Make Payment', 15, FontWeight.w600,
                                            col: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Step(
                            isActive: currentStep == 1,
                            title: Text('Finish'),
                            content: Container(
                                height: height,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: appText('Mobile Money Payment',
                                              15, FontWeight.bold),
                                        )
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: appText(
                                                'Confirm the mobile money prompt (if any). Please check your approvals if nothing happens soon.',
                                                15,
                                                FontWeight.normal,
                                                align: TextAlign.center),
                                          ),
                                        )
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    Center(
                                      child: progress(size: 30),
                                    )
                                  ],
                                )),
                          ),
                        ],
                        controlsBuilder:
                            (BuildContext context, ControlsDetails c) {
                          return Container();
                        },
                      )));
        });
  }

  headers() {
    var bytes = utf8.encode(this.clientKey);
    var auth = base64.encode(bytes);
    return {"Authorization": "Bearer $auth"};
  }
}
