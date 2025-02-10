import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget buildPincodeField() {
  return Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.grey[200], // Light background
      borderRadius: BorderRadius.circular(5), // Rounded corners
      border: Border.all(color: Colors.grey[400]!), // Border color
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: TextField(
      keyboardType: TextInputType.number,
      controller: pincodeController,
      decoration: InputDecoration(
        labelText: 'Pincode',
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
        hintText: '484001',
        border: InputBorder.none, // No default border
      ),
    ),
  );
}

Widget buildNameField() {
  return Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: Colors.grey[400]!),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: TextField(
      controller: nameController,
      decoration: InputDecoration(
        labelText: 'Name',
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
        hintText: 'Enter your name...',
        border: InputBorder.none,
      ),
    ),
  );
}

Widget buildPhoneNumberField() {
  return Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: Colors.grey[400]!),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: TextField(
      keyboardType: TextInputType.phone,
      controller: phoneController,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
        hintText: 'Enter your phone number...',
        border: InputBorder.none,
      ),
    ),
  );
}

Widget buildStreetWardAddressField() {
  return Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: Colors.grey[400]!),
    ),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: TextField(
      controller: addressController,
      decoration: InputDecoration(
        labelText: 'Street/Ward Address',
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
        hintText: 'Enter your street or ward address...',
        border: InputBorder.none,
      ),
    ),
  );
}

Map<String, String>? addressDetails;
final nameController = TextEditingController();
final phoneController = TextEditingController();
final addressController = TextEditingController();
final pincodeController = TextEditingController();

Future<void> saveAddressToPrefs(Map<String, String> addressDetails) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('saved_address', jsonEncode(addressDetails));
}

Future<Map<String, String>?> loadAddressFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final addressJson = prefs.getString('saved_address');
  if (addressJson != null) {
    return Map<String, String>.from(jsonDecode(addressJson));
  }
  return null;
}

