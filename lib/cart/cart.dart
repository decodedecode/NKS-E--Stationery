import 'dart:math';
import 'package:animated_digit/animated_digit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nks/main.dart';
import 'package:nks/pages/PaymentGateway/PayGateway.dart';
import 'package:nks/pages/orders.dart';
import 'package:page_transition/page_transition.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CartPage());
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Please log in to view your cart.'),
          ),
        ),
      );
    }

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Cart(),
    );
  }
}

class Cart extends StatefulWidget {
  const Cart({Key? key}) : super(key: key);

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> with SingleTickerProviderStateMixin {
  late Razorpay _razorpay;
  final PayGateway _payGateway = PayGateway();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _scrollController = ScrollController();

// To manage price update state
  late AnimationController _colorAnimationController;

  @override
  void initState() {
    super.initState();

    _payGateway.init(); // Initialize Razorpay

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // _calculateTotalPrice();
    _cartTotalPriceStream();

    _colorAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _payGateway.dispose();
    _colorAnimationController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Payment Successful'),
        content: Text('Payment ID: ${response.paymentId}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
    createOrder('Prepaid');

    // _clearCart();
  }

  // void _clearCart() {
  //   final user = _auth.currentUser;
  //   if (user != null) {
  //     _firestore
  //         .collection('userCart')
  //         .doc(user.uid)
  //         .collection('cart')
  //         .get()
  //         .then((snapshot) {
  //       for (var doc in snapshot.docs) {
  //         doc.reference.delete();
  //       }
  //     });
  //   }
  // }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Handle payment failure
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Payment Failed'),
          content: Text('${response.message}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Try Again'),
            ),
          ],
        ),
      );
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('External Wallet Selected'),
          content: Text('Wallet Name: ${response.walletName}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  Stream<int> _cartTotalPriceStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('userCart')
        .doc(user.uid)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        int price = int.parse(data['price'].replaceAll('₹', ''));
        int quantity = data['quantity'];
        total += price * quantity;
      }
      return total;
    });
  }

  bool noProducts = false;

  // void _onPaymentSuccess(String paymentId) {
  //   createOrder('Prepaid');
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       backgroundColor: Color(0xFFD0F3EA),
  //       title: const Text('Payment Successful'),
  //       content: Text('Payment ID: $paymentId'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  //   createOrder('Prepaid');
  //
  //   _clearCart();
  // }
  //
  // void _onPaymentError(String errorMessage) {
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text('Payment Failed'),
  //       content: Text(errorMessage),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Try Again'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // void _onExternalWallet(String walletName) {
  //   createOrder('Prepaid');
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text('External Wallet Selected'),
  //       content: Text('Wallet Name: $walletName'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _updateQuantity(String productId, int newQuantity) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = _firestore
        .collection('userCart')
        .doc(user.uid)
        .collection('cart')
        .doc(productId);

    if (newQuantity > 0) {
      await cartRef.update({'quantity': newQuantity});
    } else {
      await cartRef.delete();
    }
    setState(() {});
    _cartTotalPriceStream();
  }

  Color _getRandomColor() {
    Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    ).withOpacity(0.1); // Adding slight opacity
  }

  Future<void> createOrder(String paymentMethod) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are permanently denied.');
        }
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final userName = FirebaseAuth.instance.currentUser;
      String name =
          userName != null ? (userName.displayName ?? 'Guest') : 'Guest';

      final cartProducts = await _firestore
          .collection('userCart')
          .doc(userName?.uid)
          .collection('cart')
          .get();

      List<Map<String, dynamic>> products = [];
      for (var doc in cartProducts.docs) {
        final productData = doc.data();
        products.add({
          'id': productData['id'],
          'name': productData['name'],
          'price': productData['price'],
          'image': productData['image'],
          'quantity': productData['quantity'],
          'brand': productData['brand']
        });
      }

      await FirebaseFirestore.instance.collection('Orders').doc(name).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'paymentMethod': paymentMethod,
        'userName': name,
        'userId': userName?.uid,
        'products': products,
        // Add the list of products
      });

      print('Order created successfully.');
    } catch (e) {
      print('Error creating order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating order: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateNoProducts(bool noProducts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('noProducts', noProducts);
  }

  Future<void> saveData(bool noProducts) async {
    final prefs = await SharedPreferences.getInstance();

    // Saving data to SharedPreferences
    await prefs.setBool('noProducts', noProducts);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Please log in to view your cart.')),
      );
    }

    final cartRef =
        _firestore.collection('userCart').doc(user.uid).collection('cart');

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor:
          MediaQuery.of(context).platformBrightness == Brightness.dark
              ? Color(0xFF121318)
              : Colors.white,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 40,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color:
                  MediaQuery.of(context).platformBrightness == Brightness.dark
                      ? Color(0xFF121318)
                      : Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_outlined,
                    size: 30,
                  ),
                  color: MediaQuery.of(context).platformBrightness ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst); // Pop until the first route
                    Navigator.pushReplacement(
                      context,
                      PageTransition(
                        type: PageTransitionType.leftToRight,
                        child: const MainScreen(),
                      ),
                    );                  },
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 6,
                ),
                Text(
                  'Shopping Cart',
                  style: GoogleFonts.russoOne(
                    color: MediaQuery.of(context).platformBrightness ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 24,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: cartRef.snapshots(),
                builder: (context, snapshot) {
                  // if (snapshot.connectionState == ConnectionState.waiting) {}
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    // Update SharedPreferences asynchronously
                    _updateNoProducts(true);

                    return Center(
                      child: Text(
                        'No products added to the cart',
                        style: GoogleFonts.manrope(
                          color: MediaQuery.of(context).platformBrightness ==
                                  Brightness.light
                              ? Color(0xFF1A1A1A)
                              : Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    );
                  } else {
                    // Update SharedPreferences asynchronously
                    _updateNoProducts(false);

                    // Display the cart items
                    final cartProducts = snapshot.data!.docs;
                    print('hey $cartProducts');
                    return AnimatedOpacity(
                      opacity: 1,
                      // Fade effect
                      duration: const Duration(milliseconds: 300),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: cartProducts.length,
                        itemBuilder: (context, index) {
                          final product = cartProducts[index].data()
                              as Map<String, dynamic>;
                          final productId = cartProducts[index].id;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: _getRandomColor(),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                // Product Image
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: NetworkImage(product['image']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Product Details
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          product['name'],
                                          style: GoogleFonts.kanit(
                                            color: MediaQuery.of(context)
                                                        .platformBrightness ==
                                                    Brightness.light
                                                ? Color(0xFF1A1A1A)
                                                : Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 17),
                                        Text(
                                          'Price: ${product['price']}',
                                          style: GoogleFonts.kanit(
                                            fontSize: 18,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Quantity Control
                                Column(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        int newQuantity =
                                            product['quantity'] + 1;
                                        _updateQuantity(productId, newQuantity);
                                      },
                                      icon: const Icon(Icons.add),
                                    ),
                                    Text(
                                      '${product['quantity']}',
                                      style: GoogleFonts.russoOne(
                                          fontSize: 20,
                                          color: MediaQuery.of(context)
                                                      .platformBrightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        int newQuantity =
                                            product['quantity'] - 1;
                                        _updateQuantity(productId, newQuantity);
                                      },
                                      icon: Icon(Icons.remove),
                                    ),
                                  ],
                                ),
                                // Remove Button
                                IconButton(
                                  onPressed: () {
                                    _updateQuantity(productId, 0);
                                  },
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }
                }),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text('Total:',
                          style: GoogleFonts.russoOne(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              fontSize: 20)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5),
                      child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: StreamBuilder<int>(
                            stream: _cartTotalPriceStream(),
                            builder: (context, snapshot) {
                              final totalPrice = snapshot.data ?? 0;

                              return AnimatedDigitWidget(
                                prefix: '₹ ',
                                value: totalPrice,
                                duration: const Duration(milliseconds: 500),
                                textStyle: GoogleFonts.kanit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: Colors.green,
                                ),
                                separateSymbol: ',',
                                curve: Curves.easeInOut,
                              );
                            },
                          )),
                    )
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 80,
                  width: MediaQuery.of(context).size.width - 10,
                  child: ElevatedButton(
                    child: Text(
                      'Proceed to Checkout',
                      style: GoogleFonts.russoOne(
                          fontWeight: FontWeight.w200,
                          color: Colors.white,
                          fontSize: 18),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();

                      // Fetching the value of 'noProducts' from SharedPreferences
                      bool? noProd = prefs.getBool('noProducts');

                      if (noProd == null || noProd == false) {
                        // Navigate to OrdersPage if products exist
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => OrdersPage()));
                      } else {
                        void showTopSnackBar(
                            BuildContext context, String message,
                            {Color? color}) {
                          final overlay = Overlay.of(context);
                          final overlayEntry = OverlayEntry(
                            builder: (context) => Positioned(
                              top: MediaQuery.of(context).padding.top +
                                  20, // Just below the status bar
                              left: 16,
                              right: 16,
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: color ?? Color(0xFF6C91C2),
                                    // Vibrant green
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            message,
                                            style: GoogleFonts.kanit(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      // Icon(Icons.g_mobiledata_rounded, color: Colors.greenAccent),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );

                          overlay.insert(overlayEntry);

                          Future.delayed(Duration(seconds: 2), () {
                            overlayEntry.remove();
                          });
                        }

                        showTopSnackBar(context, 'No Products Found in Cart',
                            color: Color(0xFFF8B88B));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6C91C2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
