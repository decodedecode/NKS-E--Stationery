import 'package:flutter/material.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';

class NavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(color: Colors.black), // Global icon color set to black
      child: SnakeNavigationBar.gradient(
        backgroundGradient: LinearGradient(
          colors: MediaQuery.of(context).platformBrightness == Brightness.dark
              ? [Color(0xFF121212), Color(0xFF121212)]
              : [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
        ),
        behaviour: SnakeBarBehaviour.pinned,
        snakeShape: SnakeShape.circle,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        snakeViewGradient: LinearGradient(
          colors: MediaQuery.of(context).platformBrightness == Brightness.dark
              ? [
            const Color(0xFFD2D9FD),
            const Color(0xFFD2D9FD),
            const Color(0xFFD2D9FD),

          ]
              : [
            Color(0xFFB5D6D6),
            Color(0xFFB5D6D6),
            Color(0xFFB5D6D6),




          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.black,), // Removed color
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search), // Removed color
            label: "Search",
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.favorite), // Removed color
          //   label: "Wishlist",
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart), // Removed color
            label: "Cart",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle), // Removed color
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
