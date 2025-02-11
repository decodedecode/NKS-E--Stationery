import 'dart:convert';

import 'package:animated_digit/animated_digit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nks/cart/cart.dart';
import 'package:nks/pages/productDetail.dart';
import 'package:nks/widgets/orderPageWidgets.dart';
import 'package:page_transition/page_transition.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'PaymentGateway/PayGateway.dart';

double _selectedShippingPrice = 0.0;
String _selectedShippingMethod = '';

final instructionController = TextEditingController();
bool selected = false;


class ShippingOptions extends StatefulWidget {
  final Function(double shippingPrice) onShippingPriceChanged;

  const ShippingOptions({required this.onShippingPriceChanged});

  @override
  _ShippingOptionsState createState() => _ShippingOptionsState();
}

class _ShippingOptionsState extends State<ShippingOptions> {
  late ScrollController _scrollController; 
  int? _selectedShippingOption = 0;
  double _selectedShippingPrice = 0.0; 

  DateTime now = DateTime.now();
  String formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
  String TformattedDate = DateFormat('MMM dd, yyyy')
      .format(DateTime.now().add(Duration(hours: 24)));
  String formattedTime = DateFormat('hh:mm a').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadSavedOption();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Save selected shipping option to SharedPreferences
  Future<void> _saveSelectedOption(int value, double price) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedShippingOption', value);
    await prefs.setDouble('selectedShippingPrice', price);
  }

  // Load saved shipping option from SharedPreferences
  Future<void> _loadSavedOption() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedShippingOption = prefs.getInt('selectedShippingOption') ?? 0;
      _selectedShippingPrice = prefs.getDouble('selectedShippingPrice') ?? 0.0;
      widget.onShippingPriceChanged(_selectedShippingPrice);
    });
  }

  Widget card(
    String title,
    String date,
    String price,
    int value,
    double shippingPrice,
  ) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Card(
      color: isDark ? Color(0xFF292929) : Color(0xffffffff),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _selectedShippingOption == value
              ? Colors.green
              : (isDark ? Colors.grey : Colors.black45),
          width: _selectedShippingOption == value ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 80,
            width: 350, // Adjust width as needed
            child: ListTile(
              leading: Radio<int>(
                value: value,
                groupValue: _selectedShippingOption,
                onChanged: (newValue) {
                  setState(() {
                    selected = true;
                    _selectedShippingOption = newValue;
                    _selectedShippingPrice = shippingPrice;
                    widget.onShippingPriceChanged(_selectedShippingPrice);
                    _saveSelectedOption(
                        newValue!, shippingPrice); // Save selection
                    _selectedShippingMethod = title;
                  });
                },
                activeColor: Colors.green,
              ),
              title: Text(
                title,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black),
              ),
              subtitle: Text('Delivery: $date',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w300,
                      color: isDark ? Colors.white : Colors.black)),
              trailing: Text(
                price,
                style: GoogleFonts.manrope(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Enables horizontal scrolling
        controller: _scrollController,
        child: Center(
          child: Row(
            children: [
              card('Standard Shipping', '$formattedDate - $TformattedDate',
                  'FREE', 1, 0.0),
              SizedBox(width: 4),
              card('Same Day Delivery', 'Today', '\₹ 20.0', 2, 20.0),
              SizedBox(width: 4),
              card('Express Shipping', 'Under 30 minutes', '\₹ 30', 3, 30.0),
            ],
          ),
        ),
      ),
    );
  }
}

