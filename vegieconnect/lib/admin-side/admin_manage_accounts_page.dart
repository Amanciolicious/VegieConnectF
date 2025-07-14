import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManageAccountsPage extends StatelessWidget {
  const AdminManageAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFFA7C957);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts'),
        backgroundColor: green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No users found.'));
          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(data['name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${data['email'] ?? ''}'),
                      Text('Role: ${data['role'] ?? ''}'),
                      Text('Status: ${data['status'] ?? 'active'}'),
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