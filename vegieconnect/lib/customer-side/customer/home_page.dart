import 'package:flutter/material.dart';
import 'data/veggies_data.dart';
import 'veggies_page.dart';
import 'veggie_details_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFFA7C957);
    final darkGreen = const Color(0xFF6CA04A);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('Your Location', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const Spacer(),
                      Icon(Icons.notifications_none, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Welcome, Vegie Lover!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search, color: Colors.black38),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search Vegetables',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer, color: green, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Get 40% discount on your first order from app.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 6),
                        Text('Shop Now', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Icon(Icons.eco, color: darkGreen, size: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VeggiesPage())),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: green.withOpacity(0.15),
                            radius: 32,
                            child: Icon(Icons.eco, color: green, size: 32),
                          ),
                          const SizedBox(height: 8),
                          const Text('Veggies', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text('Popular', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  for (var veggie in veggies.take(4))
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => VeggieDetailsPage(veggie: veggie)),
                      ),
                      child: _VeggieCard(veggie: veggie),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _VeggieCard extends StatelessWidget {
  final Map<String, dynamic> veggie;
  const _VeggieCard({required this.veggie});

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFFA7C957);
    return Container(
      decoration: BoxDecoration(
        color: green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(veggie['image'], style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(veggie['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.orange, size: 16),
              Text('${veggie['rating']}', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
} 