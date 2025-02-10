import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nks/main.dart';
import 'package:page_transition/page_transition.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isObscured = true;
  bool _rememberMe = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Alignment _alignment =
      const Alignment(0.7, -0.6); // Initial center position for the gradient
  late Timer _timer;
  bool _isLoading = false; // To manage loading state
  

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        // Update the alignment to a new random position for continuous animation
        _alignment = Alignment(
          _alignment.x + 0.1 > 1.0 ? -1.0 : _alignment.x + 0.1,
          _alignment.y + 0.1 > 1.0 ? -1.0 : _alignment.y + 0.1,
        );
      });
    });
  }

  Future<void> _checkAuthStatus() async {
    final User? user = _auth.currentUser;
    if (user != null && user.emailVerified) {
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          child: const MainScreen(),
        ),
      );
    } else {
      _loadCredentials();
    }
  }

  Future<void> _loadCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    String? savedPassword = prefs.getString('password');
    bool? rememberMe = prefs.getBool('rememberMe');

    if (rememberMe == true) {
      _rememberMe = true;
      _emailController.text = savedEmail ?? '';
      _passwordController.text = savedPassword ?? '';
      // _signInWithEmailAndPassword();
    }
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> createUserProfile() async {
    try {
      final userName = FirebaseAuth
          .instance.currentUser; // Replace with the logged-in user's name

      String name =
          userName != null ? (userName.displayName ?? 'Guest') : 'Guest';
      String email = userName != null ? (userName.email ?? 'Error') : 'Error';

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('User Profiles')
          .doc(name)
          .set({
        'userName': name,
        'email': email,
        'timestamp': DateTime.now().toIso8601String(),
        'userId': userName?.uid,
        // 'orders' : ,
      });
    } catch (e) {
      print('Error saving Data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error Saving User Profile: ${e.toString()}')),
      );
    }
  }
  Future<void> _sendResetPasswordEmail(BuildContext context) async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      showTopSnackBar(context, "Please enter your email address", color: Colors.red);
      return;
    }

    try {
      // Trigger Firebase password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showTopSnackBar(context, "Password reset email sent", color: Colors.green);
    } catch (e) {
      // Show error message in case of failure
      showTopSnackBar(context, "Failed to send password reset email. Please try again.", color: Colors.red);
    }
  }
  Future<void> _signInWithEmailAndPassword() async {

    
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final User? user = userCredential.user;

      if (user != null) {
        if (user.emailVerified) {
          if (_timer.isActive) _timer.cancel();
          _timer = Timer(const Duration(milliseconds: 300), () async {
            // createUserProfile();

            Navigator.pushReplacement(
              context,
              PageTransition(
                type: PageTransitionType.fade,
                child: const MainScreen(),
              ),
            );
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true); // Force logout state
          });

          // Save credentials if Remember Me is checked
          if (_rememberMe) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString('email', _emailController.text);
            prefs.setString('password', _passwordController.text);
            prefs.setBool('rememberMe', true);
          } else {
            // Clear saved credentials
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.remove('email');
            prefs.remove('password');
            prefs.remove('rememberMe');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                duration: Duration(seconds: 3),
                content: Text(
                    'Please Check your E-mail, verify your email before signing in.')),
          );
          await user.sendEmailVerification();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found for that email.')),
        );
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Wrong password provided for that user.')),
        );
      } else {
        print(
            'Error during email sign-in: ${e.code}, ${e.message}, ${e.stackTrace}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // Once signed in, return the UserCredential
      await _auth.signInWithCredential(credential);
      // Navigate to home if Google sign-in is successful
      if (_timer.isActive) _timer.cancel();
      _timer = Timer(const Duration(milliseconds: 300), () {
        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            child: const MainScreen(),
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
      );
    }
  }

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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      message,
                      style: GoogleFonts.manrope(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
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

    // Remove the snack bar after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xffffffff),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              // color: Color(0xFFF0F5C7)
              gradient: RadialGradient(
                colors: [
                  Color(0xFFD6FECE), // Yellowish color
                  Color(0xFFF0F5C7), // Pinkish color
                  Color(0xFFDEF9F7), // Blueish color
                ],
                stops: [0.3, 0.6, 1.0],
                center: Alignment(0.7, -0.6),
                radius: 1.5,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              reverse: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20), // Add space at the top
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer thin circle
                          Container(
                            width: 80, // Outer container size
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                              border: Border.all(
                                  color: Colors.black,
                                  width: 3), // Thin outer border
                            ),
                          ),
                          // Smaller circle with a thicker border
                          Container(
                            width: 60, // Inner container size
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xae96c9ff),
                              border: Border.all(
                                  color: Colors.black,
                                  width: 3), // Thicker inner border
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/videos/lotus.gif',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                          color: Color(0xff190f0f),
                          fontSize: 34.0,
                          fontFamily: 'Bonello'),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Please enter your details to sign in',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google Button
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black.withOpacity(1.0),
                                width: 2.0, // Border width
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: TextButton(
                              onPressed: _signInWithGoogle,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/google.png',
                                    height: 24.0,
                                    width: 24.0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Facebook Button
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black.withOpacity(1.0),
                                width: 2.0, // Border width
                              ),
                              borderRadius: BorderRadius.circular(
                                  10.0), // Rounded corners
                            ),
                            child: TextButton(
                              onPressed: () {
                                showTopSnackBar(context, "Not available try Google Sign-In", color: Colors.orange);
                                

                              },
                              child: Image.asset(
                                'assets/images/facebook.png',
                                height: 24.0,
                                width: 24.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: DottedLine(
                              dashColor: Colors.black,
                              lineThickness: 1.0,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[800]),
                            ),
                          ),
                          const Expanded(
                            child: DottedLine(
                              dashColor: Colors.black,
                              lineThickness: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // const SizedBox(height: 20),
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              fillColor: WidgetStateProperty.all(
                                  const Color(0x944db17e)),
                              // WidgetStateProperty.all( Colors.transparent ),

                              checkColor: const Color(0xffffffff),
                              value: _rememberMe,
                              onChanged: (bool? newValue) {
                                setState(() {
                                  _rememberMe = newValue ?? false;
                                });
                              },
                            ),
                            const Text('Remember me'),
                          ],
                        ),
                        TextButton(
                          onPressed: () {

                            _sendResetPasswordEmail(context);



                          },
                          child: Text(
                            "Forgot Password ?",
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.grey[900]?.withOpacity(1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Hero(
                      tag: 'button',
                      child: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_timer.isActive) _timer.cancel();
                              _timer =
                                  Timer(const Duration(milliseconds: 300), () {
                                _signInWithEmailAndPassword();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              // Black button color
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.russoOne(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account yet? ",
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            // if (_timer.isActive) _timer.cancel();
                            // _timer =
                            //     Timer(const Duration(milliseconds: 300), () {
                            Navigator.pushReplacement(
                              context,
                              PageTransition(
                                type: PageTransitionType.fade,
                                child: const SignupPage(),
                                childCurrent: widget,
                              ),
                            );
                            // });
                          },
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.kanit(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Hero(
      tag: 'email',
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              height: 60,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Frosted glass effect
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail Address',
                  labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w900),
                  hintText: 'Enter your email...',
                  floatingLabelStyle: const TextStyle(
                    color: Colors.black54,
                    fontFamily: 'Inter',
                    height: 0.8, // Controls the vertical position of the label
                  ),
                  border: InputBorder.none,
                  // Remove default border
                  contentPadding: const EdgeInsets.only(
                      top: 0.0, left: 10), // Adds padding to push label up
                ),
                style: GoogleFonts.manrope(
                    color: Colors.black,
                    fontWeight: FontWeight.w600), // Text color
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Hero(
      tag: 'password',
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              height: 60,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Frosted glass effect
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _passwordController,
                obscureText: _isObscured,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w900),
                  hintText: 'Enter your password...',
                  floatingLabelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                    height: 0.8, // Controls the vertical position of the label
                  ),

                  border: InputBorder.none,
                  // Remove default border
                  contentPadding: const EdgeInsets.only(top: 0.0, left: 10),
                  // Adds padding to push label up
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _isObscured = !_isObscured),
                    child: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),

                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'Manrope',
                ), // Text color
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoginPage(),
  ));
}
