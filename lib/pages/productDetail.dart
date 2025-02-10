import 'dart:math';

import 'package:action_slider/action_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:wx_text/wx_text.dart';

void showTopSnackBar(BuildContext context, String message, {Color? color}) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 10, // Just below the status bar
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? Colors.green.shade700, // Vibrant green
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.check_circle, color: Colors.greenAccent),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Remove the snack bar after 2 seconds
  Future.delayed(Duration(seconds: 2), () {
    overlayEntry.remove();
  });
}

// Function to add product to the cart
Future<void> addToCart(Map<String, dynamic> product) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('User not logged in');
  }

  final cartRef = FirebaseFirestore.instance
      .collection('userCart')
      .doc(user.uid)
      .collection('cart');

  // Check if the product already exists in the cart by its 'id'
  final cartDoc = await cartRef.where('id', isEqualTo: product['id']).get();

  if (cartDoc.docs.isNotEmpty) {
    // If product exists, update the quantity
    final existingCartItem = cartDoc.docs.first;
    await existingCartItem.reference.update({
      'quantity': FieldValue.increment(1),
    });
  } else {
    await cartRef.add({
      'id': product['id'],
      'name': product['name'],
      'price': product['price'],
      'image': product['image'],
      'brand': product['brand'],
      'quantity': 1,
    });
  }
}

