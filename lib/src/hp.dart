import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:harbor_pay/hp_io.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MoneyRecipient {
  MoneyRecipient({
    this.amount = 0,
    this.customerNumber = '',
    this.customerName = '',
  });

  double amount;
  String customerNumber;
  String customerName;

  factory MoneyRecipient.fromRawJson(String str) => MoneyRecipient.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory MoneyRecipient.fromJson(Map<String, dynamic> json) => MoneyRecipient(
        amount: json["amount"] == null ? null : json["amount"].toDouble(),
        customerNumber: json["customer_number"] == null ? null : json["customer_number"],
        customerName: json["customer_name"] == null ? null : json["customer_name"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "customer_number": customerNumber,
        "customer_name": customerName,
      };
}

class PlatformViewVerticalGestureRecognizer extends VerticalDragGestureRecognizer {
  PlatformViewVerticalGestureRecognizer({PointerDeviceKind? kind}) : super(kind: kind);

  Offset _dragDistance = Offset.zero;

  @override
  void addPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    _dragDistance = _dragDistance + event.delta;
    if (event is PointerMoveEvent) {
      final double dy = _dragDistance.dy.abs();
      final double dx = _dragDistance.dx.abs();

      if (dy > dx && dy > kTouchSlop) {
        // vertical drag - accept
        resolve(GestureDisposition.accepted);
        _dragDistance = Offset.zero;
      } else if (dx > kTouchSlop && dx > dy) {
        // horizontal drag - stop tracking
        stopTrackingPointer(event.pointer);
        _dragDistance = Offset.zero;
      }
    }
  }

  @override
  String get debugDescription => 'horizontal drag (platform view)';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}

class HPay {
  HPay(
      {required this.clientId,
      required this.clientKey,
      required this.currency,
      this.purpose = '',
      this.source = '',
      this.reference = '',
      this.transactionType = '',
      this.customerNumber = '',
      this.customerName = '',
      this.buttonColors = const Color(0xFF24b4c4)});

  String clientId;
  String clientKey;
  String currency;
  double amount = 0;
  String reference; //If not passed, a random string will be generated
  String purpose; //useful when topping up a HarborPay wallet
  String source; //useful to tell which platform payment came from
  String transactionType; //momo or card
  String transactionPlatform = 'MTN'; //AIR, MTN or VOD;
  String customerNumber;
  String customerName;
  List<MoneyRecipient> recipients = [];
  Color buttonColors;

  genId({int count = 8}) {
    var r = Random();
    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(count, (index) => _chars[r.nextInt(_chars.length)]).join();
  }

  initialize(HPay options) {
    this.clientId = options.clientId;
    this.clientKey = options.clientKey;
    this.amount = options.amount;
    this.currency = options.currency;
    this.reference = options.reference.isEmpty ? this.genId() : options.reference;
    this.purpose = options.purpose.isEmpty ? '{}' : options.purpose;
  }

  appendToInitializer(options) {
    if (options.transactionType != null) this.transactionType = options.transactionType;
    if (options.transactionPlatform != null) this.transactionPlatform = options.transactionPlatform;
    if (options.customerNumber != null) this.customerNumber = options.customerNumber;
    if (options.customerName != null) this.customerName = options.customerName;
    if (options.currency) this.currency = options.currency;
    if (options.amount) this.amount = options.amount;
    if (options.purpose) this.purpose = options.purpose;
  }

  processTransfer(context) async {
    if (this.recipients.length == 0) {
      if (this.amount <= 0) {
        return {
          'success': false,
          'message': 'amount should be more than 0.00',
        };
      }
    } else {
      if (this.recipients.any((MoneyRecipient element) => element.amount <= 0)) {
        return {
          'success': false,
          'message': 'amount should be more than 0.00',
        };
      }
    }

    var finalLoad = {
      "client_id": this.clientId,
      "customer_number": this.customerNumber,
      "customer_name": this.customerName,
      "currency": this.currency,
      "amount": this.amount,
      "recipients": jsonEncode(this.recipients)
    };

    var x = await doPost('send_money', finalLoad, headers: headers());
    return x;
  }

  processWithdrawal(context) async {
    if (this.amount <= 0) {
      return {
        'success': false,
        'message': 'amount should be more than 0.00',
      };
    }

    var finalLoad = {
      "client_id": this.clientId,
      "account_type": MOMO_PAY_METHOD,
      "account_platform": this.transactionPlatform,
      "account_number": this.customerNumber,
      "account_name": this.customerName,
      "currency": this.currency,
      "amount": this.amount
    };

    var x = await doPost('withdraw', finalLoad, headers: headers());
    Navigator.pop(context, x);
  }

