import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartProducts = [];

  List<Map<String, dynamic>> get cartProducts => _cartProducts;

  void addToCart(Map<String, dynamic> product) {
    // Check if the product already exists in the cart
    var existingProduct =
    _cartProducts.firstWhere((p) => p['id'] == product['id'], orElse: () => {});
    if (existingProduct.isNotEmpty) {
      existingProduct['quantity']++;
    } else {
      _cartProducts.add({...product, 'quantity': 1});
    }
    notifyListeners(); // Notify listeners to rebuild UI
  }

  void removeFromCart(String productId) {
    _cartProducts.removeWhere((product) => product['id'] == productId);
    notifyListeners();
  }
}
