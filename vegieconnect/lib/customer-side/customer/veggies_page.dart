// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'data/veggies_data.dart';
import 'veggie_details_page.dart';

class VeggiesPage extends StatelessWidget {
  const VeggiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFFA7C957);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: green,
        title: const Text('Veggies'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
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
    final green = const Color(0xFFA7C957);
    return Container(
      decoration: BoxDecoration(
        color: green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.favorite_border, color: green),
            ),
            Center(child: Text(veggie['image'], style: const TextStyle(fontSize: 40))),
            const SizedBox(height: 8),
            Text(veggie['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange, size: 16),
                Text('${veggie['rating']}', style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Text('₱${veggie['price']}/KG', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFA7C957))),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () {},
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 