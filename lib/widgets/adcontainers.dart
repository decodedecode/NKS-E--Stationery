import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nks/pages/productDetail.dart';

class DynamicAdContainers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(

      future: FirebaseFirestore.instance.collection('hometags').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: SpinKitFadingCube(
            color: Colors.blue.shade50,
            size: 20,
          ));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No data available'));
        }

        List<Widget> adContainerWidgets = [];
        for (var doc in snapshot.data!.docs) {
          String docId = doc.id;

          adContainerWidgets.add(Adcontainers(docid: docId));
        }

        return Column(
          children: adContainerWidgets,
          spacing: 20,
        );
      },
    );
  }
}

///

class Adcontainers extends StatefulWidget {
  final String docid;

  const Adcontainers({super.key, required this.docid});

  @override
  State<Adcontainers> createState() => _AdcontainersState();
}

class _AdcontainersState extends State<Adcontainers>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> products = [];

  String tag = 'Loading..';
  String tag2 = 'Loading..';

  Future<void> fetchTagAndFetchProductsByType() async {
    try {
      // Fetch the document from Firestore
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('hometags')
          .doc(widget.docid)
          .get();

      // Safely access fields with null checks
      String fetchedTag = doc.data()?['label'] ?? "Products for you";
      String fetchedTag2 = doc.data()?['product'] ?? "Default";

      setState(() {
        tag = fetchedTag;
        tag2 = fetchedTag2;
      });

      await fetchByType(tag2);
    } catch (e) {
      // Handle errors gracefully
      setState(() {
        tag = "Best Products";
        tag2 = "Default"; // Ensure tag2 has a fallback value
      });
      print("Error fetching data: $e");
    }
  }

  Future<void> fetchByType(String type) async {
    List<Map<String, dynamic>> allProducts = [];

    try {
      QuerySnapshot itemsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('items')
          .where('type', isEqualTo: type)
          .get();

      // Loop through each document and map the data
      for (var itemDoc in itemsSnapshot.docs) {
        var productData = itemDoc.data() as Map<String, dynamic>;
        allProducts.add({
          'id': itemDoc.id, // Including the product ID
          'name': productData['name'],
          'price': productData['price'].toString(),
          'stock': productData['stock'].toString(),
          'type': productData['type'],
          'brand': productData['brand'],
          'image': productData['image'],
          'description': productData['description'],
        });
      }

      setState(() {
        products = allProducts;
        print("Total products fetched for type '$type': ${products.length}");
      });
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  @override
  void initState() {
    fetchTagAndFetchProductsByType();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        color: _getRandomColor(),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Divider(
                    color: Colors.black,
                  ),
                )),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        tag,
                        style: GoogleFonts.russoOne(
                          color: Color(0xFF333333).withOpacity(1),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Divider(
                    color: Colors.black,
                  ),
                )),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: products.map((product) {

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Stack(
                          children: [
                            GestureDetector(
                       // Debugging purpose to verify data structure.

                          onTap: () {
                            print('Product'+
                                '$product');                                 Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      try {
                                        return ProductDetail(
                                            product:
                                                product); // Pass the product data here
                                      } catch (e) {
                                        print('Navigation error: $e');
                                        return Scaffold(
                                          body: Center(
                                            child: Text(
                                              'Error loading product details.',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.red),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: screenWidth * 0.45,
                                  minWidth: screenWidth * 0.4,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xffffffff),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        width: 1.2, color: Colors.black),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: CachedNetworkImage(
                                            imageUrl: product['image'] ??
                                                'https://via.placeholder.com/150',
                                            fit: BoxFit.cover,
                                            height: 150,
                                            width: double.infinity,
                                            placeholder: (context, url) =>
                                                SpinKitDoubleBounce(
                                              size: 30,
                                              color: Colors.blue,
                                            ),
                                            errorWidget:
                                                (context, url, error) => Icon(
                                                    Icons.error,
                                                    color: Colors.red),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0, vertical: 4.0),
                                        child: AutoSizeText(
                                          product['name'] ?? 'Unnamed Product',
                                          maxLines: 1,
                                          style: GoogleFonts.russoOne(
                                            fontWeight: FontWeight.w600,
                                            color:
                                                Colors.black.withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0, vertical: 2.0),
                                        child: AutoSizeText(
                                          product['description'] ??
                                              'No description available',
                                          style: GoogleFonts.kanit(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12.0, vertical: 4),
                                            child: Text(
                                              '₹ ${product['price']}',
                                              style: GoogleFonts.russoOne(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xff068663),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 14.0),
                                            child: AutoSizeText(
                                              'Check Out',
                                              style: GoogleFonts.russoOne(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black
                                                    .withOpacity(0.8),
                                              ),
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
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
  ).withOpacity(0.7); // High opacity for vividness
}

