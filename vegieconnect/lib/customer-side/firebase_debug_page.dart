import 'package:flutter/material.dart';
import '../services/firebase_test_service.dart';
import '../theme.dart';

class FirebaseDebugPage extends StatefulWidget {
  const FirebaseDebugPage({super.key});

  @override
  State<FirebaseDebugPage> createState() => _FirebaseDebugPageState();
}

class _FirebaseDebugPageState extends State<FirebaseDebugPage> {
  Map<String, dynamic> _connectionResults = {};
  Map<String, dynamic> _cartResults = {};
  Map<String, dynamic> _securityResults = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text('Firebase Debug', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase Connection Debug',
              style: AppTextStyles.headline,
            ),
            const SizedBox(height: 8),
            Text(
              'This page helps diagnose Firebase permission and connection issues.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isLoading ? 'Testing...' : 'Test Connection'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Test Cart'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testSecurity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Test Security'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_connectionResults.isNotEmpty) ...[
                      _buildResultSection('Connection Test Results', _connectionResults),
                      const SizedBox(height: 16),
                    ],
                    if (_cartResults.isNotEmpty) ...[
                      _buildResultSection('Cart Test Results', _cartResults),
                      const SizedBox(height: 16),
                    ],
                    if (_securityResults.isNotEmpty) ...[
                      _buildResultSection('Security Test Results', _securityResults),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String title, Map<String, dynamic> results) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...results.entries.map((entry) {
              final key = entry.key;
              final value = entry.value;
              final isError = key.contains('error') || key.contains('Error');
              final isSuccess = value == true || (value is String && !value.contains('error'));
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isError ? Icons.error : (isSuccess ? Icons.check_circle : Icons.info),
                      color: isError ? Colors.red : (isSuccess ? Colors.green : Colors.blue),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            key,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isError ? Colors.red : null,
                            ),
                          ),
                          if (value != null && value.toString().isNotEmpty)
                            Text(
                              value.toString(),
                              style: AppTextStyles.caption.copyWith(
                                color: isError ? Colors.red : AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _connectionResults.clear();
    });

    try {
      final results = await FirebaseTestService.testFirebaseConnection();
      setState(() {
        _connectionResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _connectionResults = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  Future<void> _testCart() async {
    setState(() {
      _isLoading = true;
      _cartResults.clear();
    });

    try {
      final results = await FirebaseTestService.testCartOperations();
      setState(() {
        _cartResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _cartResults = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  Future<void> _testSecurity() async {
    setState(() {
      _isLoading = true;
      _securityResults.clear();
    });

    try {
      final results = await FirebaseTestService.getSecurityRulesStatus();
      setState(() {
        _securityResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _securityResults = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }
} 