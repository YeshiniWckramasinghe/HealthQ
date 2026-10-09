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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm up image cache ahead of time to eliminate frame drops during swipe and navigation
    precacheImage(const AssetImage('assets/images/onboard_1.jpeg'), context);
    precacheImage(const AssetImage('assets/images/onboard_2.jpeg'), context);
    precacheImage(const AssetImage('assets/images/google_logo.png'), context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final List<_OnboardData> _pages = const [
    _OnboardData(
      image: 'assets/images/onboard_1.jpeg',
      title: 'HealthQ',
      description:
          'Your smart healthcare queuing companion. Streamline your hospital visits and avoid long waiting room lines.',
      isLogoScreen: true,
    ),
    _OnboardData(
      image: 'assets/images/onboard_2.jpeg',
      title: 'Government Hospital OPD',
      description:
          'Book OPD appointments and track live queue status in real time, reducing hospital waiting room times.',
      isLogoScreen: false,
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
      body: PageView.builder(
        controller: _controller,
        itemCount: _pages.length,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (context, index) {
          final page = _pages[index];

          if (page.isLogoScreen) {
            return _buildLogoScreen(page);
          } else {
            return _buildGetStartedScreen(page);
          }
        },
      ),
    );
  }

  // --- Page 1: Logo Onboarding Screen ---
  Widget _buildLogoScreen(_OnboardData page) {
    return Container(
      color: AppColors.primary300,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              // Top Bar with Skip
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _goToLogin,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Centered Logo Card
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  image: DecorationImage(
                    image: ResizeImage(
                      AssetImage(page.image),
                      width: 250,
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                page.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Indicator Dots
              _buildPageDots(),
              const SizedBox(height: 28),
              // Next Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary400,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // --- Page 2: Get Started Screen ---
  Widget _buildGetStartedScreen(_OnboardData page) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          page.image,
          fit: BoxFit.cover,
          cacheWidth: 1080,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.black.withValues(alpha: 0.3),
                AppColors.black.withValues(alpha: 0.85),
              ],
              stops: const [0.3, 0.65, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                // Top Bar with Back Arrow
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      _controller.previousPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
                const Spacer(),
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Indicator Dots
                _buildPageDots(),
                const SizedBox(height: 28),
                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _goToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary300,
                      foregroundColor: AppColors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Reusable Page Indicator Dots ---
  Widget _buildPageDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == i ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: _currentPage == i
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _OnboardData {
  final String image;
  final String title;
  final String description;
  final bool isLogoScreen;

  const _OnboardData({
    required this.image,
    required this.title,
    required this.description,
    this.isLogoScreen = false,
  });
}