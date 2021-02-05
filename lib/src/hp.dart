import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:harbor_pay/hp_io.dart';

class SendMoney {
  SendMoney({
    this.amount,
    this.clientId,
    this.clientKey,
    this.currency,
  });

  String clientId;
  String clientKey;
  String currency;
  double amount;
}

class HPay {
  HPay(
      {this.amount,
      this.clientId,
      this.clientKey,
      this.currency,
      this.purpose,
      this.reference,
      this.transactionType,
      this.customerNumber,
      this.customerName,
      this.buttonColors = const Color(0xFF24b4c4)});

  String clientId;
  String clientKey;
  String currency;
  double amount;
  String reference; //If not passed, a random string will be generated
  String purpose; //useful when topping up a HarborPay wallet
  String transactionType; //momo or card
  String transactionPlatform; //AIR, MTN or VOD;
  String customerNumber;
  String customerName;

  Color buttonColors;

  bool allowMomo;
  bool allowCard;

  genId({int count = 8}) {
    var r = Random();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(count, (index) => _chars[r.nextInt(_chars.length)])
        .join();
  }

  initialize(HPay options) {
    this.clientId = options.clientId;
    this.clientKey = options.clientKey;
    this.amount = options.amount;
    this.currency = options.currency;
    this.reference =
        options.reference.isEmpty ? this.genId() : options.reference;
    this.purpose = options.purpose.isEmpty ? '{}' : options.purpose;
  }

  appendToInitializer(options) {
    if (options.transactionType != null)
      this.transactionType = options.transactionType;
    if (options.transactionPlatform != null)
      this.transactionPlatform = options.transactionPlatform;
    if (options.customerNumber != null)
      this.customerNumber = options.customerNumber;
    if (options.customerName != null) this.customerName = options.customerName;
    if (options.currency) this.currency = options.currency;
    if (options.amount) this.amount = options.amount;
    if (options.purpose) this.purpose = options.purpose;
  }

  processTransfer(context) async {
    if (this.amount <= 0) {
      return {
        'success': false,
        'message': 'amount should be more than zero',
      };
    }

    var finalLoad = {
      "client_id": this.clientId,
      "customer_number": this.customerNumber,
      "customer_name": this.customerName,
      "currency": this.currency,
      "amount": this.amount,
    };

    return await doPost('send_money', finalLoad, headers: headers());
  }

  prepareTransaction(context) async {
    if (!['momo', 'card'].contains(this.transactionType)) {
      return {
        'success': false,
        'message':
            'parameter transactionType should be one of [\'momo\', \'card\']',
      };
    }
    if (this.amount <= 0) {
      return {
        'success': false,
        'message': 'amount should be more than zero',
      };
    }

    var finalLoad = {
      "client_id": this.clientId,
      "client_reference": this.reference ?? genId(count: 10),
      "transaction_type": this.transactionType,
      "customer_number": this.customerNumber,
      "customer_name": this.customerName,
      "currency": this.currency,
      "amount": this.amount,
      "meta": {'purpose': this.purpose, 'client': this.clientId},
    };

    if (this.transactionPlatform != null) {
      finalLoad['transactionPlatform'] = this.transactionPlatform;
    }

    var x = await doPost('api', finalLoad, headers: headers());

    if (x['success']) {
      var responseMap = await queryTransStatus(finalLoad['client_reference']);
      Navigator.pop(context, responseMap);
    } else {
      Navigator.pop(context, x);
    }
  }

  Future<Map<String, dynamic>> queryTransStatus(transId) async {
    for (int i = 0; i < 5; i++) {
      await Future.delayed(Duration(seconds: 6));
      var dec = await doGet('verify/$transId', headers: headers());
      print('Status now:' + dec.toString());
      if (dec['transactionStatus'] == 'Completed') {
        return {'success': true, 'message': 'Payment Received. Thank you'};
      } else if (dec['transactionStatus'] == 'Failed') {
        return {
          'success': false,
          'message': 'Payment Failed. User did not confirm'
        };
      }
    }
    print('OK');
    return {'success': false, 'message': 'Payment Failed. Timed out'};
  }

