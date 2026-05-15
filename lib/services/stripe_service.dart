import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  static const String _secretKey =
      "sk_test_51TFXeuH0Dn2ZkytqlJO9vjnUVEspRn14iDAvGaK0kksU3BjhBTBnozyRZkRYSbjsjfRE1UlXw14gnJVpz0GUsprA00sF1sbDgq";

  static Map<String, dynamic>? paymentIntent;

  static Future<String?> makePayment(double amount, String currency) async {
    try {
      // 1. Create Payment Intent
      paymentIntent = await _createPaymentIntent(amount, currency);

      if (paymentIntent == null || paymentIntent!.containsKey('error')) {
        return paymentIntent?['error']?['message'] ??
            "Failed to create payment intent.";
      }

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent!['client_secret'],
          style: ThemeMode.light,
          merchantDisplayName: 'Musafirah App',
        ),
      );

      // 3. Display Payment Sheet
      return await _displayPaymentSheet();
    } catch (e) {
      debugPrint("Stripe Error: $e");
      return "Stripe Error: $e";
    }
  }

  static Future<String?> _displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      debugPrint("Payment Successful");
      paymentIntent = null;
      return null; // null means success
    } on StripeException catch (e) {
      debugPrint("Stripe Exception: $e");
      return e.error.message ?? "Payment cancelled or failed.";
    } catch (e) {
      debugPrint("Error: $e");
      return "An unexpected error occurred.";
    }
  }

  static Future<Map<String, dynamic>?> _createPaymentIntent(
    double amount,
    String currency,
  ) async {
    try {
      Map<String, String> body = {
        'amount': _calculateAmount(amount),
        'currency': currency.toLowerCase(),
        'payment_method_types[]': 'card',
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.body.isEmpty) {
        return {
          'error': {'message': 'Empty response from Stripe'},
        };
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        try {
          final errorDecoded = jsonDecode(response.body);
          return {
            'error': {'message': errorDecoded['error']?['message'] ?? 'Stripe API Error ${response.statusCode}'},
          };
        } catch (_) {
          if (response.body.contains('<!DOCTYPE HTML>')) {
             return {
              'error': {'message': 'Network Blocked: Your ISP is redirecting Stripe requests. Please try a different network or VPN.'},
            };
          }
          return {
            'error': {'message': 'Server Error ${response.statusCode}: ${response.body.length > 100 ? response.body.substring(0, 100) : response.body}'},
          };
        }
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        return {
          'error': {'message': 'Invalid JSON response from Stripe'},
        };
      }
    } catch (err) {
      debugPrint('Stripe createIntent Error: $err');
      String errorMsg = err.toString();
      if (errorMsg.contains('<!DOCTYPE HTML>')) {
        errorMsg = "Network Error: The connection is being intercepted. This usually happens if the system date is wrong or a firewall is active.";
      }
      return {
        'error': {'message': errorMsg},
      };
    }
  }

  static String _calculateAmount(double amount) {
    // Stripe expects amount in cents (e.g. 100 PKR = 10000 cents)
    final calculatedAmount = (amount * 100).toInt();
    return calculatedAmount.toString();
  }
}