class ProductDetail extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetail({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Color? _dominantColor;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Define animations for fade and slide
    _fadeAnimation = CurvedAnimation(
        parent: _animationController, curve: Curves.elasticInOut);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animationController, curve: Curves.elasticInOut));

    // Start the animations
    _animationController.forward();

    // Extract the dominant color from the image
    _getDominantColor();
  }

  Animation<Color?>? _colorAnimation;

  void initializeColorAnimation(
      TickerProvider vsync, Color? startColor, Color? endColor) {
    _animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 500), // Transition duration
    );

    _colorAnimation = ColorTween(
      begin: startColor ?? Colors.blue.withOpacity(0.6), // Initial color
      end: endColor ?? Colors.blue.withOpacity(0.6), // Target color
    ).animate(_animationController!);

    _animationController!.forward();
  }

  Color? getAnimatedColor() => _colorAnimation?.value;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getDominantColor() async {
    final imageProvider = NetworkImage(
        widget.product['image'] ?? ''); // Provide a fallback image URL
    final PaletteGenerator palette =
        await PaletteGenerator.fromImageProvider(imageProvider);

    setState(() {
      _dominantColor = palette.dominantColor?.color ?? Colors.white;
    });
  }

  Future<void> _handleAddToCart() async {
    final product = widget.product;
    try {
      await addToCart(product);
      showTopSnackBar(
        context,
        '${product['name']} added to cart!',
        color: Colors.green.shade700, // Vibrant color for success
      );
    } catch (e) {
      print('Error is ATC');
      print(e.toString());
      showTopSnackBar(
        context,
        'Failed to add to cart: $e',
        color: Colors.red.shade700, // Vibrant color for error
      );
    }
  }

  Color _getRandomColor() {
    Random random = Random();

    // Generate RGB values in the range of 180 to 255 for vibrant colors
    return Color.fromARGB(
      255, 180 + random.nextInt(76), // R: High brightness
      180 + random.nextInt(76), // G: High brightness
      180 + random.nextInt(76), // B: High brightness
    ).withOpacity(0.7); // High opacity for vividness
  }

  @override
  Widget build(BuildContext context) {
    print('Product from PD'); // Ensure correct data is passed.

    print(widget.product); // Ensure correct data is passed.

    final double imageHeight = MediaQuery.of(context).size.height * 0.5;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 3000),
            // Adjust duration for the transition
            curve: Curves.easeInOut,
            // Smooth easing curve
            color: (_dominantColor ?? _getRandomColor()).withOpacity(0.15),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: Align(
              alignment: Alignment.topCenter,
              child: Hero(
                tag: widget.product['id'] ?? 'defaultTag',
                child: Container(
                  height: imageHeight * 0.7, // Scale the image to be smaller
                  width: imageHeight * 0.7, // Scale the image to be smaller
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(widget.product['image'] ?? ''),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Overlapping Rounded Container with fade and slide animations
          Positioned(
            top: imageHeight - 50,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  child: Container(
                    height:
                        MediaQuery.of(context).size.height - imageHeight + 50,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                          horizontal:
                              BorderSide(color: Colors.black54, width: 3)),
                      color: Colors.white.withOpacity(0.5),
                      // Semi-transparent background
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 50,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 15),
                          AnimatedContainer(
                            // width: 200,
                            duration: const Duration(milliseconds: 1000),
                            // Transition duration
                            curve: Curves.easeInOut,
                            // Smooth easing curve
                            decoration: BoxDecoration(
                              border: Border.all(
                                  width: 0.8, color: Color(0xFFAEB3BD)),
                              color: (_dominantColor?.withOpacity(0.7) ??
                                  _getRandomColor().withOpacity(0.6)),
                              // Background color with transition
                              borderRadius: BorderRadius.all(Radius.circular(
                                  80)), // Match the button's corner radius
                            ),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                // Transparent as it's handled by the container
                                side: BorderSide(color: Colors.transparent),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              onPressed: () {},
                              child: Text(
                                'See more from ' + widget.product['brand'],
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Product Name
                          Row(children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                widget.product['name'] ?? 'Product',
                                style: GoogleFonts.bungee(
                                  color: Color(0xff141414),
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 10),

                          // Description Section with background color
                          Container(
                            color: const Color(0xFFFFFAF1),
                            padding: const EdgeInsets.all(10),
                            child: WxAnimatedText(
                              repeat: 0,
                              mirror: true,
                              reverse: true,
                              curve: Curves.easeInQuint,
                              delay: const Duration(milliseconds: 300),
                              duration: const Duration(milliseconds: 100),
                              reverseDelay: const Duration(milliseconds: 300),
                              reverseDuration:
                                  const Duration(milliseconds: 7000),
                              transition: WxAnimatedText.typing(trails: '_'),
                              child: WxText.bodyLarge(
                                minLines: 3,
                                widget.product['description'] ??
                                    'No description available',
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),

                          // Price Information
                          Row(
                            children: [
                              const SizedBox(width: 5),
                              Text(
                                "Price : ₹ ${widget.product['price']}",
                                style: GoogleFonts.russoOne(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  // color: _dominantColor != null
                                  //     ? _dominantColor!
                                  //         .withOpacity(0.9) // More vibrant
                                  //     : Colors.black.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ActionSlider.dual(
                    toggleColor: _dominantColor?.withOpacity(1) ??
                        _getRandomColor().withOpacity(0.6),
                    backgroundBorderRadius: BorderRadius.circular(40.0),
                    foregroundBorderRadius: BorderRadius.circular(40.0),
                    height: 70,
                    width: MediaQuery.of(context).size.width - (8 * 2),
                    backgroundColor: Colors.white,
                    startChild: Text(
                      "Wishlist",
                      style: GoogleFonts.outfit(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    endChild: Text(
                      "Add to Cart",
                      style: GoogleFonts.outfit(
                          fontSize: 20,
                          // color: _dominantColor?.withOpacity(1) ??
                          //     Colors.blue.withOpacity(0.6),
                          fontWeight: FontWeight.w800),
                    ),
                    icon: Center(
                      child: Transform.rotate(
                          angle: 0.5 * pi,
                          child: const Icon(
                            Icons.unfold_more_rounded,
                            size: 28.0,
                            color: Colors.black,
                          )),
                    ),
                    startAction: (controller) async {
                      controller.loading(); //starts loading animation
                      _handleAddToCart();
                      await Future.delayed(const Duration(seconds: 1));
                      controller.success(); //starts success animation
                      await Future.delayed(const Duration(seconds: 1));
                      controller.reset(); //resets the slider
                    },
                    endAction: (controller) async {
                      controller.loading(); //starts loading animation
                      _handleAddToCart();
                      await Future.delayed(const Duration(seconds: 1));
                      controller.success(); //starts success animation
                      await Future.delayed(const Duration(seconds: 1));
                      controller.reset(); //resets the slider
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