  Future sendMoney(
      {BuildContext context,
      double amount,
      String customerName,
      String customerNumber}) async {
    this.amount = amount;
    this.customerNumber = customerNumber;
    this.customerName = customerName;

    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (_) {
          return Container(
            height: 130,
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                )),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child:
                          appText('Send Money', 15, FontWeight.bold),
                    )
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: appText(
                            'Transferring ${this.currency}$amount to $customerNumber...',
                            15,
                            FontWeight.normal,
                            align: TextAlign.center),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10),
                Center(
                  child: progress(size: 20),
                )
              ],
            ),
          );
        });

    Map sndMnResponse = await this.processTransfer(context);

    print(sndMnResponse);

    if (!sndMnResponse['success']) {
      Navigator.pop(context);
      return sndMnResponse;
    } else {
      Navigator.pop(context);
      return sndMnResponse;
    }

  }

  Future processPayment(
      {BuildContext context,
      double amount,
      String customerName,
      String customerNumber, String purpose = ''}) async {
    if (amount != null) this.amount = amount;
    if (customerNumber != null) this.customerNumber = customerNumber;
    if (customerName != null) this.customerName = customerName;
    if (purpose != null) this.purpose = purpose;

    int currentStep = 0;
    bool complete = false;
    double height = 220;

    return await showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (_) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) =>
                  Container(
                      height: height,
                      padding: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30.0),
                            topRight: Radius.circular(30.0),
                          )),
                      child: Stepper(
                        currentStep: currentStep,
                        type: StepperType.horizontal,
                        onStepContinue: () {
                          (currentStep + 1 != 3)
                              ? setState(() => currentStep = currentStep + 1)
                              : setState(() => complete = true);
                        },
                        onStepCancel: () {
                          (currentStep - 1 >= 0)
                              ? setState(() => currentStep = currentStep - 1)
                              : setState(() => complete = false);
                        },
                        steps: [
                          Step(
                            isActive: currentStep == 0,
                            title: Text('Method'),
                            content: Container(
                              height: 120,
                              child: ListView(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: appText(
                                            'Choose a payment method.',
                                            15,
                                            FontWeight.w600,
                                            align: TextAlign.center),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            height = 350;
                                            currentStep = 1;
                                          });
                                        },
                                        color: this.buttonColors,
                                        child: appText(
                                            'Mobile Money', 15, FontWeight.w600,
                                            col: Colors.white),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(50)),
                                      ),
//                                      SizedBox(width: 10),
//                                      FlatButton(
//                                        onPressed: () {},
//                                        color:
//                                            this.buttonColors.withOpacity(0.4),
//                                        child: appText(
//                                            'Debit Card', 15, FontWeight.w600,
//                                            col: Colors.white),
//                                        shape: RoundedRectangleBorder(
//                                            borderRadius:
//                                                BorderRadius.circular(50)),
//                                      )
                                    ],
                                  ),
                                  SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                          Step(
                            isActive: currentStep == 1,
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
                                            '${this.currency}${this.amount.toString()}',
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
                                                      val;
                                                  selectedMomo = val;
                                                });
                                              }),
                                        ),
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            currentStep = 2;
                                            this.prepareTransaction(context);
                                          });
                                        },
                                        color: this.buttonColors,
                                        child: appText(
                                            'Make Payment', 15, FontWeight.w600,
                                            col: Colors.white),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(50)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Step(
                            isActive: currentStep == 2,
                            title: Text('Finish'),
                            content: Container(
                              height: 210,
                              padding: EdgeInsets.all(20.0),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(30.0),
                                    topRight: Radius.circular(30.0),
                                  )),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                              ),
                            ),
                          ),
                        ],
                        controlsBuilder: (BuildContext context,
                            {VoidCallback onStepContinue,
                            VoidCallback onStepCancel}) {
                          return Container();
                        },
                      )));
        });
  }

  headers() {
    var bytes = utf8.encode(this.clientId + ":" + this.clientKey);
    var auth = base64.encode(bytes);
    return {"Authorization": "Bearer $auth"};
  }
}
