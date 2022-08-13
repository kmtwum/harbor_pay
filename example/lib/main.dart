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
    clientKey: 'xxx',
    buttonColors: Colors.black,
    bottomSheetBackgroundColor: Colors.yellow
  );

  void doProcessPayment() async {
    var paymentResponse = await hp.processPayment(context: context, amount: 14.00, customerNumber: '2330000000', extra: {'order_id': 'STRF3C77575'});
    print(paymentResponse.toString());
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
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(ThemeData.light().primaryColor)),
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
          ],
        ),
      ),
    );
  }
}
