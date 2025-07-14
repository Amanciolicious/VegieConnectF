// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'data/veggies_data.dart';
import 'veggie_details_page.dart';

class VeggiesPage extends StatelessWidget {
  const VeggiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final green = const Color(0xFFA7C957);
    final cardRadius = BorderRadius.circular(screenWidth * 0.05);
    final neumorphicShadow = [
      BoxShadow(
        color: Colors.grey.shade300,
        offset: Offset(screenWidth * 0.015, screenWidth * 0.015),
        blurRadius: screenWidth * 0.04,
      ),
      BoxShadow(
        color: Colors.white,
        offset: Offset(-screenWidth * 0.015, -screenWidth * 0.015),
        blurRadius: screenWidth * 0.04,
      ),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: green,
        title: Text('Veggies', style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)),
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
    final green = const Color(0xFFA7C957);
    final cardRadius = BorderRadius.circular(screenWidth * 0.05);
    final neumorphicShadow = [
      BoxShadow(
        color: Colors.grey.shade300,
        offset: Offset(screenWidth * 0.015, screenWidth * 0.015),
        blurRadius: screenWidth * 0.04,
      ),
      BoxShadow(
        color: Colors.white,
        offset: Offset(-screenWidth * 0.015, -screenWidth * 0.015),
        blurRadius: screenWidth * 0.04,
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: green.withOpacity(0.10),
        borderRadius: cardRadius,
        boxShadow: neumorphicShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.favorite_border, color: green, size: screenWidth * 0.05),
            ),
            Center(child: Text(veggie['image'], style: TextStyle(fontSize: screenWidth * 0.09))),
            SizedBox(height: screenWidth * 0.02),
            Text(veggie['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
            SizedBox(height: screenWidth * 0.01),
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange, size: screenWidth * 0.04),
                Text('${veggie['rating']}', style: TextStyle(fontSize: screenWidth * 0.035)),
              ],
            ),
            SizedBox(height: screenWidth * 0.01),
            Text('\u20b1${veggie['price']}/KG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04, color: green)),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(borderRadius: cardRadius),
                  minimumSize: Size(screenWidth * 0.09, screenWidth * 0.09),
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  shadowColor: Colors.transparent,
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