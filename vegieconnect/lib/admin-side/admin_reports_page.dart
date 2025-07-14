import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

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
        title: Text('User Reports', style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold)),
        backgroundColor: green,
        elevation: 0,
      ),
      backgroundColor: bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reports').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No reports.'));
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
                  title: Text(data['subject'] ?? 'No Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From: ${data['reporterEmail'] ?? ''}', style: TextStyle(fontSize: screenWidth * 0.04)),
                      Text('Type: ${data['type'] ?? ''}', style: TextStyle(fontSize: screenWidth * 0.04)),
                      Text('Status: ${data['status'] ?? 'pending'}', style: TextStyle(fontSize: screenWidth * 0.04)),
                      if (data['message'] != null) Text('Message: ${data['message']}', style: TextStyle(fontSize: screenWidth * 0.04)),
                      if (data['response'] != null) Text('Response: ${data['response']}', style: TextStyle(fontSize: screenWidth * 0.04)),
                    ],
                  ),
                  trailing: data['status'] == 'pending'
                      ? IconButton(
                          icon: Icon(Icons.reply, color: Colors.blue, size: screenWidth * 0.06),
                          onPressed: () async {
                            final response = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                String reply = '';
                                return AlertDialog(
                                  title: const Text('Respond to Report'),
                                  content: TextField(
                                    onChanged: (v) => reply = v,
                                    decoration: const InputDecoration(labelText: 'Response'),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    ElevatedButton(onPressed: () => Navigator.pop(context, reply), child: const Text('Send')),
                                  ],
                                );
                              },
                            );
                            if (response != null && response.isNotEmpty) {
                              await doc.reference.update({'response': response, 'status': 'resolved'});
                            }
                          },
                        )
                      : null,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
} 