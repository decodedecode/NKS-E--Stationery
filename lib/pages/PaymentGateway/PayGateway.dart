import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PayGateway {
  final Razorpay _razorpay;

  PayGateway() : _razorpay = Razorpay();

  // Initialize Razorpay and set the event listeners
  void init() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear(); // Clean up the Razorpay instance when done
  }

  // Payment success callback
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("Payment Success: ${response.paymentId}");
  }

  // Payment failure callback
  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Failed: ${response.message}");
  }

  // External wallet callback
  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
  }

  // Open Razorpay Checkout
  void openCheckout({
    required int amount, // Amount in paise
    required String name,
    required String description,
    required String prefillContact,
    required String prefillEmail,
    required Function(String paymentId) onSuccess,
    required Function(String errorMessage) onError,
    required Function(String walletName) onExternalWallet,
  }) 
  {
    var options = {

      'key': 'rzp_test_',
      'amount': amount,
      'name': name,
      'description': description,
      'prefill': {
        'contact': prefillContact,
        'email': prefillEmail,
      },
      'theme': {'color': '#DFFDFF'},
    };

    try {
      print("Checkout options: $options");

      _razorpay.open(options);

      // Assign user-defined callback methods after Razorpay initializes
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
        onSuccess(response.paymentId!);
      });

      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        onError(response.message ?? 'Unknown error');
      });

      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
        onExternalWallet(response.walletName ?? 'Unknown wallet');
      });

    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}