  prepareTransaction(context, {Map extra: const {}}) async {
    if (!['momo', 'card', 'paypal'].contains(this.transactionType)) {
      return {
        'success': false,
        'message': 'parameter transactionType should be one of [\'momo\', \'card\', \'paypal\']',
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
      "client_reference": this.reference != '' ? this.reference : genId(count: 10),
      "transaction_type": this.transactionType,
      "customer_number": this.customerNumber,
      "customer_name": this.customerName,
      "currency": this.currency,
      "amount": this.amount,
      "source": this.source
    };

    if (selectedMomo != '') {
      this.transactionPlatform = selectedMomo;
      finalLoad['transaction_platform'] = this.transactionPlatform;
    }

    if (this.purpose != '') {
      if (['deposit', 'top_up'].indexOf(this.purpose) > 0) {
        finalLoad['meta'] = {'purpose': this.purpose, 'client': this.clientId};
      }
    }

    if (extra.length > 0) finalLoad['meta'] = extra;

//    print(finalLoad.toString());

    var x = await doPost('api', finalLoad, headers: headers());

    if (this.transactionType == 'paypal') return x;

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
      if (dec['transactionStatus'] == 'Completed') {
        return {'success': true, 'message': 'Payment Received. Thank you'};
      } else if (dec['transactionStatus'] == 'Failed') {
        return {'success': false, 'message': 'Payment Failed. User did not confirm'};
      }
    }
    return {'success': false, 'message': 'Payment Failed. Timed out'};
  }

  paymentCaptured(BuildContext context) {
    if (this.transactionType == 'paypal') {
      Future.delayed(Duration(seconds: 7), () {
        Navigator.pop(context, {'success': true, 'transactionStatus': 'Completed'});
      });
    }
  }

