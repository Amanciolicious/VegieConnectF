import 'package:flutter/material.dart';
import 'landing_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LandingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFFA7C957);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
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
                        Icon(page.icon, size: 120, color: green),
                        const SizedBox(height: 32),
                        Text(page.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 18),
                        Text(page.desc, style: const TextStyle(fontSize: 18, color: Colors.black54), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: i == _pageIndex ? green : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              )),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    if (_pageIndex == _pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                    }
                  },
                  child: Text(_pageIndex == _pages.length - 1 ? 'Get Started' : 'Next', style: const TextStyle(fontSize: 20, color: Colors.white)),
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