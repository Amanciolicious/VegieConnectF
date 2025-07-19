import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:path/path.dart';
import 'package:vegieconnect/theme.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text('Reports', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055)),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Reports',
              style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.06),
            ),
            SizedBox(height: screenWidth * 0.04),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reports')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Neumorphic(
                        style: AppNeumorphic.card,
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.08),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.assignment,
                                size: screenWidth * 0.15,
                                color: AppColors.primaryGreen,
                              ),
                              SizedBox(height: screenWidth * 0.04),
                              Text(
                                'No Reports',
                                style: AppTextStyles.headline.copyWith(
                                  fontSize: screenWidth * 0.06,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              SizedBox(height: screenWidth * 0.02),
                              Text(
                                'No reports have been submitted yet',
                                style: AppTextStyles.body.copyWith(
                                  fontSize: screenWidth * 0.04,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final reports = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index].data() as Map<String, dynamic>;
                      return _buildReportCard(screenWidth, reports[index].id, report);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(double screenWidth, String reportId, Map<String, dynamic> report) {
    final timestamp = report['timestamp'] as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();
    
    return Neumorphic(
      style: AppNeumorphic.card,
      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.01),
                  decoration: BoxDecoration(
                    color: _getReportTypeColor(report['type']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Text(
                    report['type'] ?? 'Unknown',
                    style: AppTextStyles.body.copyWith(
                      fontSize: screenWidth * 0.035,
                      color: _getReportTypeColor(report['type']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: AppTextStyles.body.copyWith(
                    fontSize: screenWidth * 0.035,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.03),
            // Report Title
            Text(
              report['title'] ?? 'No Title',
              style: AppTextStyles.headline.copyWith(
                fontSize: screenWidth * 0.045,
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            // Report Description
            Text(
              report['description'] ?? 'No description provided',
              style: AppTextStyles.body.copyWith(
                fontSize: screenWidth * 0.04,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            // Reporter Info
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    size: screenWidth * 0.05,
                    color: AppColors.primaryGreen,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      'Reported by: ${report['reporterName'] ?? 'Anonymous'}',
                      style: AppTextStyles.body.copyWith(
                        fontSize: screenWidth * 0.035,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: NeumorphicButton(
                    style: AppNeumorphic.button.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                    onPressed: () => _handleReport(reportId, 'resolved'),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                      child: Text(
                        'Mark Resolved',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: NeumorphicButton(
                    style: AppNeumorphic.button.copyWith(
                      color: Colors.transparent,
                    ),
                    onPressed: () => _handleReport(reportId, 'investigating'),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                      child: Text(
                        'Under Investigation',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.primaryGreen,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getReportTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'bug':
        return Colors.red;
      case 'feature':
        return Colors.blue;
      case 'complaint':
        return Colors.orange;
      case 'suggestion':
        return Colors.purple;
      default:
        return AppColors.primaryGreen;
    }
  }

  Future<void> _handleReport(String reportId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
        'status': status,
        'handledBy': 'admin',
        'handledAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Report status updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Error updating report: $e')),
      );
    }
  }
} 