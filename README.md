# harbor_pay

A Flutter package to accept payments with HarborPay.

## Getting Started
You will need an account on HarborPay to accept payments if you don't already have one.  
[Create one here](https://pay.harborstores.com/register), and get your `clientId` and `clientKey` from the preferences screen.

First, add the `harbor_pay` package to your pubspec dependencies.

### Import HarborPay

```dart
import 'package:harbor_pay/harbor_pay.dart';
```

### Create a HarborPay object

```dart
HPay hp = new HPay(
  clientId: '123456',
  clientKey: '456789765435678',
  currency: 'GHS',
  buttonColors: Colors.black
);
```

### Process Payment
```dart
var paymentResponse = await hp.processPayment(context: context, amount: 1.00, customerNumber: '2330000000');  
print(paymentResponse.toString()); 

// Optional but useful parameter: customerName
```

### Make A Deposit / Top-Up

Requires passing a `purpose` parameter as `deposit` in the `processPayment()` method.
```dart
var paymentResponse = await hp.processPayment(context: context, amount: 1.00, customerNumber: '2330000000', purpose: 'deposit');  
print(paymentResponse.toString()); 

// Optional but useful parameter: customerName
```

### Send Money

#### Option 1 (*Suitable for single recipients*)

```dart
var paymentResponse = await hp.sendMoney(context: context, amount: 1.00, customerNumber: '2330000000');  
print(paymentResponse.toString()); 

// Optional but useful parameter: customerName

```
#### Option 2

```dart
void doSendMoneyToMultiple() async {
    List<MoneyRecipient> clients = [
      new MoneyRecipient(customerNumber: '2330000000', amount: 1.00),
      new MoneyRecipient(customerNumber: '2330000001', amount: 2.00),
      // Optional but useful parameter: customerName
    ] ;
    var sendMoneyResponse = await hp.sendMoney(context: context, recipients: clients);
    print(sendMoneyResponse.toString());
  } 

```
### Make A Withdrawal

```dart
var withdrawMoneyResponse = await hp.withdraw(context: context, amount: 2.00, customerNumber: '2330000000');
print(withdrawMoneyResponse.toString());

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