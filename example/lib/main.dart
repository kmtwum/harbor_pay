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
    clientId: '123456',
    clientKey: '456789765435678',
    currency: 'GHS',
    buttonColors: Colors.black,
    source: 'MyFancyApp',
    callback: 'https://kampusbuy.com/pay/hook'
  );

  void doProcessPayment() async {
    var paymentResponse = await hp.processPayment(
        context: context,
        amount: 1.00,
        customerNumber: '233249713683');
    print(paymentResponse.toString());
  }

  void doDeposit() async {
    var paymentResponse = await hp.processPayment(
        context: context,
        amount: 1.00,
        customerNumber: '2330000000',
        purpose: 'deposit');
    print(paymentResponse.toString());
  }

  void doWithdraw() async {
    var withdrawMoneyResponse = await hp.withdraw(
        context: context, amount: 1.00, customerNumber: '2330000000');
    print(withdrawMoneyResponse.toString());
  }

  void sendMoney() async {
    List<MoneyRecipient> clients = [
      new MoneyRecipient(customerNumber: '2330000000', amount: 1.00),
      new MoneyRecipient(customerNumber: '2330000001', amount: 2.00),
    ];
    var sendMoneyResponse =
        await hp.sendMoney(context: context, recipients: clients);
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
              child: TextButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          ThemeData.light().primaryColor)),
                  onPressed: sendMoney,
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
              child: TextButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          ThemeData.light().primaryColor)),
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
              child: TextButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          ThemeData.light().primaryColor)),
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
            ),
            SizedBox(
              width: 200,
              child: TextButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          ThemeData.light().primaryColor)),
                  onPressed: doDeposit,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Deposit Money',
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