  Future sendMoney({required BuildContext context, List<MoneyRecipient> recipients = const []}) async {
    this.recipients = recipients;
    this.customerNumber = "";
    this.customerName = "";

    showModalBottomSheet(
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
                      child: appText('Send Money', 15, FontWeight.bold),
                    )
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: this.recipients.length == 0
                            ? appText('Transferring ${this.currency}$amount to $customerNumber...', 15, FontWeight.normal,
                                align: TextAlign.center)
                            : appText('Transferring money to recipient(s)...', 15, FontWeight.normal, align: TextAlign.center),
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

    Navigator.pop(context);
    return sndMnResponse;
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
    if (customerName != null) this.customerName = customerName;
    if (purpose != null) this.purpose = purpose;
    final Completer<WebViewController> _controller = Completer<WebViewController>();

    int currentStep = 0;
    double height = 220;
    bool paymentInitiated = false;
    var wvURI = '';

    return await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) => Container(
                  height: height,
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Stepper(
                    currentStep: currentStep,
                    type: StepperType.horizontal,
                    onStepContinue: () {
                      (currentStep + 1 != 3) ? setState(() => currentStep = currentStep + 1) : setState(() {});
                    },
                    onStepCancel: () {
                      (currentStep - 1 >= 0) ? setState(() => currentStep = currentStep - 1) : setState(() {});
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
                                    child: appText('Choose a payment method.', 15, FontWeight.w600, align: TextAlign.center),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  this.currency == 'GHS'
                                      ? ElevatedButton(
                                          style: bStyle(this.buttonColors, radius: 50),
                                          onPressed: () {
                                            setState(() {
                                              this.transactionType = 'momo';
                                              selectedMomo = MOMO_MTN;
                                              height = 350;
                                              currentStep = 1;
                                            });
                                          },
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.mobile_screen_share,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              appText('Mobile Money', 15, FontWeight.w600, col: Colors.white),
                                            ],
                                          ),
                                        )
                                      : Container(),
                                  this.currency == 'USD' ? SizedBox(width: 5) : Container(),
                                  this.currency == 'USD'
                                      ? TextButton(
                                          style: bStyle(this.buttonColors, radius: 50),
                                          onPressed: () {
                                            setState(() {
                                              this.transactionType = 'paypal';
                                              selectedMomo = '';
                                              height = 250;
                                              currentStep = 1;
                                            });
                                          },
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.credit_card,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              appText('PayPal/Card', 15, FontWeight.w600, col: Colors.white),
                                            ],
                                          ),
                                        )
                                      : Container()
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
                          child: this.transactionType == 'momo'
                              ? ListView(
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
                                                          backgroundImage: AssetImage('assets/airteltigo.jpg', package: 'harbor_pay'),
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
                                                          backgroundImage: AssetImage('assets/mtn.png', package: 'harbor_pay'),
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
                                                          backgroundImage: AssetImage('assets/vodafone.jpg', package: 'harbor_pay'),
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
                                              currentStep = 2;
                                              height = 300;
                                              this.prepareTransaction(context, extra: extra);
                                            });
                                          },
                                          style: bStyle(this.buttonColors, radius: 50),
                                          child: appText('Make Payment', 15, FontWeight.w600, col: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : ListView(
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
                                    this.currency == 'GHS'
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                size: 14,
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              appText('Payment will be charged in USD.', 12, FontWeight.normal),
                                            ],
                                          )
                                        : Container(),
                                    this.currency == 'GHS'
                                        ? SizedBox(
                                            height: 6,
                                          )
                                        : Container(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              height = 310;
                                              paymentInitiated = true;
                                            });
                                            Map response = await prepareTransaction(context, extra: extra);
                                            if (!response['success']) {
                                              Navigator.pop(context, response);
                                            } else {
                                              wvURI = response['message'];
                                              setState(() {
                                                height = appHeight(context) * 0.90;
                                                currentStep = 2;
                                              });
                                            }
                                          },
                                          style: bStyle(this.buttonColors, radius: 50),
                                          child: appText('Initiate Payment', 15, FontWeight.w600, col: Colors.white),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    paymentInitiated ? Center(child: progress(size: 25)) : Container(),
                                  ],
                                ),
                        ),
                      ),
                      Step(
                        isActive: currentStep == 2,
                        title: Text('Finish'),
                        content: Container(
                          height: height,
                          child: this.transactionType == 'momo'
                              ? Column(
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
                                )
                              : Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: appText('PayPal Payment', 15, FontWeight.bold),
                                        )
                                      ],
                                    ),
                                    Container(
                                      height: height - 50,
                                      child: paymentInitiated
                                          ? WebView(
                                              initialUrl: wvURI,
                                              javascriptMode: JavascriptMode.unrestricted,
                                              onWebViewCreated: (WebViewController webViewController) {
                                                _controller.complete(webViewController);
                                              },
                                              navigationDelegate: (NavigationRequest request) {
                                                if (request.url.startsWith('https://app.myharborpay.com/pcap')) {
                                                  paymentCaptured(context);
                                                }
                                                return NavigationDecision.navigate;
                                              },
                                              gestureRecognizers: [
                                                Factory(() => PlatformViewVerticalGestureRecognizer()),
                                              ].toSet(),
                                              gestureNavigationEnabled: true,
                                            )
                                          : Container(),
                                    )
                                  ],
                                ),
                        ),
                      ),
                    ],
                    controlsBuilder: (BuildContext context, {VoidCallback? onStepContinue, VoidCallback? onStepCancel}) {
                      return Container();
                    },
                  )));
        });
  }

  Future withdraw({required BuildContext context, required double amount, String? customerName, required String customerNumber}) async {
    if (amount != 0) this.amount = amount;
    if (customerNumber != '') this.customerNumber = customerNumber;
    if (customerName != null) this.customerName = customerName;
    TextEditingController _mobController = new TextEditingController();

    selectedMomo = MOMO_MTN;
    int currentStep = 0;
    double height = appHeight(context) * 0.8;
    _mobController.text = this.customerNumber;

    return await showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (_) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) => Container(
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
                      (currentStep + 1 != 2) ? setState(() => currentStep = currentStep + 1) : setState(() {});
                    },
                    onStepCancel: () {
                      (currentStep - 1 >= 0) ? setState(() => currentStep = currentStep - 1) : setState(() {});
                    },
                    steps: [
                      Step(
                        isActive: currentStep == 0,
                        title: Text('Number & Provider'),
                        content: Container(
                          height: 620,
                          child: ListView(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  appText('Withdrawal for: ${this.currency}${this.amount.toString()}', 18, FontWeight.bold),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 15.0),
                                      child: TextField(
                                        autofocus: true,
                                        controller: _mobController,
                                        keyboardType: TextInputType.phone,
                                        textAlign: TextAlign.center,
                                        decoration: textDecor(hint: 'Mobile Number', prefixIcon: Icon(Icons.phone)),
                                        onChanged: (w) {
                                          this.customerNumber = w;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 10,
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
                                                    backgroundImage: AssetImage('assets/airteltigo.jpg', package: 'harbor_pay'),
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
                                                    backgroundImage: AssetImage('assets/mtn.png', package: 'harbor_pay'),
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
                                                    backgroundImage: AssetImage('assets/vodafone.jpg', package: 'harbor_pay'),
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
                                  this.customerNumber.isNotEmpty
                                      ? ElevatedButton(
                                          style: bStyle(this.buttonColors, radius: 50),
                                          onPressed: () {
                                            if (this.customerNumber.isEmpty) {
                                            } else {
                                              setState(() {
                                                height = 240;
                                                currentStep = 1;
                                                this.processWithdrawal(context);
                                              });
                                            }
                                          },
                                          child: appText('Withdraw', 15, FontWeight.w600, col: Colors.white),
                                        )
                                      : Container(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Step(
                        isActive: currentStep == 1,
                        title: Text('Finish'),
                        content: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: appText('Mobile Money Withdrawal', 15, FontWeight.bold),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: appText('Withdrawal in progress.', 15, FontWeight.normal, align: TextAlign.center),
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
                      ),
                    ],
                    controlsBuilder: (BuildContext context, {VoidCallback? onStepContinue, VoidCallback? onStepCancel}) {
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
