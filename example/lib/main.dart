import 'package:flutter/material.dart';
import 'package:harbor_pay/harbor_pay.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HarborPay Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'HarborPay Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  HPay hp = new HPay(
    clientId: '1234',
    clientKey: '456789765435678',
    currency: 'GHS',
    buttonColors: Colors.black,
  );

  void doProcessPayment() async {
    var paymentResponse = await hp.processPayment(context: context, amount: 1.00, customerNumber: '2330000000');
    print(paymentResponse.toString());
  }

  void doSendMoney() async {
    var sendMoneyResponse = await hp.sendMoney(context: context, amount: 1.00, customerNumber: '2330000000');
    print(sendMoneyResponse.toString());
  }

  void doWithdraw() async {
    var withdrawMoneyResponse = await hp.withdraw(context: context, amount: 1.00, customerNumber: '2330000000');
    print(withdrawMoneyResponse.toString());
  }

  void doSendMoneyToMultiple() async {
    List<MoneyRecipient> clients = [
      new MoneyRecipient(customerNumber: '2330000000', amount: 1.00),
      new MoneyRecipient(customerNumber: '2330000001', amount: 2.00),
    ];
    var sendMoneyResponse = await hp.sendMoney(context: context, recipients: clients);
    print(sendMoneyResponse.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 200,
              child: FlatButton(
                  color: ThemeData.light().primaryColor,
                  onPressed: doSendMoneyToMultiple,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Send Money',
                        style: TextStyle(color: Colors.white),
                      ),
                      Icon(Icons.call_made, color: Colors.white),
                    ],
                  )),
            ),
            SizedBox(
              width: 200,
              child: FlatButton(
                  color: ThemeData.light().primaryColor,
                  onPressed: doProcessPayment,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Request Money',
                        style: TextStyle(color: Colors.white),
                      ),
                      Icon(Icons.call_received, color: Colors.white),
                    ],
                  )),
            ),
            SizedBox(
              width: 200,
              child: FlatButton(
                  color: ThemeData.light().primaryColor,
                  onPressed: doWithdraw,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Withdraw Money',
                        style: TextStyle(color: Colors.white),
                      ),
                      Icon(Icons.call_made, color: Colors.white),
                    ],
                  )),
            )
          ],
        ),
      ),
    );
  }
}
