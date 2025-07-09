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
    final green = const Color(0xFFA7C957);
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
                    margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
                    padding: const EdgeInsets.only(top: 60, bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Text(veggie['image'], style: const TextStyle(fontSize: 100))),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(veggie['name'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  ...List.generate(5, (i) => Icon(Icons.star, color: i < veggie['rating'].round() ? Colors.orange : Colors.grey[300], size: 20)),
                                  const SizedBox(width: 8),
                                  Text(veggie['rating'].toString(), style: const TextStyle(fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text('₱${veggie['price']}/KG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: green)),
                                  const Spacer(),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 20),
                                          onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                                        ),
                                        Text('$_qty KG', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 20),
                                          onPressed: () => setState(() => _qty++),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const Text('Product Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 6),
                              Text(
                                showReadMore && !_readMore ? '${desc.substring(0, 90)}...' : desc,
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                              if (showReadMore && !_readMore)
                                GestureDetector(
                                  onTap: () => setState(() => _readMore = true),
                                  child: const Text('Read More', style: TextStyle(color: Color(0xFFA7C957), fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 56,
                    left: 32,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 56,
                    right: 32,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.favorite_border, color: Color(0xFFA7C957)),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text('Related Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    for (var v in veggies.where((v) => v['name'] != veggie['name']).take(4))
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => VeggieDetailsPage(veggie: v)),
                        ),
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: green.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(v['image'], style: const TextStyle(fontSize: 36)),
                              const SizedBox(height: 6),
                              Text(v['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
          // Bottom bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Price', style: TextStyle(color: Colors.black54)),
                      Text('₱${(veggie['price'] * _qty).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: green)),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {},
                      child: const Text('Add to Cart', style: TextStyle(fontSize: 18, color: Colors.white)),
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