import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nks/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const Profile());
}

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProfilePage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  void _loadProfileImage() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.providerData
          .any((provider) => provider.providerId == 'google.com')) {
        setState(() {
          _profileImagePath = user.photoURL;
        });
      } else {
        setState(() {
          _profileImagePath = 'assets/images/pfp_basic.jpg';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (user.providerData
          .any((provider) => provider.providerId == 'google.com')) {
        _profileImagePath = user.photoURL;
      } else {
        _profileImagePath = 'assets/images/pfp_basic.jpg';
      }
    }

    String userName = 'Guest';

    Future<String?> _showEditEmailDialog(BuildContext context) async {
      final TextEditingController _emailController = TextEditingController();

      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Edit Email"),
          content: TextField(
            controller: _emailController,
            decoration: InputDecoration(hintText: "Enter new email"),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, _emailController.text.trim());
              },
              child: Text("Save"),
            ),
          ],
        ),
      );
    }

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

    Future<void> editProfileFunctionality(BuildContext context) async {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print("No user logged in");
        return;
      }

      try {
        final isDark =
            MediaQuery.of(context).platformBrightness == Brightness.dark;

        // Show options to user: Change profile picture or update email
        showModalBottomSheet(
          backgroundColor: isDark ? Color(0xff121212) : Colors.white,
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo),
                title: Text("Change Profile Picture"),
                onTap: () async {
                  Navigator.pop(context); // Close bottom sheet
                  // Pick an image
                  final pickedFile = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);

                  if (pickedFile != null) {
                    // Upload image to Firebase Storage
                    final storageRef = FirebaseStorage.instance
                        .ref()
                        .child('profile_pictures')
                        .child('${user.uid}.jpg');
                    final uploadTask =
                        await storageRef.putFile(File(pickedFile.path));
                    final downloadURL = await uploadTask.ref.getDownloadURL();

                    // Update Firebase Auth profile photo
                    await user.updatePhotoURL(downloadURL);

                    // Update UI or app state
                    print("Profile picture updated successfully.");
                  } else {
                    print("No image selected.");
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.email),
                title: Text("Edit Email"),
                onTap: () async {
                  Navigator.pop(context); // Close bottom sheet
                  // Show dialog to update email
                  final newEmail = await _showEditEmailDialog(context);
                  if (newEmail != null && newEmail.isNotEmpty) {
                    try {
                      await user.updateEmail(newEmail);
                      print("Email updated to $newEmail");
                    } catch (e) {
                      print("Error updating email: $e");
                    }
                  }
                },
              ),
            ],
          ),
        );
      } catch (e) {
        print("Error in editProfileFunctionality: $e");
      }
    }

    String displayName =
        user != null ? (user.displayName ?? userName) : userName;
    String userEmail = user != null ? (user.email ?? "No Email") : 'No Email';

    void showTopSnackBar(BuildContext context, String message, {Color? color}) {
      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top +
              10, // Just below the status bar
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

    Future<void> _sendResetPasswordEmail(BuildContext context) async {
      Navigator.pop(context);
      String email = userEmail;
      // A variable to track the last time an email was sent
      DateTime? lastEmailSentTime;

      if (email.isEmpty) {
        showTopSnackBar(context, "Please enter your email address",
            color: Colors.red);
        return;
      }

      // Check if 2 minutes have passed since the last email was sent
      if (lastEmailSentTime != null &&
          DateTime.now().difference(lastEmailSentTime!) <
              Duration(minutes: 2)) {
        showTopSnackBar(context,
            "You can send a password reset email only once every 2 minutes",
            color: Colors.orange);
        return;
      }

      try {
        // Trigger Firebase password reset email
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        // Update the last email sent time
        lastEmailSentTime = DateTime.now();

        // Show success message
        showTopSnackBar(context, "Password reset email sent",
            color: Colors.green);
      } catch (e) {
        // Show error message in case of failure
        showTopSnackBar(
            context, "Failed to send password reset email. Please try again.",
            color: Colors.red);
      }
    }

    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    const List<Color> darkModeColors = [
      Color(0xFF6F7F7F),
      Color(0xFF7A8D8B),
      Color(0xFF9E6E7A),
    ];

    const List<Color> lightModeColors = [
      Color(0xFFCAF0F8),
      Color(0xFFCAF0F8),
      Color(0xFFFACDDE),
    ];

    final List<Color> colors =
        MediaQuery.of(context).platformBrightness == Brightness.dark
            ? darkModeColors
            : lightModeColors;

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
            stops: [0.3, 0.99, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 70, left: 20, right: 20),
                child: Text(
                  'My Profile',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    color: const Color(0xFF121212),
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: BlurryContainer(
                  blur: 20,
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 2,
                            color:
                                MediaQuery.of(context).platformBrightness ==
                                        Brightness.dark
                                    ? Colors.white38
                                    : Colors.blueGrey,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundImage: _profileImagePath != null
                              ? (_profileImagePath!.startsWith('http')
                                  ? NetworkImage(_profileImagePath!)
                                  : AssetImage(_profileImagePath!)
                                      as ImageProvider)
                              : AssetImage('assets/images/pfp_basic.jpg'),
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          AutoSizeText(
                            userEmail,
                            style: TextStyle(fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: ListTile(
                          leading: const Icon(
                            Icons.lock_outline,
                          ),
                          title: Text(
                            "Password and Security",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            showModalBottomSheet(
                              backgroundColor:
                                  isDark ? Color(0xff323232) : Colors.white,
                              context: context,
                              builder: (context) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      "Password and Security",
                                      style: GoogleFonts.kanit(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: !isDark
                                            ? Color(0xff121212)
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildCustomButton(
                                      Color(0xFFD8F5E4),
                                      context,
                                      "Reset Password",
                                      () {
                                        _sendResetPasswordEmail(context);
                                      },
                                    ),
                                    _buildCustomButton(
                                        Color(0xFFF4EEED),
                                        context,
                                        "Logout from All Devices", () async {
                                      final currentUser =
                                          FirebaseAuth.instance.currentUser;
                                      if (currentUser != null) {
                                        await FirebaseAuth.instance.signOut();
                                        await FirebaseFirestore.instance
                                            .collection('userTokens')
                                            .doc(currentUser.uid)
                                            .delete();
                                        SharedPreferences prefs =
                                            await SharedPreferences
                                                .getInstance();
                                        await prefs.setBool(
                                            'isLoggedIn', false);
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const LoginPage()),
                                          (Route<dynamic> route) => false,
                                        );
                                      }
                                    }),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: const Divider(color: Colors.black12),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: ListTile(
                            leading: const Icon(
                              Icons.edit,
                            ),
                            title: Text(
                              "Edit Profile",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              showModalBottomSheet(
                                backgroundColor:
                                    isDark ? Color(0xff323232) : Colors.white,
                                context: context,
                                builder: (context) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        "Edit Profile",
                                        style: GoogleFonts.kanit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: !isDark
                                              ? Color(0xff121212)
                                              : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _buildCustomButton(
                                        Color(0xFFE1F1FE),
                                        context,
                                        "Edit Email",
                                        () {},
                                      ),
                                      _buildCustomButton(
                                        Color(0xFFD9D8EB),
                                        context,
                                        "Change Profile Picture",
                                        () {},
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: const Divider(color: Colors.black12),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: ListTile(
                            leading: const Icon(
                              Icons.support_agent,
                            ),
                            title: Text(
                              "Support",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Show Modal Bottom Sheet
                              showModalBottomSheet(
                                backgroundColor:
                                    isDark ? Color(0xff323232) : Colors.white,
                                context: context,
                                builder: (context) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Support",
                                        style: GoogleFonts.kanit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: !isDark
                                              ? Color(0xff121212)
                                              : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _buildCustomButton(
                                        Color(0xFFFED4ED),
                                        context,
                                        "Report a Problem",
                                        () {},
                                      ),
                                      _buildCustomButton(
                                        Color(0xFFD3E1DA),
                                        context,
                                        "Contact Support",
                                        () {},
                                      ),
                                      _buildCustomButton(
                                        Color(0xFFEEFCD5),
                                        context,
                                        "FAQs",
                                        () {},
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: ListTile(
                      leading:
                          const Icon(Icons.logout, color: Color(0xffd62828)),
                      title: Text(
                        "Logout",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xffd62828),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Color(0xffd62828), size: 16),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          backgroundColor:
                              isDark ? Color(0xff323232) : Color(0xFFFfffff),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 10),
                                Text(
                                  "Are you sure you want to logout?",
                                  style: GoogleFonts.kanit(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: !isDark
                                        ? Color(0xff121212)
                                        : Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                _buildCustomButton(
                                  const Color(0xFFD9D8EB),
                                  context,
                                  "Cancel",
                                  () {
                                    Navigator.of(context)
                                        .pop(); // Dismiss the modal
                                  },
                                ),
                                _buildCustomButton(
                                  const Color(0xFFFFE5E5),
                                  context,
                                  "Logout",
                                  () async {
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool('isLoggedIn',
                                        false); // Force logout state
                                    await FirebaseAuth.instance.signOut();
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage()),
                                      (Route<dynamic> route) => false,
                                    );
                                  },
                                ),
                                const SizedBox(height: 5),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 10,
              )
            ],
          ),
        ),
      ),
    );
  }
}
