import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import 'home_page.dart';    // Your existing HomePage
import 'profile_page.dart'; // Your existing ProfilePage
import 'about_page.dart';   // Your existing AboutPage
import '../../theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<Widget> _pages = [
    const HomePage(),
    ProfilePage(),
    AboutPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        pageSnapping: false, // Disable page snapping
      ),
      bottomNavigationBar: _CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CustomBottomNavBar({required this.currentIndex, required this.onTap});

  static const double _barHeight = 64;
  static const double _bubbleSize = 74;
  static const Duration _animDuration = Duration(milliseconds: 220);
  static const Curve _animCurve = Curves.easeOutExpo;

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.account_circle_rounded, 'label': 'Profile'},
      {'icon': Icons.info_rounded, 'label': 'About'},
    ];

    return ColoredBox(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double sideGutter = (_bubbleSize / 2) + 12;
              final double effectiveWidth = (width - (sideGutter * 2)).clamp(0, width);
              final double segment = effectiveWidth / items.length;
              final double bubbleCenterX = sideGutter + (segment * currentIndex) + (segment / 2);
              final double bubbleLeft = bubbleCenterX - (_bubbleSize / 2);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Custom painted blue bar with fluid concave notch
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: _barHeight,
                      width: double.infinity,
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _NotchedBarPainter(
                            notchCenterX: bubbleCenterX,
                            notchRadius: _bubbleSize / 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Tappable icons overlay (hide active)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _barHeight,
                    child: RepaintBoundary(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: sideGutter),
                        child: Row(
                          children: List.generate(items.length, (int index) {
                            final bool isActive = index == currentIndex;
                            return Expanded(
                              child: InkResponse(
                                onTap: () => onTap(index),
                                highlightShape: BoxShape.rectangle,
                                radius: 28,
                                child: Center(
                                  child: Opacity(
                                    opacity: isActive ? 0.0 : 1.0,
                                    child: Icon(
                                      items[index]['icon'] as IconData,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),

                  // Floating bubble for active item (blue and detached, overlaps above the bar)
                  AnimatedPositioned(
                    duration: _animDuration,
                    curve: _animCurve,
                    bottom: _barHeight - 25,
                    left: bubbleLeft,
                    child: RepaintBoundary(child: _NavBubble(icon: items[currentIndex]['icon'] as IconData)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavBubble extends StatelessWidget {
  const _NavBubble({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _CustomBottomNavBar._bubbleSize,
      height: _CustomBottomNavBar._bubbleSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A89A7), // navbar color
            Color(0xFF6A89A7), // same color for solid effect
          ],
        ),
        borderRadius: BorderRadius.circular(_CustomBottomNavBar._bubbleSize),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 22,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  _NotchedBarPainter({
    required this.notchCenterX,
    required this.notchRadius,
  });

  final double notchCenterX;
  final double notchRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Notch parameters
    final double spread = notchRadius * 3.2;
    final double startX = (notchCenterX - spread / 2).clamp(0, w);
    final double endX = (notchCenterX + spread / 2).clamp(0, w);
    final double depth = notchRadius * 1.02;

    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(startX, 0)
      // left shoulder down into notch
      ..cubicTo(
        startX + spread * 0.22,
        0,
        notchCenterX - notchRadius * 1.12,
        depth,
        notchCenterX,
        depth,
      )
      // right shoulder up from notch
      ..cubicTo(
        notchCenterX + notchRadius * 1.12,
        depth,
        endX - spread * 0.22,
        0,
        endX,
        0,
      )
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    // Bar shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.20), 8, false);

    // Create gradient paint
    final Rect rect = Rect.fromLTWH(0, 0, w, h);
    final Paint gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6A89A7), // navbar color
          Color(0xFF6A89A7), // same color for solid effect
        ],
      ).createShader(rect);

    // Fill bar with gradient
    canvas.drawPath(path, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant _NotchedBarPainter oldDelegate) {
    return oldDelegate.notchCenterX != notchCenterX ||
        oldDelegate.notchRadius != notchRadius;
  }
}
