import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminVerifyListingsPage extends StatelessWidget {
  const AdminVerifyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final green = const Color(0xFFA7C957);
    final bg = const Color(0xFFF6F6F6);
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
      appBar: AppBar(
        title: Text('Verify Listings', style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold)),
        backgroundColor: green,
        elevation: 0,
      ),
      backgroundColor: bg,
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Text('Pending Product Listings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.048)),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').where('isActive', isEqualTo: false).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('No pending products.'));
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: cardRadius,
                      boxShadow: neumorphicShadow,
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.03),
                      title: Text(data['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                      subtitle: Text('Supplier: ${data['supplierName'] ?? ''}', style: TextStyle(fontSize: screenWidth * 0.04)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check, color: Colors.green, size: screenWidth * 0.06),
                            onPressed: () => doc.reference.update({'isActive': true}),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red, size: screenWidth * 0.06),
                            onPressed: () => doc.reference.delete(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Text('Pending Farm Locations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.048)),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('farm_locations').where('isActive', isEqualTo: false).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('No pending farms.'));
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: cardRadius,
                      boxShadow: neumorphicShadow,
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.03),
                      title: Text(data['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                      subtitle: Text('Supplier: ${data['supplierName'] ?? ''}', style: TextStyle(fontSize: screenWidth * 0.04)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check, color: Colors.green, size: screenWidth * 0.06),
                            onPressed: () => doc.reference.update({'isActive': true}),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red, size: screenWidth * 0.06),
                            onPressed: () => doc.reference.delete(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
} 