Future<void> showAddressDialog(
    BuildContext context, Function(Map<String, String>) onSubmit,
    {Map<String, String>? initialAddressDetails}) async {
  nameController.text = initialAddressDetails?['name'] ?? '';
  phoneController.text = initialAddressDetails?['phone'] ?? '';
  addressController.text = initialAddressDetails?['address'] ?? '';
  pincodeController.text = initialAddressDetails?['pincode'] ?? '';

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        // Alert dialog background color
        title: Text(
          initialAddressDetails == null
              ? 'Save Delivery Details'
              : 'Edit Delivery Details',
          textAlign: TextAlign.center,
          style: GoogleFonts.kanit(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildNameField(),
              SizedBox(height: 10),
              buildPhoneNumberField(),
              SizedBox(height: 10),
              buildStreetWardAddressField(),
              SizedBox(height: 10),
              buildPincodeField(),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    // Background color for Cancel
                    side: BorderSide(color: Color(0xFFF7CCEE), width: 2),
                    // Thick black border
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(5), // Rectangular button
                    ),
                    shadowColor: Colors.black,
                    // Shadow color
                    elevation: 0, // Removes blur
                  ),
                  onPressed: () {
                    addressDetails == null;
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.kanit(
                      fontWeight: FontWeight.w700,
                      // fontSize: 16,
                      color: Colors.black, // Black text color
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFABF348),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    shadowColor: Colors.black,
                    elevation: 0,
                  ),
                  onPressed: () {
                    void showTopSnackBar(BuildContext context, String message,
                        {Color? color}) {
                      final overlay = Overlay.of(context);
                      final overlayEntry = OverlayEntry(
                        builder: (context) => Positioned(
                          top: MediaQuery.of(context).padding.top + 20,
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
                    

                    if (nameController.text.length < 6) {
                      showTopSnackBar(
                          context, "Name must be at least 6 characters long",
                          color: Colors.red);
                      return;
                    }
                    // if (pincodeController.text != 484001.toInt()) {
                    //   showTopSnackBar(
                    //       context, "Delivery Outside Shahdol is Not Eligible Yet.",
                    //       color: Colors.red);
                    //   return;
                    // }
                    if (phoneController.text.length < 10 ||
                        phoneController.text.length > 10) {
                      showTopSnackBar(context,
                          "Phone number must be at least 10 digits long",
                          color: Colors.red);
                      return;
                    }
                    if (addressController.text.length < 16) {
                      showTopSnackBar(context,
                          "Address must be at least 16 characters long",
                          color: Colors.red);
                      return;
                    }
                    if (pincodeController.text.length < 6 ||
                        pincodeController.text.length > 6 ) {
                      showTopSnackBar(
                          context, "Pincode must be at least 6 digits long",
                          color: Colors.red);
                      return;
                    }

                    final updatedDetails = {
                      'name': nameController.text,
                      'phone': phoneController.text,
                      'address': addressController.text,
                      'pincode': pincodeController.text,
                    };
                    onSubmit(updatedDetails);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Submit',
                    style: GoogleFonts.kanit(
                      fontWeight: FontWeight.w800,
                      color: Colors.white, // White text color
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class AddressSummaryWidget extends StatefulWidget {
  final Function(Map<String, String>) onAddressUpdated;

  const AddressSummaryWidget({required this.onAddressUpdated, Key? key})
      : super(key: key);

  @override
  _AddressSummaryWidgetState createState() => _AddressSummaryWidgetState();
}

class _AddressSummaryWidgetState extends State<AddressSummaryWidget> {
  Map<String, String>? addressDetails;
  bool addressFilled = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final loadedAddress = await loadAddressFromPrefs();
    final isAddressFilled = loadedAddress != null &&
        loadedAddress.values.every((field) => field.isNotEmpty);

    setState(() {
      addressDetails = loadedAddress;
      addressFilled = isAddressFilled;
    });

    // Notify parent widget
    widget.onAddressUpdated(addressDetails ?? {});
  }

  Future<void> saveAddressToPrefs(Map<String, String> address) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('address', jsonEncode(address));
  }

  Future<Map<String, String>?> loadAddressFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final addressJson = prefs.getString('address');
    if (addressJson == null) return null;
    return Map<String, String>.from(jsonDecode(addressJson));
  }

  Future<void> _saveAndUpdateAddress(Map<String, String> updatedAddress) async {
    await saveAddressToPrefs(updatedAddress);

    final isAddressFilled =
        updatedAddress.values.every((field) => field.isNotEmpty);

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('addressFilled', !isAddressFilled);

    setState(() {
      addressDetails = updatedAddress;
      addressFilled = isAddressFilled;
    });

    widget.onAddressUpdated(updatedAddress);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        showAddressDialog(
          context,
          (submittedAddress) {
            _saveAndUpdateAddress(submittedAddress);
          },
          initialAddressDetails: addressDetails,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Dismissible(
          behavior: HitTestBehavior.opaque,
          key: ValueKey(addressDetails),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) async {
            setState(() {
              addressDetails = null;
              addressFilled = false;
            });

            // Clear saved address in SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            prefs.remove('address');
            prefs.setBool('addressFilled', false);

            // Notify parent widget
            widget.onAddressUpdated({});
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            color: Color(0xFFF2BAC9),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF0E0F10) : Color(0xffffffff),
              borderRadius: addressDetails == null
                  ? BorderRadius.circular(5.0)
                  : BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 1,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: addressDetails == null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_location_alt, color: Colors.green),
                      SizedBox(width: 10),
                      Text(
                        'Save Address',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              !isDark ? Color(0xFF0E0F10) : Color(0xffffffff),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.location_on, color: Colors.green),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 30.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${addressDetails!['name']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: !isDark
                                      ? Color(0xFF0E0F10)
                                      : Color(0xffffffff),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ph: ${addressDetails!['phone']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: !isDark
                                      ? Color(0xFF0E0F10)
                                      : Color(0xffffffff),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '${addressDetails!['address']}, Pincode: ${addressDetails!['pincode']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: !isDark
                                      ? Color(0xFF0E0F10)
                                      : Color(0xffffffff),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class OrderList extends StatefulWidget {
  @override
  _OrderList createState() => _OrderList();
}

class _OrderList extends State<OrderList> {
  final _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  List<Color> dominantColors = [];
  bool isLoadingColors = true;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _preloadDominantColors(List<dynamic> products) async {
    dominantColors = await Future.wait(
      products.map((product) async {
        final imageProvider = NetworkImage(product['image'] ?? '');
        final palette = await PaletteGenerator.fromImageProvider(imageProvider);
        return palette.dominantColor?.color ?? Colors.white;
      }),
    );
    setState(() {
      isLoadingColors = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartRef =
        _firestore.collection('userCart').doc(user?.uid).collection('cart');

    return Container(
      child: StreamBuilder<QuerySnapshot>(
        stream: cartRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SpinKitFadingCube(
                color: Colors.blue,
                size: 20,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No products in your cart.',
                style: GoogleFonts.macondo(),
              ),
            );
          }

          final products = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': data['id'],
              'name': data['name'],
              'price': data['price'],
              'image': data['image'],
              'quantity': data['quantity'],
              'brand': data['brand'],
            };
          }).toList();

          if (isLoadingColors) {
            _preloadDominantColors(products);
            return Center(
              child: SpinKitDoubleBounce(
                color: Colors.blue,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Item Detail',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: MediaQuery.of(context).platformBrightness ==
                            Brightness.light
                        ? const Color(0xFF1A1A1A)
                        : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Horizontal Product List
              SizedBox(
                height: 420,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 1),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final productData = products[index];
                    final color = dominantColors.isNotEmpty &&
                            index < dominantColors.length
                        ? dominantColors[index].withOpacity(0.1)
                        : _getRandomColor();

                    final name = productData['name'] ?? 'Unnamed Product';
                    final brand = productData['brand'] ?? 'Best One';
                    final price = double.tryParse(
                            productData['price']?.toString() ?? '0') ??
                        0.0;
                    final quantity = int.tryParse(
                            productData['quantity']?.toString() ?? '0') ??
                        0;
                    final subtotal = price * quantity;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1.8,
                          color: Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(0),
                        color: color,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                              ),
                              child: productData['image'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        productData['image'],
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.image, size: 40),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              brand,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.light
                                        ? const Color(0x64121212)
                                        : Colors.grey,
                              ),
                            ),
                            Text(
                              name,
                              style: GoogleFonts.outfit(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.light
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Price:',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    color: MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.light
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white,
                                  ),
                                ),
                                Text(
                                  '₹ $price',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    color: MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.light
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Quantity:',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    color: MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.light
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white,
                                  ),
                                ),
                                Text(
                                  '$quantity',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    color: MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.light
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal:',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.light
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white,
                                  ),
                                ),
                                Text(
                                  '₹${subtotal.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
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
  ).withOpacity(0.1); // High opacity for vividness
}
