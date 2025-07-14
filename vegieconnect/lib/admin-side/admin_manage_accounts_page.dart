import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManageAccountsPage extends StatelessWidget {
  const AdminManageAccountsPage({super.key});

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
        title: Text('Manage Accounts', style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold)),
        backgroundColor: green,
        elevation: 0,
      ),
      backgroundColor: bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No users found.'));
          return ListView(
            padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${data['email'] ?? ''}', style: TextStyle(fontSize: screenWidth * 0.04)),
                      Text('Role: ${data['role'] ?? ''}', style: TextStyle(fontSize: screenWidth * 0.04)),
                      Text('Status: ${data['status'] ?? 'active'}', style: TextStyle(fontSize: screenWidth * 0.04)),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'suspend') {
                        await doc.reference.update({'status': 'suspended'});
                      } else if (value == 'activate') {
                        await doc.reference.update({'status': 'active'});
                      } else if (value == 'delete') {
                        await doc.reference.delete();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: data['status'] == 'active' ? 'suspend' : 'activate',
                        child: Text(data['status'] == 'active' ? 'Suspend' : 'Activate'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
} 