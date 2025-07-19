// ignore_for_file: deprecated_member_use
import 'package:vegieconnect/theme.dart';
import 'data/veggies_data.dart';
import 'veggie_details_page.dart';
// For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class VeggiesPage extends StatelessWidget {
  const VeggiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text('Veggies', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.05)),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: screenWidth * 0.04,
          crossAxisSpacing: screenWidth * 0.04,
          childAspectRatio: 0.85,
          children: [
            for (var veggie in veggies)
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => VeggieDetailsPage(veggie: veggie)),
                ),
                child: _VeggieGridCard(veggie: veggie),
              ),
          ],
        ),
      ),
    );
  }
}

class _VeggieGridCard extends StatelessWidget {
  final Map<String, dynamic> veggie;
  const _VeggieGridCard({required this.veggie});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardRadius = BorderRadius.circular(screenWidth * 0.05);
    return Neumorphic(
      style: AppNeumorphic.card.copyWith(color: AppColors.primaryGreen.withOpacity(0.10)),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.favorite_border, color: AppColors.primaryGreen, size: screenWidth * 0.05),
            ),
            Center(child: Text(veggie['image'], style: TextStyle(fontSize: screenWidth * 0.09))),
            SizedBox(height: screenWidth * 0.02),
            Text(veggie['name'], style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
            SizedBox(height: screenWidth * 0.01),
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange, size: screenWidth * 0.04),
                Text('${veggie['rating']}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.035)),
              ],
            ),
            SizedBox(height: screenWidth * 0.01),
            Text('\u20b1${veggie['price']}/KG', style: AppTextStyles.price.copyWith(fontSize: screenWidth * 0.04)),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: NeumorphicButton(
                style: AppNeumorphic.button.copyWith(
                  color: AppColors.primaryGreen,
                  boxShape: NeumorphicBoxShape.roundRect(cardRadius),
                ),
                onPressed: () {},
                child: Icon(Icons.add, color: Colors.white, size: screenWidth * 0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 