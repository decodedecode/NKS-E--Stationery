import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nks/widgets/adcontainers.dart';
import 'package:nks/widgets/fringes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const HomePage());
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePageScreen(),
    );
  }
}

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});

  @override
  _HomePageScreenState createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> products = [];

  late AnimationController _controller;
  String tag = 'Loading..';
  String tag2 = 'Loading..';
  final PageController _pageController =
      PageController(viewportFraction: 1); // Showing part of the next image
  List<String> images = [];
  bool isLoading = true;
  String errorMessage = '';

  Timer? _autoSlideTimer;
  List<int> likedImages = []; // To keep track of liked images

  @override
  void initState() {
    super.initState();
    debugFetchAllDocuments();
    _fetchSlideshowImages();
    _startAutoSlide();
    loadUserName();

    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> debugFetchAllDocuments() async {
    QuerySnapshot parentCollectionSnapshot =
        await FirebaseFirestore.instance.collection('Products').get();

    print(
        "Total documents in 'Products': ${parentCollectionSnapshot.docs.length}");

    for (var doc in parentCollectionSnapshot.docs) {
      print("Document ID: ${doc.id}");
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel(); // Cancel the timer when the widget is disposed
    _pageController.dispose();
    _controller.dispose();

    super.dispose();
  }

  Future<void> _fetchSlideshowImages() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('slideshow1')
          .doc('001')
          .get();

      List<dynamic> imageList = snapshot.data()?['images'] ?? [];
      if (imageList.isNotEmpty) {
        setState(() {
          images = List<String>.from(imageList);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'No images found in Firestore.';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching images: $e';
      });
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      int nextPage = _pageController.page!.round() + 1;

      if (nextPage >= images.length) {
        nextPage = 0; // Loop back to the first image
      }

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  String userName = 'Guest'; // Default value

  Future<String?> getUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('UserName');
  }

  void loadUserName() async {
    String? fetchedUserName = await getUserName();
    setState(() {
      userName = fetchedUserName ?? 'Guest'; // Fallback to 'Guest' if null
      isLoading = false; // Mark loading as complete
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String displayName =
        user != null ? (user.displayName ?? userName) : userName;
    // void printName() {
    //   print('Here : username $userName');
    //   print(user?.displayName );
    // }

    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Scaffold(
        backgroundColor: const Color(0xfffbf5f3).withOpacity(0.1),
        // Background color set to white
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: MediaQuery.of(context).platformBrightness ==
                          Brightness.light
                      ? [
                          Colors.white,
                          Colors.white,
                          Colors.white,
                        ]
                      : [
                          Colors.black,
                          Color(0xFF1A1A1A),
                          Color(0xFF333333),
                        ],
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipPath(
                    clipper: WavyClipper(),
                    child: Container(
                      height: 130,
                      decoration: BoxDecoration(
                        color: MediaQuery.of(context).platformBrightness ==
                                Brightness.dark
                            ? Color(0xFFC6DFBA)
                            : Color(0xFFBADBE3),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black87,
                              blurRadius: 7,
                              spreadRadius: 5,
                              offset: Offset(0, 3)),
                        ],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Stack(
                        children: [
                          /// Adds ruled lines for notebook appearance
                          Positioned.fill(
                            child: Column(
                              children: List.generate(
                                5,
                                (index) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Container(
                                    height: 1,
                                    color: Colors.black.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0, right: 0.0, top: 40, bottom: 20),
                            child: Column(children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome,'.padLeft(10),
                                        style: TextStyle(
                                            letterSpacing: 1.2,
                                            wordSpacing: 4,
                                            color: Color(0xFF606060),
                                            fontFamily: 'Bonello'),
                                      ),
                                      isLoading
                                          ? const CircularProgressIndicator()
                                          : Text(displayName.padLeft(15),
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  letterSpacing: 1.5,
                                                  wordSpacing: 4,
                                                  color: Color(0xFF3B3B3B),
                                                  fontFamily: 'Bonello')),
                                    ],
                                  ),

                                  /// Search & Coins
                                  Padding(
                                    padding: const EdgeInsets.only(right: 0.0),
                                    child: Row(
                                      children: [
                                        /// coins
                                        GestureDetector(
                                          onTap: () {},
                                          child: Container(
                                            width: 120,
                                            height: 45,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  width: 1,
                                                  color: Colors.black),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(24)),
                                              shape: BoxShape.rectangle,
                                              color: Color(0xfff9f8de),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Request Item',
                                                  style: GoogleFonts.kanit(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 80,
                                          height: 45,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xffe5e1ee)
                                                  .withOpacity(1),
                                              border: Border.all(
                                                  width: 1,
                                                  color: Colors.black)),
                                          child: Icon(Icons
                                              .notifications_active_rounded),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ]),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Horizontal list of slideshow images
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 15, right: 15),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: CachedNetworkImage(
                                  imageUrl: images[index],
                                  width: MediaQuery.of(context).size.width - 20,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      SpinKitDoubleBounce(
                                    size: 30,
                                    color: Colors.blue,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  // Rounded corners
                                  child: SizedBox(
                                    // width: 176,
                                    height: 40,
                                    child: InkWell(
                                      onTap: () {
                                        // Handle button tap

                                        print("Button tapped!");
                                      },
                                      child: Stack(
                                        children: [
                                          BackdropFilter(
                                            filter: ImageFilter.compose(
                                              outer: ImageFilter.blur(
                                                  sigmaX: 5, sigmaY: 5),
                                              inner: ImageFilter.matrix(
                                                  Matrix4.rotationZ(0.2)
                                                      .storage),
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xffdfe6a9)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                    width: 1,
                                                    color: Colors
                                                        .white70), // Ensure rounded corners
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                              child: Text(
                                                'Check Out',
                                                style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: images.length,
                      effect: SwapEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: _getRandomColor(),
                        dotColor: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  DynamicAdContainers(),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height /
                        5, // Increased height for additional content
                    color: MediaQuery.of(context).platformBrightness ==
                            Brightness.dark
                        ? Colors.black12
                        : Colors.white60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Name and Company
                        Text(
                          'NKS - Neelkamal Books and Stationers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        SizedBox(height: 5), // Spacing

                        // Version Information
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 5), // Spacing

                        // Contact and Support Information
                        Text(
                          'Contact us: sarthak8770@gmail.com | Support',
                          style: TextStyle(
                            fontSize: 12,
                            color: MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 10), // Spacing

                        // Promotion Line
                        Text(
                          'Developed with ❤️ by Sarthak Shukla in Madhya Pradesh',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        SizedBox(height: 5), // Spacing

                        // Call to Action
                        Text(
                          'If you want an app, contact me at sarthak8770@gmail.com',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  // SizedBox(
                  //   height: 30,
                  // )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _getRandomColor() {
  Random random = Random();
  return Color.fromARGB(
    255, (180 + random.nextInt(76)), // R: High brightness
    (180 + random.nextInt(76)), // G: High brightness
    (180 + random.nextInt(76)), // B: High brightness
  ).withOpacity(0.9); // High opacity for vividness
}
