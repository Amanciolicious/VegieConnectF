// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'data/veggies_data.dart';

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
    final veggie = widget.veggie;
    final desc = veggie['desc'] as String;
    final showReadMore = desc.length > 90;
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6EA),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: screenWidth * 0.11, left: screenWidth * 0.04, right: screenWidth * 0.04),
                    padding: EdgeInsets.only(top: screenWidth * 0.16, bottom: screenWidth * 0.06),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: cardRadius,
                      boxShadow: neumorphicShadow,
                    ),
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
                              Text(veggie['name'], style: TextStyle(fontSize: screenWidth * 0.065, fontWeight: FontWeight.bold)),
                              SizedBox(height: screenWidth * 0.015),
                              Row(
                                children: [
                                  ...List.generate(5, (i) => Icon(Icons.star, color: i < veggie['rating'].round() ? Colors.orange : Colors.grey[300], size: screenWidth * 0.05)),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(veggie['rating'].toString(), style: TextStyle(fontSize: screenWidth * 0.04)),
                                ],
                              ),
                              SizedBox(height: screenWidth * 0.02),
                              Row(
                                children: [
                                  Text('\u20b1${veggie['price']}/KG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.055, color: green)),
                                  const Spacer(),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: green.withOpacity(0.12),
                                      borderRadius: cardRadius,
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove, size: screenWidth * 0.05),
                                          onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                                        ),
                                        Text('$_qty KG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
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
                              Text('Product Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                              SizedBox(height: screenWidth * 0.015),
                              Text(
                                showReadMore && !_readMore ? '${desc.substring(0, 90)}...' : desc,
                                style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.black87),
                              ),
                              if (showReadMore && !_readMore)
                                GestureDetector(
                                  onTap: () => setState(() => _readMore = true),
                                  child: Text('Read More', style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
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
                        icon: Icon(Icons.favorite_border, color: green, size: screenWidth * 0.06),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.06),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Text('Related Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
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
                        child: Container(
                          width: screenWidth * 0.22,
                          margin: EdgeInsets.only(right: screenWidth * 0.03),
                          decoration: BoxDecoration(
                            color: green.withOpacity(0.10),
                            borderRadius: cardRadius,
                            boxShadow: neumorphicShadow,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(v['image'], style: TextStyle(fontSize: screenWidth * 0.08)),
                              SizedBox(height: screenWidth * 0.015),
                              Text(v['name'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: screenWidth * 0.04)),
                            ],
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
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenWidth * 0.05),
                  topRight: Radius.circular(screenWidth * 0.05),
                ),
                boxShadow: neumorphicShadow,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Price', style: TextStyle(color: Colors.black54, fontSize: screenWidth * 0.035)),
                      Text('\u20b1${(veggie['price'] * _qty).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.055, color: green)),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: screenWidth * 0.13,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(borderRadius: cardRadius),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: () {},
                      child: Text('Add to Cart', style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 