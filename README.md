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
    clientId: '123456',
    buttonColors: Colors.black,
    bottomSheetBackgroundColor: Colors.white
);
```

### Process Payment

```dart

var paymentResponse = await
hp.processPayment(context: context, amount: 14.00
,
customerNumber: '
2330000000
'
);
print
(
paymentResponse.toString()
);

// Optional but useful parameter: customerName
// Optional but useful parameter: Map<String, dynamic> extra
```

`paymentResponse` from the calls, will contain the following in JSON response:

```json
{
  "success": true,
  "message": ""
}
```

A `success` value of `true` means the payment has actually been processed successfully and no
further action has to be taken.