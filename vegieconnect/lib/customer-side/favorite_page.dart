import 'package:flutter/material.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFFA7C957);
    // For demo, empty list
    final favorites = <String>[];
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: green,
        title: const Text('Favorites'),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Text('No favorites yet.', style: TextStyle(color: Colors.black54, fontSize: 18)),
            )
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, i) => ListTile(
                leading: Icon(Icons.eco, color: green),
                title: Text(favorites[i]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {},
                ),
              ),
            ),
    );
  }
} 