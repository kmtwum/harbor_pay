import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:harbor_pay/hp_io.dart';

class HPay {
  HPay(
      {required this.clientId,
      required this.callback,
      this.currency = 'GHS',
      this.purpose = '',
      this.reference = '',
      this.transactionType = 'momo',
      this.customerNumber = '',
      this.buttonColors = const Color(0xFF24b4c4),
      this.bottomSheetBackgroundColor = const Color(0xff787878)});

  String clientId;
  String currency;
  double amount = 0;
  String reference; //  used as transaction id. If not passed, a random string will be generated
  String purpose; //  useful when topping up a HarborPay wallet
  String callback; // where to receive status updates
  String transactionType; //  momo or card
  String transactionPlatform = 'MTN'; //AIR, MTN or VOD;
  String customerNumber;
  Color buttonColors;
  Color bottomSheetBackgroundColor;

  genId({int count = 8}) {
    var r = Random();
    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(count, (index) => _chars[r.nextInt(_chars.length)]).join();
  }

  initialize(HPay options) {
    this.clientId = options.clientId;
    this.amount = options.amount;
    this.currency = options.currency;
    this.reference = options.reference.isEmpty ? this.genId() : options.reference;
    this.purpose = options.purpose.isEmpty ? '{}' : options.purpose;
  }

  appendToInitializer(options) {
    if (options.transactionType != null) this.transactionType = options.transactionType;
    if (options.transactionPlatform != null) this.transactionPlatform = options.transactionPlatform;
    if (options.customerNumber != null) this.customerNumber = options.customerNumber;
    if (options.currency) this.currency = options.currency;
    if (options.amount) this.amount = options.amount;
    if (options.purpose) this.purpose = options.purpose;
  }

  prepareTransaction(context, {Map extra: const {}}) async {
    if (!['momo', 'card'].contains(this.transactionType)) {
      return {
        'success': false,
        'message': 'parameter transactionType should be one of [\'momo\', \'card\']',
      };
    }
    if (this.amount <= 0) {
      return {
        'success': false,
        'message': 'amount should be more than zero',
      };
    }

    var finalLoad = {
      "client": this.clientId,
      "reference": this.reference != '' ? this.reference : genId(count: 10),
      "transaction_type": this.transactionType,
      "customer_number": this.customerNumber,
      "currency": this.currency,
      "amount": this.amount,
      "purpose": this.purpose,
      "callback": this.callback
    };

    if (selectedMomo != '') {
      this.transactionPlatform = selectedMomo;
      finalLoad['network_type'] = this.transactionPlatform;
    }

    if (this.purpose != '') {
      if (['deposit', 'top_up'].indexOf(this.purpose) > 0) {
        finalLoad['meta'] = {'purpose': this.purpose, 'client': this.clientId};
      }
    }

    if (extra.length > 0) finalLoad['meta'] = extra;

//    print(finalLoad.toString());

    var x = await doPost('forward', finalLoad, headers: headers());

    if (x['resp_code'] == '015') {
      var responseMap = await queryTransStatus(finalLoad['reference']);
      Navigator.pop(context, responseMap);
    } else {
      Navigator.pop(context, x);
    }
  }

  Future<Map<String, dynamic>> queryTransStatus(transId) async {
    for (int i = 0; i < 5; i++) {
      await Future.delayed(Duration(seconds: 6));
      var dec = await doPost('verify', {'client': this.clientId, 'reference': transId}, headers: headers());
      if (dec['transactionStatus'] == 'Completed') {
        return {'success': true, 'message': 'Payment Received. Thank you'};
      } else if (dec['transactionStatus'] == 'Failed') {
        return {'success': false, 'message': 'Payment Failed. User did not confirm'};
      }
    }
    return {'success': false, 'message': 'Payment Failed. Timed out'};
  }

  Future processPayment(
      {required BuildContext context,
      required double amount,
      String? customerName,
      required String customerNumber,
      String? purpose,
      Map extra = const {}}) async {
    if (amount != 0) this.amount = amount;
    if (customerNumber != '') this.customerNumber = customerNumber;
    if (purpose != null) this.purpose = purpose;

    int currentStep = 0;
    double height = 340;

    return await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) => Container(
                  height: height,
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: this.bottomSheetBackgroundColor,
                  ),
                  child: Stepper(
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
                                    appText('Payment for:', 12, FontWeight.normal),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: appText('${this.currency}${this.amount.toString()}', 30, FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    appText('Select mobile money platform:', 12, FontWeight.normal),
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
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10),
                                        child: DropdownButton(
                                            isExpanded: true,
                                            underline: Container(),
                                            items: [
                                              DropdownMenuItem(
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 15,
                                                      backgroundImage:
                                                          AssetImage('assets/airteltigo.jpg', package: 'harbor_pay'),
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    appText('AirtelTigo', 15, FontWeight.w600),
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
                                                          AssetImage('assets/mtn.png', package: 'harbor_pay'),
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    appText('MTN', 15, FontWeight.w600),
                                                  ],
                                                ),
                                                value: 'MTN',
                                              ),
                                              DropdownMenuItem(
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 15,
                                                      backgroundImage:
                                                          AssetImage('assets/vodafone.jpg', package: 'harbor_pay'),
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    appText('Vodafone', 15, FontWeight.w600),
                                                  ],
                                                ),
                                                value: 'VOD',
                                              )
                                            ],
                                            value: selectedMomo,
                                            onChanged: (val) {
                                              setState(() {
                                                this.transactionType = MOMO_PAY_METHOD;
                                                this.transactionPlatform = val.toString();
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
                                          this.prepareTransaction(context, extra: extra);
                                        });
                                      },
                                      style: bStyle(this.buttonColors, radius: 50),
                                      child: appText('Make Payment', 15, FontWeight.w600, col: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            )),
                      ),
                      Step(
                        isActive: currentStep == 1,
                        title: Text('Finish ${this.transactionType}'),
                        content: Container(
                            height: height,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: appText('Mobile Money Payment', 15, FontWeight.bold),
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
                    controlsBuilder: (BuildContext context, ControlsDetails details) {
                      return Container();
                    },
                  )));
        });
  }

  headers() {
    var bytes = utf8.encode(this.clientId);
    var auth = base64.encode(bytes);
    return {"Authorization": "Bearer $auth"};
  }
}
