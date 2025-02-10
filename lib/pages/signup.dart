import 'dart:async';
import 'dart:ui';

import 'package:dotted_line/dotted_line.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nks/main.dart';
import 'package:nks/pages/login.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SignupPage());
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _isObscured = true; // Password visibility toggle
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;


  final _formKey = GlobalKey<FormState>(); // Form key for validation
  bool _isLoading = false; // To manage loading state
  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
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
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          child: const MainScreen(),
        ),
      );
    } catch (e) {
      // Handle errors and show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

// Function to save UserName
  Future<void> saveUserName(String userName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('UserName', userName);
  }

  Future<String?> getUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('UserName');
  }

  void loadUserName() async {
    String? userName = await getUserName();
    if (userName != null) {
      _nameController.text = userName; // Set the text in the TextField
    }
  }
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (_nameController.text.trim().isNotEmpty) {
          await userCredential.user?.updateDisplayName(_nameController.text.trim());
          await userCredential.user?.reload();
        }

        // Trigger email verification
        await userCredential.user?.sendEmailVerification();
        print('Verification email sent to ${userCredential.user!.email}');

        // Start checking for email verification
        _checkEmailVerification(userCredential.user!);

        // Show email verification dialog if email is not verified
        if (!userCredential.user!.emailVerified) {
          _showEmailVerificationDialog();
        }

        // Set a 2-hour timer to delete the account if not verified
        Future.delayed(Duration(hours: 2), () async {
          if (!userCredential.user!.emailVerified) {
            await userCredential.user!.delete();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Account deleted due to email not being verified.')),
            );
          }
        });
      } on FirebaseAuthException catch (e) {
        _showErrorDialog(e.message ?? 'An error occurred.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _checkEmailVerification(User user) async {
    Timer.periodic(Duration(seconds: 5), (timer) async {
      await user.reload(); // Refresh user info to check verification status
      if (user.emailVerified) {
        timer.cancel(); // Stop checking if verified
        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            child: const MainScreen(),
          ),
        );
      }
    });
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Your Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/verification.png', height: 100),
            const SizedBox(height: 10),
            Text(
              'Please check your email for a verification link. '
                  'Follow these steps:\n\n'
                  '1. Open your inbox\n'
                  '2. Find the email from us\n'
                  '3. Click on the verification link\n\n'
                  'Once verified, you will be automatically redirected.',
              style: GoogleFonts.kanit(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close the dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signup Error'),
        content: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Hero(
      tag: 'name',
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
                color: Colors.white.withOpacity(0.2),
                // Frosted glass effect
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.3)),
              ),
              child: TextField(

                controller: _nameController,



                onChanged: (value) {
                  saveUserName(value); // Save the username on text change
                },
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: GoogleFonts.manrope(
                    fontWeight: FontWeight.w900,
                  ),
                  hintText: 'Enter your name...',
                  floatingLabelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                    height: 0.8, // Controls the vertical position of the label
                  ),
                  border: InputBorder.none,
                  // Remove default border
                  contentPadding: const EdgeInsets.only(
                      top: 0.0, left: 10), // Adds padding to push label up
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily:
                      'Manrope', // Apply the same font as in the password field
                ),
              ),
            ),
          ),
        ),
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
                color: Colors.white.withOpacity(0.2),
                // Frosted glass effect
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail Address',
                  labelStyle: GoogleFonts.manrope(
                    fontWeight: FontWeight.w900,
                  ),
                  hintText: 'Enter your email...',
                  floatingLabelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                    height: 0.8, // Controls the vertical position of the label
                  ),
                  border: InputBorder.none,
                  // Remove default border
                  contentPadding: const EdgeInsets.only(
                      top: 0.0, left: 10), // Adds padding to push label up
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily:
                      'Manrope', // Apply the same font as in the password field
                ),
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
                color: Colors.white.withOpacity(0.2),
                // Frosted glass effect
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _passwordController,
                obscureText: _isObscured,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.manrope(
                    fontWeight: FontWeight.w900,
                  ),
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
                  fontFamily:
                      'Manrope', // Apply the same font as in the name and email fields
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFF5F5DC), // Beige (a subtle base)
                    Color(0xFFE9967A), // DarkSalmon (a touch of warmth)
                    Color(0xFFAFEEEE), // PaleTurquoise (a hint of coolness)
                  ],
                  stops: [0.2, 0.5, 1.0], // Creates a delicate transition
                  center: Alignment(0.7, -0.6), // Shifts focus to the top right
                  radius: 1.7, // Enhances the diffused effect
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                reverse: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Form(
                    key: _formKey, // Attach form key to Form widget
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        // Space at the top
                        // Row for GIF and Welcome Text
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 85,
                                    height: 85,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0x944db17e),
                                      border: Border.all(
                                          color: Colors.black, width: 3),
                                    ),
                                  ),
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0x560043ff),
                                      border: Border.all(
                                          color: Colors.black, width: 3),
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
                            const SizedBox(width: 20),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Bonello',
                                    fontSize: 45.0,
                                  ),
                                ),
                                Text(
                                  'to the best, from the best.',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 18.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.black, width: 2),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: TextButton(
                                  onPressed: _signInWithGoogle,
                                  child: Image.asset(
                                    'assets/images/google.png',
                                    height: 24.0,
                                    width: 24.0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.black, width: 2),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: TextButton(
                                  onPressed: () {
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
                        const SizedBox(height: 20),

                        // Divider with OR text
                        Row(
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
                        const SizedBox(height: 20),

                        // Name TextField
                        _buildNameField(),
                        const SizedBox(height: 20),

                        // Email TextField with validation
                        _buildEmailField(),
                        const SizedBox(height: 20),

                        // Password TextField with validation
                        _buildPasswordField(),
                        const SizedBox(height: 20),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Link to Login Page
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account ? ",
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageTransition(
                                    type: PageTransitionType.fade,
                                    child: const LoginPage(),
                                    childCurrent: widget,
                                  ),
                                );
                              },
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.kanit(
                                  fontWeight: FontWeight.w700,
                                  // Matching font weight for consistency
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
            ),
          ],
        ),
      ),
    );
  }
}
