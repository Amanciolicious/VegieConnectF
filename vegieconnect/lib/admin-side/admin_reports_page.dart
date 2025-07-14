import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFFA7C957);
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Reports'),
        backgroundColor: green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reports').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No reports.'));
          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(data['subject'] ?? 'No Subject'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From: ${data['reporterEmail'] ?? ''}'),
                      Text('Type: ${data['type'] ?? ''}'),
                      Text('Status: ${data['status'] ?? 'pending'}'),
                      if (data['message'] != null) Text('Message: ${data['message']}'),
                      if (data['response'] != null) Text('Response: ${data['response']}'),
                    ],
                  ),
                  trailing: data['status'] == 'pending'
                      ? IconButton(
                          icon: const Icon(Icons.reply, color: Colors.blue),
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