Stream<int> cartTotalPriceStream() {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
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
      int price = int.tryParse(data['price'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      int quantity = data['quantity'] ?? 1;
      total += price * quantity;
    }

    return total + (_selectedShippingPrice ?? 0).toInt();
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(OrdersPage());
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Please login to view your orders.'),
          ),
        ),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Orders(),
    );
  }
}

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  bool addressFilled = false;

  late Razorpay _razorpay;
  final PayGateway _payGateway = PayGateway();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late ScrollController _scrollController;
  late FocusNode searchFocusNode;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); 
    _loadAddressStatus();
    searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchFocusNode.dispose();

    super.dispose();
  }

  Future<void> createOrder(String paymentMethod) async {
    Future<Map<String, String>?> loadAddressFromPrefs() async {
      final prefs = await SharedPreferences.getInstance();
      final addressJson = prefs.getString('address');
      if (addressJson == null) return null;
      return Map<String, String>.from(jsonDecode(addressJson));
    }

    try {
      // Fetch address details
      final addressDetails = await loadAddressFromPrefs();
      if (addressDetails == null ||
          addressDetails.values.any((value) => value.isEmpty)) {
        throw Exception('Address details are incomplete or missing.');
      }

      double? latitude;
      double? longitude;

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled.');
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
          latitude = position.latitude;
          longitude = position.longitude;
        }
      } catch (e) {
        print('Location permissions or services not available: $e');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User is not logged in.');
      }

      final cartSnapshot = await _firestore
          .collection('userCart')
          .doc(user.uid)
          .collection('cart')
          .get();

      List<Map<String, dynamic>> products = cartSnapshot.docs.map((doc) {
        final productData = doc.data();
        return {
          'id': productData['id'],
          'name': productData['name'],
          'price': productData['price'],
          'image': productData['image'],
          'quantity': productData['quantity'],
          'brand': productData['brand'],
        };
      }).toList();

      if (products.isEmpty) {
        throw Exception('Cart is empty.');
      }

      final now = DateTime.now();
      final orderId = DateFormat(' hh:mm:ss a dd-MM-yyyy ').format(now);
      final totalPrice = await cartTotalPriceStream().first;  


      await _firestore.collection('Orders').doc(orderId).set({
        'deliveryCompleted': false,
        'orderId': orderId,
        'totalPrices': totalPrice,
        'latitude': latitude,
        'longitude': longitude,
        'customerDetails': addressDetails,
        'timestamp': DateTime.now().toIso8601String(),
        'paymentMethod': paymentMethod,
        'userName': user.displayName ?? 'Guest',
        'userId': user.uid,
        'products': products,
        'shipping price': _selectedShippingPrice,
        'instructions': instructionController.text,
        'shipping method': _selectedShippingMethod
      });

      print('Order created successfully.');
    } catch (e) {
      print('Error creating order: $e');
      if (ScaffoldMessenger.maybeOf(context) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating order: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadAddressStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final filled = prefs.getBool('addressFilled') ?? false;

    final loadedAddress = await loadAddressFromPrefs();
    setState(() {
      addressDetails = loadedAddress;
      addressFilled = filled &&
          loadedAddress != null &&
          loadedAddress.values.every((field) => field.isNotEmpty);
    });
  }


  void _onPaymentSuccess(String paymentId) {
    createOrder('Prepaid');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFFD0F3EA),
        title: const Text('Payment Successful'),
        content: Text('Payment ID: $paymentId'),
        actions: [
          // TextButton(
          //   onPressed: () => Navigator.pop(context),
          //   child: const Text('OK'),
          // ),
        ],
      ),
    );
  }

  void _onPaymentError(String errorMessage) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF90BEDE),
        title: const Text('Payment Failed'),
        content: Text(errorMessage),
        actions: [
          // TextButton(
          //   onPressed: () => Navigator.pop(context),
          //   child: const Text('Try Again'),
          // ),
        ],
      ),
    );
  }

  void _onExternalWallet(String walletName) {
    createOrder('Prepaid');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('External Wallet Selected'),
        content: Text('Wallet Name: $walletName'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return GestureDetector(
      onTap: () => searchFocusNode.unfocus(),
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: true,
            // backgroundColor: Color(0xFFF8F8F8),
            backgroundColor: isDark ? Color(0xFF121318) : Color(0xffffffff),
            body: SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(top: 15, left: 16, right: 16),
                      decoration: BoxDecoration(
                        color: MediaQuery.of(context).platformBrightness ==
                                Brightness.dark
                            ? Color(0xFF121318)
                            : Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 12,
                          ),
                          Text(
                            'Order Confirmation',
                            style: GoogleFonts.russoOne(
                              color:
                                  MediaQuery.of(context).platformBrightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 12,
                          )
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28.0, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: Colors.green,
                              child: Text('1',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            Text(
                              'Set Address',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: MediaQuery.of(context)
                                              .platformBrightness ==
                                          Brightness.light
                                      ? const Color(0xFF1A1A1A)
                                      : Colors.white),
                            ),
                            Row(
                              children: [
                                Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.grey, size: 18),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.grey, size: 18),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.grey, size: 18),
                              ],
                            ),
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: Colors.green,
                              child: Text('2',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            Text(
                              'Confirm Order',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: MediaQuery.of(context)
                                              .platformBrightness ==
                                          Brightness.light
                                      ? const Color(0xFF1A1A1A)
                                      : Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    AddressSummaryWidget(
                      onAddressUpdated: (updatedAddress) {
                        setState(() {
                          addressDetails = updatedAddress;
                          addressFilled = updatedAddress.values
                              .every((field) => field.isNotEmpty);
                        });
                      },
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'Shipping',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color:
                                  MediaQuery.of(context).platformBrightness ==
                                          Brightness.light
                                      ? const Color(0xFF1A1A1A)
                                      : Colors.white,
                            ),
                          ),
                        ),
                        ShippingOptions(
                          onShippingPriceChanged: (newPrice) {
                            setState(() {
                              _selectedShippingPrice = newPrice;
                            });
                          },
                        )
                      ],
                    ),
                    OrderList(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                'Any Delivery Instructions ?',
                                textAlign: TextAlign.start,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: MediaQuery.of(context)
                                              .platformBrightness ==
                                          Brightness.light
                                      ? const Color(0xFF1A1A1A)
                                      : Colors.white,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                child: Container(
                                  width: double.infinity,
                                  // Infinite width
                                  height:
                                      MediaQuery.of(context).size.height / 20 +
                                          35,
                                  // Fixed height
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.black45, width: 1.5),
                                    color: Colors.white, // Black background
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  // Add padding for content
                                  child: TextField(
                                    focusNode: searchFocusNode,

                                    controller: instructionController,
                                    style: const TextStyle(color: Colors.black),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Enter delivery instructions..😊 ',
                                      hintStyle: GoogleFonts.kanit(
                                          color: MediaQuery.of(context)
                                                      .platformBrightness ==
                                                  Brightness.light
                                              ? const Color(0xFF4A4A4A)
                                              : Colors.grey.shade700,
                                          fontWeight: FontWeight.w500),
                                      // Grey hint color
                                      border: InputBorder.none,
                                    ),
                                    maxLines: null, //
                                  ),
                                ),
                              ),
                            ),
                            // SizedBox(height: 100),
                          ],
                        )
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 12 + 100,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: isDark ? Color(0xFF101010) : Color(0xffffffff),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 12.0, right: 12, top: 10, bottom: 15),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text('Total :',
                                style: GoogleFonts.russoOne(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                child: StreamBuilder<int>(
                                  stream: cartTotalPriceStream(),
                                  builder: (context, snapshot) {
                                    final totalPrice = snapshot.data ?? 0;

                                    return AnimatedDigitWidget(
                                      prefix: '₹ ',
                                      value: totalPrice,
                                      duration:
                                          const Duration(milliseconds: 500),
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
                    ),
                    Container(
                      color: isDark ? Color(0xFF121318) : Color(0xffffffff),
                      height: MediaQuery.of(context).size.height / 12,
                      width: MediaQuery.of(context).size.width - 10,
                      child: ElevatedButton(
                        child: Text(
                          'Confirm Order',
                          style: GoogleFonts.russoOne(
                              fontWeight: FontWeight.w200,
                              color: Colors.white,
                              fontSize: 18),
                        ),
                        onPressed: () async {
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
                                      color: color ?? Colors.green.shade700,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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

                          searchFocusNode.unfocus();

                          final totalPrice = await cartTotalPriceStream().first;

                          return Future.delayed(Duration(milliseconds: 300),
                              () {
                            showModalBottomSheet(
                              backgroundColor:
                                  isDark ? Color(0xff323232) : Colors.white,
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              builder: (context) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'By proceeding you Accept our Terms and Conditions.'
                                            .padLeft(3),
                                        textAlign: TextAlign.start,
                                        style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            color: !isDark
                                                ? Color(0xff121212)
                                                : Colors.white,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Color(0xfff2e2ba),
                                            border: Border.all(
                                                color: MediaQuery.of(context)
                                                            .platformBrightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                                width: 1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ListTile(
                                            title: Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 15.0),
                                                child: Text(
                                                  "Cash on Delivery",
                                                  style: GoogleFonts.kanit(
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            onTap: () async {
                                              await createOrder(
                                                  'Cash on Delivery');

                                              Navigator.popUntil(
                                                  context,
                                                  (route) => route
                                                      .isFirst); // Pop until the first route
                                              Navigator.pushReplacement(
                                                context,
                                                PageTransition(
                                                  type: PageTransitionType
                                                      .leftToRight,
                                                  child: const Cart(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 0,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Color(0xffbaf2bb),
                                            border: Border.all(
                                                color: MediaQuery.of(context)
                                                            .platformBrightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                                width: 1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ListTile(
                                            title: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 15.0),
                                              child: Center(
                                                child: Text(
                                                  "Prepaid",
                                                  style: GoogleFonts.kanit(
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            onTap: () async {
                                              if (totalPrice > 0) {
                                                _payGateway.openCheckout(
                                                  amount: totalPrice * 100,
                                                  name:
                                                      'Neelkamal Books And Stationers',
                                                  description:
                                                      'Payment for items in cart',
                                                  prefillContact: '6268346287',
                                                  prefillEmail:
                                                      'sarthak8770@gmail.com',
                                                  onSuccess: _onPaymentSuccess,
                                                  onError: _onPaymentError,
                                                  onExternalWallet:
                                                      _onExternalWallet,
                                                );

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Let\'s Proceed!')),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Your cart is empty!')),
                                                );
                                              }
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20,)
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
