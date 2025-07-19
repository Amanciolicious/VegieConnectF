// ignore_for_file: deprecated_member_use

import 'data/veggies_data.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class VeggieDetailsPage extends StatefulWidget {
  final Map<String, dynamic> veggie;
  const VeggieDetailsPage({super.key, required this.veggie});

  @override
  State<VeggieDetailsPage> createState() => _VeggieDetailsPageState();
}

class _VeggieDetailsPageState extends State<VeggieDetailsPage> {
  int _qty = 1;
  bool _readMore = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardRadius = BorderRadius.circular(screenWidth * 0.05);
    final veggie = widget.veggie;
    final desc = veggie['desc'] as String;
    final showReadMore = desc.length > 90;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  Neumorphic(
                    style: AppNeumorphic.card.copyWith(
                      boxShape: NeumorphicBoxShape.roundRect(cardRadius),
                    ),
                    margin: EdgeInsets.only(top: screenWidth * 0.11, left: screenWidth * 0.04, right: screenWidth * 0.04),
                    padding: EdgeInsets.only(top: screenWidth * 0.16, bottom: screenWidth * 0.06),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Text(veggie['image'], style: TextStyle(fontSize: screenWidth * 0.22))),
                        SizedBox(height: screenWidth * 0.03),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(veggie['name'], style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.065)),
                              SizedBox(height: screenWidth * 0.015),
                              Row(
                                children: [
                                  ...List.generate(5, (i) => Icon(Icons.star, color: i < veggie['rating'].round() ? AppColors.primaryGreen : AppColors.oliveGreen.withOpacity(0.2), size: screenWidth * 0.05)),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(veggie['rating'].toString(), style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04)),
                                ],
                              ),
                              SizedBox(height: screenWidth * 0.02),
                              Row(
                                children: [
                                  Text('\u20b1${veggie['price']}/KG', style: AppTextStyles.price.copyWith(fontSize: screenWidth * 0.055)),
                                  const Spacer(),
                                  Neumorphic(
                                    style: AppNeumorphic.inset.copyWith(
                                      color: AppColors.primaryGreen.withOpacity(0.12),
                                      boxShape: NeumorphicBoxShape.roundRect(cardRadius),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove, size: screenWidth * 0.05),
                                          onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                                        ),
                                        Text('$_qty KG', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                                        IconButton(
                                          icon: Icon(Icons.add, size: screenWidth * 0.05),
                                          onPressed: () => setState(() => _qty++),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenWidth * 0.045),
                              Text('Product Details', style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.045)),
                              SizedBox(height: screenWidth * 0.015),
                              Text(
                                showReadMore && !_readMore ? '${desc.substring(0, 90)}...' : desc,
                                style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04),
                              ),
                              if (showReadMore && !_readMore)
                                GestureDetector(
                                  onTap: () => setState(() => _readMore = true),
                                  child: Text('Read More', style: AppTextStyles.body.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: screenWidth * 0.15,
                    left: screenWidth * 0.08,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: screenWidth * 0.06,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.black87, size: screenWidth * 0.06),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenWidth * 0.15,
                    right: screenWidth * 0.08,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: screenWidth * 0.06,
                      child: IconButton(
                        icon: Icon(Icons.favorite_border, color: AppColors.primaryGreen, size: screenWidth * 0.06),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.06),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Text('Related Products', style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.045)),
              ),
              SizedBox(height: screenWidth * 0.02),
              SizedBox(
                height: screenWidth * 0.32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                  children: [
                    for (var v in veggies.where((v) => v['name'] != veggie['name']).take(4))
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => VeggieDetailsPage(veggie: v)),
                        ),
                        child: Neumorphic(
                          style: AppNeumorphic.card.copyWith(color: AppColors.primaryGreen.withOpacity(0.10)),
                          margin: EdgeInsets.only(right: screenWidth * 0.03),
                          child: SizedBox(
                            width: screenWidth * 0.22,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(v['image'], style: TextStyle(fontSize: screenWidth * 0.08)),
                                SizedBox(height: screenWidth * 0.015),
                                Text(v['name'], style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: screenWidth * 0.04)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: screenWidth * 0.18),
            ],
          ),
          // Bottom bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Neumorphic(
              style: AppNeumorphic.card.copyWith(
                boxShape: NeumorphicBoxShape.roundRect(BorderRadius.only(
                  topLeft: cardRadius.topLeft,
                  topRight: cardRadius.topRight,
                )),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenWidth * 0.04),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Price', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: screenWidth * 0.035)),
                        Text('\u20b1${(veggie['price'] * _qty).toStringAsFixed(2)}', style: AppTextStyles.price.copyWith(fontSize: screenWidth * 0.055)),
                      ],
                    ),
                    const Spacer(),
                    NeumorphicButton(
                      style: AppNeumorphic.button.copyWith(
                        color: AppColors.primaryGreen,
                        boxShape: NeumorphicBoxShape.roundRect(cardRadius),
                      ),
                      onPressed: () {},
                      child: Text('Add to Cart', style: AppTextStyles.button.copyWith(fontSize: screenWidth * 0.045)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 