import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nks/pages/productDetail.dart';

class CatalogList extends StatelessWidget {
  const CatalogList({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Catalog(selectedCategories: []),
    );
  }
}

class Catalog extends StatefulWidget {
  const Catalog({super.key, required this.selectedCategories});

  final List<String> selectedCategories;

  @override
  State<Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<Catalog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true;
  bool hasError = false;
  String searchQuery = "";
  late FocusNode searchFocusNode;

  @override
  void initState() {
    super.initState();
    searchFocusNode = FocusNode();
    fetchProducts(widget.selectedCategories);
  }

  @override
  void dispose() {
    searchFocusNode.dispose();
    super.dispose();
  }

  void sortProducts(String criteria) {
    setState(() {
      if (criteria == "A-Z") {
        filteredProducts.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (criteria == "Z-A") {
        filteredProducts.sort((a, b) => b['name'].compareTo(a['name']));
      } else if (criteria == "Price Low to High") {
        filteredProducts.sort((a, b) =>
            double.parse(a['price']).compareTo(double.parse(b['price'])));
      } else if (criteria == "Price High to Low") {
        filteredProducts.sort((a, b) =>
            double.parse(b['price']).compareTo(double.parse(a['price'])));
      }
    });
  }

  Future<void> fetchProducts(List<String> categories) async {
    List<Map<String, dynamic>> allProducts = [];
    try {
      for (var category in categories) {
        QuerySnapshot itemsSnapshot = await _firestore
            .collection('Products')
            .doc(category)
            .collection('items')
            .get();

        for (var doc in itemsSnapshot.docs) {
          var itemData = doc.data() as Map<String, dynamic>;
          allProducts.add({
            'id': doc.id,
            'name': itemData['name'],
            'price': itemData['price'].toString(),
            'stock': itemData['stock'].toString(),
            'type': itemData['type'],
            'brand': itemData['brand'],
            'image': itemData['image'],
            'description': itemData['description'],
          });
        }
      }
      setState(() {
        products = allProducts;
        filteredProducts = allProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void filterProducts(String query) {
    setState(() {
      searchQuery = query;
      filteredProducts = products.where((product) {
        return product['name'].toLowerCase().contains(query.toLowerCase()) ||
            product['description'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: () => searchFocusNode.unfocus(),
      child: Scaffold(
        backgroundColor: !isDark ? Colors.white : Color(0xFF2B2B2B) ,
        body: Stack(
          children: [
            Column(
              children: [
                // Search Bar
                Container(
                  color: Color(0xFFD1F4E4),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 30,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(width: 1),
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            focusNode: searchFocusNode,
                            onChanged: filterProducts,
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              hintStyle: GoogleFonts.kanit(),
                              border: InputBorder.none,
                              prefixIcon:
                                  const Icon(Icons.search, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Filter Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 70,
                    child: Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFAEB3BD)),
                              color: Color(0xFFF1FCD3),
                            
                            shape: BoxShape.circle
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            color: Colors.black.withOpacity(1),
                            // size: 10,
                          ),
                        ),
                        Expanded(
                          child: OutlinedButton(
                            style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(
                                    Colors.blue.shade50)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.sort,
                                  color: Colors.black,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Sort by',
                                    style: GoogleFonts.sora(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                backgroundColor: Color(0xFFFFFFFF),
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                ),
                                builder: (context) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical:
                                                  8.0), // Vertical padding
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Color(0xfff2bac9),
                                              border: Border.all(
                                                  color: Colors.black,
                                                  width: 1),
                                              // Black thin border
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ListTile(
                                              title: Center(
                                                // Center the text
                                                child: Text(
                                                  "A-Z",
                                                  style: GoogleFonts.kanit(
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                              onTap: () {
                                                sortProducts("A-Z");
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Color(0xffbad7f2),
                                              border: Border.all(
                                                  color: Colors.black,
                                                  width: 1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ListTile(
                                              title: Center(
                                                child: Text(
                                                  "Z-A",
                                                  style: GoogleFonts.kanit(
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                              onTap: () {
                                                sortProducts("Z-A");
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Color(0xfff2e2ba),
                                              border: Border.all(
                                                  color: Colors.black,
                                                  width: 1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ListTile(
                                              title: Center(
                                                child: Text(
                                                  "Price Low to High",
                                                  style: GoogleFonts.kanit(
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                              onTap: () {
                                                sortProducts(
                                                    "Price Low to High");
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Color(0xffbaf2bb),
                                              border: Border.all(
                                                  color: Colors.black,
                                                  width: 1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ListTile(
                                              title: Center(
                                                child: Text(
                                                  "Price High to Low",
                                                  style: GoogleFonts.kanit(
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                              onTap: () {
                                                sortProducts(
                                                    "Price High to Low");
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
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: SpinKitWave(
                            color: Colors.blue,
                            size: 50,
                          ),
                        )
                      : hasError
                          ? const Center(child: Text('Error fetching products'))
                          : MasonryGridView.builder(
                              gridDelegate:
                                  const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                return buildProductCard(
                                    filteredProducts[index]);
                              },
                            ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget buildProductCard(Map<String, dynamic> product) {
  //   return GestureDetector(
  //     onTap: () {
  //       searchFocusNode.unfocus();
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => ProductDetail(
  //             product: product,
  //           ),
  //         ),
  //       );
  //     },
  //     child: Card(
  //       color: Colors.white,
  //       margin: const EdgeInsets.all(8),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.stretch,
  //         children: [
  //           // Product Image
  //           AspectRatio(
  //             aspectRatio: 1,
  //             child: ClipRRect(
  //               borderRadius: const BorderRadius.only(
  //                 topLeft: Radius.circular(12),
  //                 topRight: Radius.circular(12),
  //               ),
  //               child: Padding(
  //                 padding: const EdgeInsets.all(4.0),
  //                 child: Hero(
  //                   tag: product['id'],
  //                   child: Container(
  //                     decoration: BoxDecoration(
  //                       borderRadius: BorderRadius.circular(8),
  //                       image: DecorationImage(
  //                         image: NetworkImage(product['image'] ?? 'https://via.placeholder.com/150'),
  //                         fit: BoxFit.cover,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ), // Product Details
  //           Padding(
  //             padding: const EdgeInsets.all(8.0),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   product['name' ],
  //                   style: GoogleFonts.russoOne(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                   maxLines: 1,
  //                   overflow: TextOverflow.ellipsis,
  //                 ),
  //                 const SizedBox(height: 4),
  //                 Text(
  //                   product['description'],
  //                   style: GoogleFonts.kanit(
  //                     fontSize: 12,
  //                     color: Colors.grey[600],
  //                   ),
  //                   maxLines: 2,
  //                   overflow: TextOverflow.ellipsis,
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Text(
  //                   '₹ ${product['price']}',
  //                   style: GoogleFonts.russoOne(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w700,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  Widget buildProductCard(Map<String, dynamic> product) {
    if (product == null) return SizedBox();

    return GestureDetector(
      onTap: () {
        searchFocusNode.unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetail(product: product),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Hero(
                  tag: product['id'] ?? UniqueKey().toString(),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(
                          product['image'] ?? 'https://via.placeholder.com/150',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Product Details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unnamed Product',
                    style: GoogleFonts.russoOne(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['description'] ?? 'No description available',
                    style: GoogleFonts.kanit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹ ${product['price'] ?? '0'}',
                    style: GoogleFonts.russoOne(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
