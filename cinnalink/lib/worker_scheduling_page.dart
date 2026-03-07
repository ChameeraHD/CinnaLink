import 'package:flutter/material.dart';

class WorkerSchedulingPage extends StatefulWidget {
  const WorkerSchedulingPage({super.key});

  @override
  State<WorkerSchedulingPage> createState() => _WorkerSchedulingPageState();
}

class _WorkerSchedulingPageState extends State<WorkerSchedulingPage> {
  final List<Map<String, dynamic>> _workers = [
    {
      'name': 'Kiri banda',
      'role': 'Cinnamon Harvester',
      'status': 'Available',
      'assignedJob': null,
      'avatar': 'RK',
    },
    {
      'name': 'josapin',
      'role': 'Cinnamon Planter',
      'status': 'Working',
      'assignedJob': 'Cinnamon Planting - Plantation A',
      'avatar': 'PS',
    },
    {
      'name': 'Appuhami',
      'role': 'peeiling',
      'status': 'Available',
      'assignedJob': null,
      'avatar': 'AS',
    },
    {
      'name': 'bandara',
      'role': 'peeiling',
      'status': 'Working',
      'assignedJob': 'Pest Control - Plantation B',
      'avatar': 'SP',
    },
    {
      'name': 'sandanathala',
      'role': 'Cinnamon Processor',
      'status': 'Available',
      'assignedJob': null,
      'avatar': 'KG',
    },
    
  ];

  void _assignJob(int index) {
    // In a real app, this would show a job selection dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Assign Job'),
          content: const Text('Select a cinnamon farming task to assign to this worker.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _workers[index]['status'] = 'Working';
                  _workers[index]['assignedJob'] = 'New Cinnamon Task Assigned';
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job assigned successfully!')),
                );
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  void _markComplete(int index) {
    setState(() {
      _workers[index]['status'] = 'Available';
      _workers[index]['assignedJob'] = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Job marked as complete!')),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Working':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.brown, Colors.orangeAccent],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Worker Scheduling',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your cinnamon plantation workforce and assign tasks',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard('Total Workers', _workers.length.toString(), Colors.blue),
                          _buildStatCard('Available', _workers.where((w) => w['status'] == 'Available').length.toString(), Colors.green),
                          _buildStatCard('Working', _workers.where((w) => w['status'] == 'Working').length.toString(), Colors.orange),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _workers.length,
                    itemBuilder: (context, index) {
                      final worker = _workers[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: _getStatusColor(worker['status']),
                                child: Text(
                                  worker['avatar'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      worker['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      worker['role'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(worker['status']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        worker['status'],
                                        style: TextStyle(
                                          color: _getStatusColor(worker['status']),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (worker['assignedJob'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Assigned: ${worker['assignedJob']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  if (worker['status'] == 'Available')
                                    ElevatedButton(
                                      onPressed: () => _assignJob(index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Assign'),
                                    )
                                  else
                                    ElevatedButton(
                                      onPressed: () => _markComplete(index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Complete'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}