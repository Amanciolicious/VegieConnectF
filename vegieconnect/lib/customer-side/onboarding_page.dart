import 'landing_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingPage extends StatefulWidget {
  final String? userId; // Add userId parameter
  const OnboardingPage({super.key, this.userId});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  final List<_OnboardData> _pages = [
    _OnboardData(
      icon: Icons.eco,
      title: 'Fresh Vegetables',
      desc: 'Get the freshest vegetables delivered straight to your door with VegieConnect.',
    ),
    _OnboardData(
      icon: Icons.shopping_cart_checkout,
      title: 'Easy Ordering',
      desc: 'Order your favorite veggies in just a few taps. Simple, fast, and secure.',
    ),
    _OnboardData(
      icon: Icons.track_changes,
      title: 'Track Your Orders',
      desc: 'Stay updated with real-time order tracking and notifications.',
    ),
  ];

  Future<void> _finishOnboarding() async {
    try {
      // Mark onboarding as complete in both SharedPreferences and Firestore
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      
      // Update Firestore if userId is provided
      if (widget.userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
          'onboardingCompleted': true,
          'isNewlyRegistered': false, // Mark as no longer newly registered
        });
      }
      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LandingPage()),
      );
    } catch (e) {
      // If Firestore update fails, still proceed with SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LandingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _pageIndex = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Neumorphic(
                          style: AppNeumorphic.card.copyWith(
                            color: AppColors.accentGreen.withOpacity(0.18),
                            boxShape: NeumorphicBoxShape.circle(),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Icon(page.icon, size: 120, color: AppColors.primaryGreen),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(page.title, style: AppTextStyles.headline.copyWith(fontSize: 28)),
                        const SizedBox(height: 18),
                        Text(page.desc, style: AppTextStyles.body.copyWith(fontSize: 18, color: AppColors.textSecondary), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => Neumorphic(
                style: AppNeumorphic.card.copyWith(
                  color: i == _pageIndex ? AppColors.primaryGreen : AppColors.oliveGreen.withOpacity(0.18),
                  boxShape: NeumorphicBoxShape.circle(),
                  depth: i == _pageIndex ? 3 : 1,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                ),
              )),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: NeumorphicButton(
                  style: AppNeumorphic.button.copyWith(
                    color: AppColors.primaryGreen,
                    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(28)),
                  ),
                  onPressed: () {
                    if (_pageIndex == _pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                    }
                  },
                  child: Text(
                    _pageIndex == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: AppTextStyles.button.copyWith(fontSize: 20, color: Colors.white),
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

class _OnboardData {
  final IconData icon;
  final String title;
  final String desc;
  const _OnboardData({required this.icon, required this.title, required this.desc});
} 