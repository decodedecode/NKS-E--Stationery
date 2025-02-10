import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nks/pages/catalog.dart';
import 'package:nks/widgets/frostedglasstile.dart';

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  _CategoriesState createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<bool> selectedTiles = List.generate(12, (index) => false);
  bool goButton = false;
  List<String> selectedCategories = [];
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tileData = [
      {
        'icon': Icons.brush,
        'title': 'Arts',
        'description':
            'Explore a wide range of art supplies to fuel creativity.'
      },
      {
        'icon': Icons.book,
        'title': 'Books',
        'description': 'Discover an extensive collection of books for all ages.'
      },
      {
        'icon': Icons.print,
        'title': 'Copier Supplies',
        'description': 'High-quality copier paper and toner for office needs.'
      },
      {
        'icon': Icons.menu_book,
        'title': 'Diaries',
        'description': 'Elegant diaries to pen down thoughts and memories.'
      },
      {
        'icon': Icons.child_care,
        'title': 'Kids',
        'description':
            'Fun and educational supplies perfect for young learners.'
      },
      {
        'icon': Icons.library_books,
        'title': 'Note Copies',
        'description': 'Durable note copies in various sizes and designs.'
      },
      {
        'icon': Icons.business_center,
        'title': 'Office Supplies',
        'description': 'Essential office supplies to keep productivity high.'
      },
      {
        'icon': Icons.edit,
        'title': 'Pens',
        'description':
            'A range of pens from gel to fountain for all writing styles.'
      },
      {
        'icon': Icons.school,
        'title': 'School Supplies',
        'description': 'Everything needed for students to excel in school.'
      },
      {
        'icon': Icons.sports_soccer,
        'title': 'Sports',
        'description': 'Sports gear and equipment for active lifestyles.'
      },
      {
        'icon': Icons.create,
        'title': 'Stationery Supplies',
        'description': 'Complete stationery supplies for all your needs.'
      },
      {
        'icon': Icons.toys,
        'title': 'Toys',
        'description': 'Fun and engaging toys for kids of all ages.'
      },
    ];

    return Scaffold(
      floatingActionButton: Visibility(
        visible: goButton,
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(1, 0.8),
              child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: const [
                              const Color(0xFFFFB6C1),
                              const Color(0xFFFFDAB9),
                              const Color(0xFFB0E0E6),
                              const Color(0xFFFFE4E1),
                            ],
                            stops: const [0.0, 0.3, 0.5, 1.0],
                            // transform: GradientRotation(_controller.value * 2 * 3.14159, )
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 4,
                            )
                          ]),
                      padding: const EdgeInsets.all(5),
                      child: FloatingActionButton(
                        backgroundColor: Color(0xffedfafd).withOpacity(1),
                        shape: const CircleBorder(),
                        elevation: 0,
                        onPressed: () {
                          if (_isNavigating) return;

                          if (selectedCategories.isNotEmpty) {
                            _isNavigating = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Catalog(
                                      selectedCategories: selectedCategories),
                                ),
                              ).then((_) {
                                _isNavigating =
                                    false; // Reset flag after navigation completes
                              });
                            });
                          }
                        },
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  // color: Colors.white
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: MediaQuery.of(context).platformBrightness ==
                            Brightness.dark
                        ? [
                            const Color(0xFF101820),
                            const Color(0xFF15232D),
                            const Color(0xFF1B3A4B),
                            const Color(0xFF265D6E)
                            // Charcoal blue-gray for balance
                          ]
                        : [
                            const Color(0xFFFFB6C1),
                            const Color(0xFFFFDAB9),
                            const Color(0xFFB0E0E6),
                            const Color(0xFFFFE4E1),
                          ],
                    stops: const [0.0, 0.33, 0.66, 1.0],
                    transform:
                        GradientRotation(_controller.value * 2 * 3.14159),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Explore',
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: MediaQuery.of(context).platformBrightness ==
                                Brightness.light
                            ? Colors.black
                            : Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    itemCount: tileData.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTiles[index] = !selectedTiles[index];
                            final category = tileData[index]['title'];
                            if (selectedTiles[index]) {
                              selectedCategories.add(category);
                            } else {
                              selectedCategories.remove(category);
                            }
                            goButton = selectedCategories.isNotEmpty;
                          });
                        },
                        onLongPress: () {
                          if (_isNavigating) return;

                          _isNavigating = true;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Catalog(
                                selectedCategories: [tileData[index]['title']],
                              ),
                            ),
                          ).then((_) {
                            _isNavigating = false; // Reset flag
                          });
                        },

                        child: FrostedGlassTile(
                          title: tileData[index]['title'],
                          description: tileData[index]['description'],
                          icon: tileData[index]['icon'],
                          isSelected: selectedTiles[index],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
