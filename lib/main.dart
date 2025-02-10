import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nks/cart/cart.dart';
import 'package:nks/pages/Categories/categories.dart';
import 'package:nks/pages/homepage.dart';
import 'package:nks/pages/login.dart';
import 'package:nks/pages/onboarding.dart';
import 'package:nks/firebase/firebase.dart';
import 'package:nks/pages/profile.dart';
import 'package:nks/widgets/bottomNavigationBar.dart';
import 'package:nks/widgets/cartprovider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  PushNotificationService pushNotificationService = PushNotificationService();
  await pushNotificationService.initialize();
  await pushNotificationService.getToken();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.light, // Dark status bar icons
    statusBarColor: Color(0x0),
  ));

  runApp(
    ChangeNotifierProvider(
      create: (create) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreenWrapper(), // Use SplashScreenWrapper as the home
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  late VideoPlayerController _controller;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();

    Future.delayed(const Duration(seconds: 1, milliseconds: 800), () {
      _checkNavigationStatus();
    });
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/splash.mp4')
        ..initialize().then((_) {
          setState(() {});
          _controller.play();
          _controller.setLooping(false);
        });
    } catch (e) {
        print("Error initializing video: $e");
      
    }
  }

  Future<void> _checkNavigationStatus() async {
    if (_isNavigating) return;
    _isNavigating = true;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool onboardingShown = prefs.getBool('onboardingShown') ?? false;
    bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

    Widget nextPage;
    if (isLoggedIn) {
      nextPage = const MainScreen();
    } else if (onboardingShown) {
      nextPage = const LoginPage();
    } else {
      nextPage = const OnboardingScreen();
    }

    _navigateToPage(nextPage);
  }

  void _navigateToPage(Widget page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          if (_controller.value.isInitialized)
            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                );
              },
            )
          else
            Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  Future<bool> _onWillPop() async {
    // Show the modal bottom sheet for confirmation
    return await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20), // Rounded top corners
        ),
      ),
      backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.dark ? Color(0xff121212) : Colors.white, // Background color set to white
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(
              "Are you sure you want to exit the app?",
              style: GoogleFonts.kanit(
                fontSize: 19, // Font size of the title
                fontWeight: FontWeight.w700, // Bold font weight
                                  color: MediaQuery.of(context).platformBrightness != Brightness.dark? Color(0xff121212) : Colors.white,
               // Dark text color
              ),
              textAlign: TextAlign.center, // Center-align the text
            ),
            const SizedBox(height: 20),
            _buildCustomButton(
              const Color(0xFFF7E8EF), // Light pink button background
              context,
              "Exit", // Exit button text
                  () {
                Navigator.of(context).pop(true); // Confirm and close the modal
              },
            ),
            // const SizedBox(height: 10), // Space between buttons
            _buildCustomButton(
              const Color(0xFFF0FFD5), // Light purple button background
              context,
              "Cancel", // Cancel button text
                  () {
                Navigator.of(context).pop(false); // Dismiss the modal
              },
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark, // Dark status bar icons
        systemNavigationBarColor:
            MediaQuery.of(context).platformBrightness == Brightness.dark
                ? Color(0xff121212)
                : Colors.white,
      ),
    );

    final pages = [
      const HomePageScreen(),
      const Categories(),
      const Cart(),
      const ProfilePage(),
    ];

    return WillPopScope(
      onWillPop: _onWillPop, // Intercepts the back button
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: NavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              print("Switched to page index: $_currentIndex");
            });
          },
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dotPosition;
  late Animation<double> _textOpacity;

  Future<void> _checkNavigationStatus() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool onboardingShown = prefs.getBool('onboardingShown') ?? false;
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      print(
          "App Start - isLoggedIn: $isLoggedIn, onboardingShown: $onboardingShown");

      Widget nextPage;
      if (isLoggedIn) {
        nextPage = const MainScreen();
      } else if (onboardingShown) {
        nextPage = const LoginPage();
      } else {
        nextPage = const OnboardingScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextPage),
      );
    } catch (e) {
      print("Error loading SharedPreferences: $e");
      // Handle error (maybe navigate to an error page or default screen)
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _dotPosition = Tween<double>(begin: -1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInQuint),
      ),
    );

    _controller.forward();

    // Delay the navigation check after the splash screen animation has shown
    Future.delayed(const Duration(milliseconds: 800), () {
      _checkNavigationStatus();
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the animation controller properly
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [Colors.blue.shade900, const Color(0xFF121212)]
                    : [Color(0xFF5386E4), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Stack(
                children: [
                  // Dot sliding across the screen
                  Align(
                    alignment: Alignment(
                      _dotPosition.value,
                      // Animates from -1.0 (left) to 1.0 (right)
                      0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: const Text(
                        ".",
                        style: TextStyle(
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  // Text "NKS" appearing in the center
                  Opacity(
                    opacity: _textOpacity.value,
                    child: Center(
                      child: Text(
                        "NKS",
                        style: GoogleFonts.russoOne(
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
// Widget _buildCustomButton(
//     Color color, BuildContext context, String text, VoidCallback onPressed) {
//   return Container(
//     width: double.infinity, // Full-width button
//     height: 50, // Fixed height for the button
//     decoration: BoxDecoration(
//       color: color, // Dynamic background color
//       borderRadius: BorderRadius.circular(10), // Rounded button corners
//     ),
//     child: TextButton(
//       onPressed: onPressed, // Button action
//       child: Text(
//         text,
//         style: GoogleFonts.russoOne(
//           fontSize: 16, // Font size for the button text
//           color: Colors.black, // Text color
//         ),
//       ),
//     ),
//   );
// }
Widget _buildCustomButton(
    Color Color,
    BuildContext context,
    String text,
    VoidCallback onPressed,
    ) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Container(
      decoration: BoxDecoration(
        color: Color,
        border: Border.all(
          color: isDarkMode ? Colors.white : Colors.black,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: Text(
              text,
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.w800,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        onTap: onPressed,
      ),
    ),
  );
}