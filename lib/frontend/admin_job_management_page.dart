import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminJobManagementPage extends StatefulWidget {
  const AdminJobManagementPage({super.key});

  @override
  State<AdminJobManagementPage> createState() => _AdminJobManagementPageState();
}

class _AdminJobManagementPageState extends State<AdminJobManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('jobs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final jobData = jobs[index].data() as Map<String, dynamic>;
              final jobId = jobs[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(jobData['title'] ?? 'Untitled Job'),
                  subtitle: Text(
                    'Posted by: ${jobData['landownerName'] ?? 'Unknown'}\n'
                    'Status: ${jobData['status'] ?? 'Unknown'}\n'
                    'Location: ${jobData['location'] ?? 'Unknown'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleJobAction(value, jobId, jobData),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('View Details'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Job'),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleJobAction(
    String action,
    String jobId,
    Map<String, dynamic> jobData,
  ) {
    switch (action) {
      case 'view':
        _showJobDetailsDialog(jobData);
        break;
      case 'delete':
        _deleteJob(jobId);
        break;
    }
  }

  void _showJobDetailsDialog(Map<String, dynamic> jobData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(jobData['title'] ?? 'Job Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Description: ${jobData['description'] ?? 'No description'}',
              ),
              const SizedBox(height: 8),
              Text('Location: ${jobData['location'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Wage: ${jobData['wage'] ?? 'Not specified'}'),
              const SizedBox(height: 8),
              Text('Status: ${jobData['status'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Posted by: ${jobData['landownerName'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text(
                'Posted on: ${jobData['createdAt']?.toDate()?.toString() ?? 'Unknown'}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteJob(String jobId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text(
          'Are you sure you want to delete this job? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _firestore.collection('jobs').doc(jobId).delete();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job deleted successfully')),
              );
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
