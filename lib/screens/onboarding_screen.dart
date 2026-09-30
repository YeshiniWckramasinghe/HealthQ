import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  @override
void initState() {
  super.initState();
  Future.delayed(const Duration(seconds: 2), () {
    if (mounted) {
      _controller.animateToPage(
        1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  });
}

  final List<_OnboardData> _pages = const [
    _OnboardData(
      image: 'assets/images/onboard_1.jpeg',
      showLogoOnly: true,
    ),
    _OnboardData(
      image: 'assets/images/onboard_2.jpeg',
      title: 'Government Hospital OPD',
      description:
          'Book OPD appointments and track live queue status in real time, reducing hospital waiting room times.',
    ),
  ];

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final page = _pages[index];

              // --- Page 1: Solid background + centered logo image ---
              if (page.showLogoOnly) {
                return Container(
                  color: AppColors.primary300,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            image: DecorationImage(
                              image: AssetImage(page.image),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'HealthQ',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // --- Page 2 (and others): Full background image + text ---
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(page.image, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          page.title ?? '',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          page.description ?? '',
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _goToLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary300,
                              foregroundColor: AppColors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Next'),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Page indicator dots
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? AppColors.white
                        : AppColors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardData {
  final String image;
  final String? title;
  final String? description;
  final bool showLogoOnly;

  const _OnboardData({
    required this.image,
    this.title,
    this.description,
    this.showLogoOnly = false,
  });
}