# harbor_pay

A Flutter package to accept payments with HarborPay.

## Getting Started
You will need an account on HarborPay to accept payments if you don't already have one.  
[Create one here](https://pay.harborstores.com/register) to get your `clientId` and `clientKey`.

First, add the `harbor_pay` package to your pubspec dependencies.

### Import HarborPay

```
import 'package:harbor_pay/harbor_pay.dart';
```

### Initialise HarborPay

```
HPay hp = new HPay(
  clientId: '123456',
  clientKey: '456789765435678',
  currency: 'GHS',
  amount: 1.00,
  customerNumber: '2330000000',
  buttonColors: Colors.black
);
```

### Process Payment

```
var paymentResponse = await hp.processPayment(context);
```

From the above, `paymentResponse` will be in JSON as described below:

```json
{
  "success": true,
  "message": ""
}
```

A `success` value of `true` means the payment has actually been processed successfully and no further action has to bbe taken.