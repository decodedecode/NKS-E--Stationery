import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nks/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main () {
  runApp(const OnboardingApp());
}
class OnboardingApp extends StatelessWidget {
  const OnboardingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen(),
    );
  }
}


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int currentPage = 0;
  bool _isNavigating = false;

  // Animation variables
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _setOnboardingShown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingShown', true);
  }

  void _navigateToLoginPage() async {
    if (!_isNavigating) {
      _isNavigating = true;
      await _setOnboardingShown();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                currentPage = page;
              });
            },
            children: [
              buildOnboardingPage(
                color: const Color(0xff004290),
                image: 'assets/images/image1.png',
                text: 'Welcome to\nNeelkamal Books\nand Stationers.',
              ),
              buildOnboardingPage(
                color: const Color(0xff96c9ff),
                image: 'assets/images/image2.png',
                text: 'Explore a wide\nRange of\nStationery...',
              ),
              buildOnboardingPage(
                color: const Color(0xff94c9e1),
                image: 'assets/images/image3.png',
                text: 'Get fast and\nreliable delivery.',
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              height: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _navigateToLoginPage,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            color: currentPage == 0
                                ? const Color(0xff198ce5)
                                : currentPage == 1
                                ? const Color(0xff96c9ff)
                                : const Color(0xff94c9e1),

                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) => buildDot(index)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: currentPage == 0
                              ? const Color(0xff198ce5)
                              : currentPage == 1
                              ? const Color(0xff96c9ff)
                              : const Color(0xff94c9e1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          icon: Icon(
                            currentPage == 2 ? Icons.check : Icons.arrow_forward,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (currentPage == 2) {
                              _navigateToLoginPage();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.ease,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOnboardingPage({
    required Color color,
    required String image,
    required String text,
  }) {
    return Container(
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _animation.value),
                child: Image.asset(
                  image,
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: MediaQuery.of(context).size.width,
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              text,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 10,
      width: currentPage == index ? 20 : 10,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: currentPage == index ? Colors.black : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
