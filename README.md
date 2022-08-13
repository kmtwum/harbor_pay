# harbor_pay

A Flutter package to accept mobile money payments.

## Getting Started
First, add the `harbor_pay` package to your pubspec dependencies.

### Import HarborPay

```dart
import 'package:harbor_pay/harbor_pay.dart';
```

### Create a HarborPay object

```dart
HPay hp = new HPay(
  clientKey: 'xxx'
);
```

### Process Payment
```dart
  var paymentResponse = await hp.processPayment(context: context, amount: 14.00, customerNumber: '2330000000');
  print(paymentResponse.toString());

// Optional but useful parameter: customerName
// Optional but useful parameter: Map<String, dynamic> extra
```