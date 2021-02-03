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
  int _counter = 0;

  void proceed() async {
    HPay hp = new HPay(
      clientId: '1234',
      clientKey: '456789765435678',
      currency: 'GHS',
      amount: 1.00,
      customerNumber: '0000000000',
      buttonColors: Colors.black
    );

    var k = await hp.processPayment(context);
    print('FROM APP:' + k.toString());
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
            Text(
              'Tap the FAB to begin',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: proceed,
        tooltip: 'Test',
        child: Icon(Icons.arrow_forward),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}