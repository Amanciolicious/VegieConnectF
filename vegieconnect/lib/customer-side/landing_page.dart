import 'customer_home_page.dart';
import 'package:vegieconnect/theme.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Neumorphic(
              style: AppNeumorphic.card.copyWith(
                color: AppColors.accentGreen.withOpacity(0.18),
                boxShape: NeumorphicBoxShape.circle(),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Icon(Icons.eco, size: 100, color: AppColors.primaryGreen),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to VegieConnect!',
              style: AppTextStyles.headline.copyWith(fontSize: 28),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Your one-stop shop for fresh vegetables. Get started and enjoy healthy living!',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: SizedBox(
                width: 180,
                height: 56,
                child: NeumorphicButton(
                  style: AppNeumorphic.button.copyWith(
                    color: AppColors.primaryGreen,
                    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(28)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const CustomerHomePage()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Enter', style: AppTextStyles.button.copyWith(fontSize: 20)),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_downward, color: Colors.white, size: 28),
                    ],
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