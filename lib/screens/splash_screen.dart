import "package:package_info_plus/package_info_plus.dart";
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    // Return empty black screen until visible to prevent "double logo" flash
    if (!_isVisible) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
      );
    }
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              
              // Logo Reveal Animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      children: [
                        // Layer 1: Empty State (Background)
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.grey[900] : Colors.grey[200],
                          ),
                          child: Center(
                            child: Text(
                              'Did\nit',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 80, // Larger size
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.grey[700] : Colors.grey[400],
                                letterSpacing: -3.0, // Tighter letter spacing for larger text
                                height: 0.85,
                              ),
                            ),
                          ),
                        ),
                        
                        // Layer 2: Filled State (Foreground) - Clipped from bottom
                        ClipRect(
                          clipper: BottomFillClipper(_controller.value),
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFCEFF00), // Electric Lime to match logo
                            ),
                            child: Center(
                              child: Text(
                                'Did\nit',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 80, // Larger size
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black, // Always black on Lime
                                  letterSpacing: -3.0,
                                  height: 0.85,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // "Tapped it." Text below
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Tapped it.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              
              const Spacer(flex: 3),
              
              // Version Text
              FadeTransition(
                opacity: _fadeAnimation,
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version ?? '1.0.0';
                    return Text(
                      'v$version',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[800] : Colors.grey[400],
                        letterSpacing: 1.0,
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class BottomFillClipper extends CustomClipper<Rect> {
  final double progress;

  BottomFillClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, size.height * (1 - progress), size.width, size.height);
  }

  @override
  bool shouldReclip(BottomFillClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

