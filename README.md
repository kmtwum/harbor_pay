# harbor_pay

A Flutter package to accept payments with HarborPay.

## Getting Started
You will need an account on HarborPay to accept payments if you don't already have one.  
[Create one here](https://pay.harborstores.com/register), and get your `clientId` and `clientKey` from the preferences screen.

First, add the `harbor_pay` package to your pubspec dependencies.

### Import HarborPay

```
import 'package:harbor_pay/harbor_pay.dart';
```

### Create a HarborPay object

```
HPay hp = new HPay(
  clientId: '123456',
  clientKey: '456789765435678',
  currency: 'GHS',
  buttonColors: Colors.black
);
```

### Process Payment
```
var paymentResponse = await hp.processPayment(context: context, amount: 1.00, customerNumber: '2330000000');  
print(paymentResponse.toString()); 

// Optional but useful parameter: customerName
```

### Make A Deposit / Top-Up

Requires passing a `purpose` parameter as `deposit` in the `processPayment()` method.
```
var paymentResponse = await hp.processPayment(context: context, amount: 1.00, customerNumber: '2330000000', purpose: 'deposit');  
print(paymentResponse.toString()); 

// Optional but useful parameter: customerName
```

### Send Money

```
var paymentResponse = await hp.sendMoney(context: context, amount: 1.00, customerNumber: '2330000000');  
print(paymentResponse.toString()); 

// Optional but useful parameter: customerName
```

`paymentResponse` from the calls, will contain the following  in JSON response:

```json
{
  "success": true,
  "message": ""
}
```
A `success` value of `true` means the payment has actually been processed successfully and no further action has to be taken.