// // payment_service.dart


// import 'dart:math';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
//
// class PaymentService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   void handlePaymentSuccess(BuildContext context, PaymentSuccessResponse response) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('Payment Successful'),
//         content: Text('Payment ID: ${response.paymentId}'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('OK'),
//           ),
//         ],
//       ),
//     );
//     createOrder('Prepaid');
//
//     final user = _auth.currentUser;
//     if (user != null) {
//       _firestore
//           .collection('userCart')
//           .doc(user.uid)
//           .collection('cart')
//           .get()
//           .then((snapshot) {
//         for (var doc in snapshot.docs) {
//           doc.reference.delete();
//         }
//       });
//     }
//   }
//
//   void handlePaymentError(BuildContext context, PaymentFailureResponse response) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('Payment Failed'),
//         content: Text('${response.message}'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Try Again'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void handleExternalWallet(BuildContext context, ExternalWalletResponse response) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('External Wallet Selected'),
//         content: Text('Wallet Name: ${response.walletName}'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Stream<int> cartTotalPriceStream() {
//     final user = _auth.currentUser;
//     if (user == null) return Stream.value(0);
//
//     return _firestore
//         .collection('userCart')
//         .doc(user.uid)
//         .collection('cart')
//         .snapshots()
//         .map((snapshot) {
//       int total = 0;
//       for (var doc in snapshot.docs) {
//         final data = doc.data();
//         int price = int.parse(data['price'].replaceAll('₹', ''));
//         int quantity = data['quantity'];
//         total += price * quantity;
//       }
//       return total;
//     });
//   }
//
//   Future<void> createOrder(String paymentMethod) async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         throw Exception('Location services are disabled.');
//       }
//
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.deniedForever) {
//           throw Exception('Location permissions are permanently denied.');
//         }
//       }
//
//       if (permission == LocationPermission.denied) {
//         throw Exception('Location permissions are denied.');
//       }
//
//       Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);
//
//       final userName = FirebaseAuth.instance.currentUser;
//       String name =
//       userName != null ? (userName.displayName ?? 'Guest') : 'Guest';
//
//       await FirebaseFirestore.instance.collection('Orders').doc(name).set({
//         'latitude': position.latitude,
//         'longitude': position.longitude,
//         'timestamp': DateTime.now().toIso8601String(),
//         'paymentMethod': paymentMethod,
//         'userName': name,
//         'userId': userName?.uid,
//       });
//
//       print('User location saved successfully.');
//     } catch (e) {
//       print('Error saving location: $e');
//     }
//   }
//
//   void updateQuantity(String productId, int newQuantity) async {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     final cartRef = _firestore
//         .collection('userCart')
//         .doc(user.uid)
//         .collection('cart')
//         .doc(productId);
//
//     if (newQuantity > 0) {
//       await cartRef.update({'quantity': newQuantity});
//     } else {
//       await cartRef.delete();
//     }
//   }
//
//   Color getRandomColor() {
//     Random random = Random();
//     return Color.fromARGB(
//       255,
//       random.nextInt(256),
//       random.nextInt(256),
//       random.nextInt(256),
//     ).withOpacity(0.1);
//   }
// }
///sdfsdfsd
///
/// // Expanded(
//             //   child: StreamBuilder<DocumentSnapshot>(
//             //     stream: cartRef.snapshots(),
//             //     builder: (context, snapshot) {
//             //       if (snapshot.connectionState == ConnectionState.waiting) {
//             //         return const Center(child: CircularProgressIndicator());
//             //       }
//             //       if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
//             //         return Center(
//             //           child: Text(
//             //             'No orders yet.',
//             //             style: GoogleFonts.macondo(),
//             //           ),
//             //         );
//             //       }
//             //
//             //       final orderData =
//             //           snapshot.data!.data() as Map<String, dynamic>;
//             //
//             //       // Access the products array
//             //       final products =
//             //           orderData['products'] as List<dynamic>? ?? [];
//             //
//             //       // Create widgets for each product
//             //       final productWidgets = products.map((product) {
//             //         final productData = product as Map<String, dynamic>;
//             //         final name = productData['name'] ?? 'Unnamed Product';
//             //
//             //         // Parse price and quantity, handling String or num cases
//             //         final price = productData['price'] is num
//             //             ? (productData['price'] as num).toDouble()
//             //             : double.tryParse(
//             //                     productData['price']?.toString() ?? '0') ??
//             //                 0.0;
//             //
//             //         final quantity = productData['quantity'] is num
//             //             ? (productData['quantity'] as num).toInt()
//             //             : int.tryParse(
//             //                     productData['quantity']?.toString() ?? '0') ??
//             //                 0;
//             //
//             //         return Card(
//             //           color: Color(0xFFDFFDFF).withOpacity(0.3),
//             //           borderOnForeground: true,
//             //           margin: const EdgeInsets.symmetric(
//             //               vertical: 8, horizontal: 16),
//             //           child: ListTile(
//             //             title: Text(name,                                       style: GoogleFonts.kanit(
//             //               color: MediaQuery.of(context)
//             //                   .platformBrightness ==
//             //                   Brightness.light
//             //                   ? Color(0xFF1A1A1A)
//             //                   : Colors.white,
//             //               fontSize: 18,
//             //               fontWeight: FontWeight.w700,
//             //             )),
//             //             subtitle: Text(                                      style: GoogleFonts.kanit(
//             //               fontSize: 18,
//             //               color: Colors.green,
//             //               fontWeight: FontWeight.w700,
//             //             ),
//             //                 'Price: ${price.toStringAsFixed(2)} \nQuantity: ${quantity}'),
//             //             trailing: Text(
//             //               '₹ ${(price * quantity).toStringAsFixed(2)}',
//             //                 style: GoogleFonts.kanit(
//             //                   color: MediaQuery.of(context)
//             //                       .platformBrightness ==
//             //                       Brightness.light
//             //                       ? Color(0xFF1A1A1A)
//             //                       : Colors.white,
//             //                   fontSize: 18,
//             //                   fontWeight: FontWeight.w700,
//             //                 )                        ),
//             //           ),
//             //         );
//             //       }).toList();
//             //
//             //       return ListView(children: productWidgets );
//             //     },
//             //   ),
//             // ),
/// dsfsd
// Expanded(
// child: StreamBuilder<DocumentSnapshot>(
// stream: cartRef.snapshots(),
// builder: (context, snapshot) {
// if (snapshot.connectionState == ConnectionState.waiting) {
// return const Center(child: CircularProgressIndicator());
// }
// if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
// return Center(
// child: Text(
// 'No orders yet.',
// style: GoogleFonts.macondo(),
// ),
// );
// }
//
// final orderData =
// snapshot.data!.data() as Map<String, dynamic>;
//
// // Access the products array
// final products =
// orderData['products'] as List<dynamic>? ?? [];
//
// // Create widgets for each product
// final productWidgets = products.map((product) {
// final productData = product as Map<String, dynamic>;
// final name = productData['name'] ?? 'Unnamed Product';
//
// // Parse price and quantity, handling String or num cases
// final price = productData['price'] is num
// ? (productData['price'] as num).toDouble()
//     : double.tryParse(
// productData['price']?.toString() ?? '0') ??
// 0.0;
//
// final quantity = productData['quantity'] is num
// ? (productData['quantity'] as num).toInt()
//     : int.tryParse(
// productData['quantity']?.toString() ?? '0') ??
// 0;
//
// return Card(
// color: Color(0xFFDFFDFF).withOpacity(0.3),
// borderOnForeground: true,
// margin: const EdgeInsets.symmetric(
// vertical: 8, horizontal: 16),
// child: ListTile(
// title: Text(name,                                       style: GoogleFonts.kanit(
// color: MediaQuery.of(context)
//     .platformBrightness ==
// Brightness.light
// ? Color(0xFF1A1A1A)
//     : Colors.white,
// fontSize: 18,
// fontWeight: FontWeight.w700,
// )),
// subtitle: Text(                                      style: GoogleFonts.kanit(
// fontSize: 18,
// color: Colors.green,
// fontWeight: FontWeight.w700,
// ),
// 'Price: ${price.toStringAsFixed(2)} \nQuantity: ${quantity}'),
// trailing: Text(
// '₹ ${(price * quantity).toStringAsFixed(2)}',
// style: GoogleFonts.kanit(
// color: MediaQuery.of(context)
//     .platformBrightness ==
// Brightness.light
// ? Color(0xFF1A1A1A)
//     : Colors.white,
// fontSize: 18,
// fontWeight: FontWeight.w700,
// )                        ),
// ),
// );
// }).toList();
//
// return ListView(children: productWidgets );
// },
// ),
// )
// return Container(
//   margin: const EdgeInsets.symmetric(
//       horizontal: 8.0),
//   decoration: BoxDecoration(
//
//     border: Border.all(width: 1.8, color: Colors.grey.shade300),
//     borderRadius:
//         BorderRadius.circular(16),
//     color: _getRandomColor(),
//   ),
//   child: Padding(
//     padding: const EdgeInsets.all(16.0),
//     child: Row(
//       crossAxisAlignment:
//           CrossAxisAlignment.center,
//       children: [
//         // Product Image
//         Expanded(
//           child: Container(
//             // width: 80,
//             // height: 80,
//             decoration: BoxDecoration(
//               borderRadius:
//                   BorderRadius.circular(
//                       8),
//               color: Colors.grey.shade200,
//             ),
//             child: productData['image'] !=
//                     null
//                 ? ClipRRect(
//                     borderRadius:
//                         BorderRadius
//                             .circular(8),
//                     child: Image.network(
//                       productData[
//                           'image'],
//                       fit: BoxFit.cover,
//                     ),
//                   )
//                 : const Icon(Icons.image,
//                     size: 40),
//           ),
//         ),
//         const SizedBox(width: 16),
//         // Product Details
//         Expanded(
//           child: Column(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               if (brand != null)
//                 Text(
//                   brand,
//                   style:
//                       GoogleFonts.kanit(
//                     fontSize: 14,
//                     fontWeight:
//                         FontWeight.bold,
//                     color: Colors
//                         .grey.shade700,
//                   ),
//                 ),
//               Text(
//                 name,
//                 style: GoogleFonts.kanit(
//                   fontSize: 19,
//                   fontWeight:
//                       FontWeight.bold,
//                   color: MediaQuery.of(
//                                   context)
//                               .platformBrightness ==
//                           Brightness.light
//                       ? const Color(
//                           0xFF1A1A1A)
//                       : Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 0),
//               // Color and Size (if available)
//               Column(
//                 crossAxisAlignment:
//                     CrossAxisAlignment
//                         .start,
//                 children: [
//                   // Color
//
//                   SizedBox(
//                       height: 2), // Size
//                   if (size != null)
//                     Row(
//                       mainAxisAlignment:
//                           MainAxisAlignment
//                               .spaceBetween,
//                       children: [
//                         Text(
//                           'Size:',
//                           style:
//                               GoogleFonts
//                                   .kanit(
//                             fontSize: 14,
//                             color: Colors
//                                 .black,
//                             fontWeight:
//                                 FontWeight
//                                     .w700,
//                           ),
//                         ),
//                         Text(
//                           '$size',
//                           style:
//                               GoogleFonts
//                                   .kanit(
//                             fontSize: 14,
//                             color: Colors
//                                 .black,
//                             fontWeight:
//                                 FontWeight
//                                     .w700,
//                           ),
//                         ),
//                       ],
//                     ),
//                   SizedBox(
//                       height: 2), // Price
//                   Row(
//                     mainAxisAlignment:
//                         MainAxisAlignment
//                             .spaceBetween,
//                     children: [
//                       Text(
//                         'Price:',
//                         style: GoogleFonts
//                             .kanit(
//                           fontSize: 14,
//                           color: Colors
//                               .black,
//                           fontWeight:
//                               FontWeight
//                                   .w700,
//                         ),
//                       ),
//                       Text(
//                         '₹ $price',
//                         style: GoogleFonts
//                             .kanit(
//                           fontSize: 14,
//                           color: Colors
//                               .black,
//                           fontWeight:
//                               FontWeight
//                                   .w700,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(
//                       height:
//                           2), // Quantity
//                   Row(
//                     mainAxisAlignment:
//                         MainAxisAlignment
//                             .spaceBetween,
//                     children: [
//                       Text(
//                         'Quantity:',
//                         style: GoogleFonts
//                             .kanit(
//                           fontSize: 14,
//                           color: Colors
//                               .black,
//                           fontWeight:
//                               FontWeight
//                                   .w700,
//                         ),
//                       ),
//                       Text(
//                         '$quantity',
//                         style: GoogleFonts
//                             .kanit(
//                           fontSize: 20,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(
//                       height:
//                           2), // Subtotal
//                   Row(
//                     mainAxisAlignment:
//                         MainAxisAlignment
//                             .spaceBetween,
//                     children: [
//                       Text(
//                         'Subtotal:',
//                         style: GoogleFonts
//                             .kanit(
//                           fontSize: 16,
//                           fontWeight:
//                               FontWeight
//                                   .bold,
//                           color: Colors
//                               .green,
//                         ),
//                       ),
//                       Text(
//                         '₹${subtotal.toStringAsFixed(2)}',
//                         style: GoogleFonts
//                             .kanit(
//                           fontSize: 16,
//                           fontWeight:
//                               FontWeight
//                                   .bold,
//                           color: Colors
//                               .green,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               )
//             ],
//           ),
//         ),
//       ],
//     ),
//   ),
// );