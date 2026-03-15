import 'package:flutter/material.dart';

class JobPostingPage extends StatefulWidget {
  const JobPostingPage({super.key});

  @override
  State<JobPostingPage> createState() => _JobPostingPageState();
}

class _JobPostingPageState extends State<JobPostingPage> {
  final _formKey = GlobalKey<FormState>();
  final _jobTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _wageController = TextEditingController();
  final _workersController = TextEditingController();

  String? _jobType;
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitJob() {
    if (_formKey.currentState!.validate()) {
      // Here you would typically send the job data to your backend
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job posted successfully!')));
      // Clear form
      _jobTitleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _wageController.clear();
      _workersController.clear();
      setState(() {
        _selectedDate = DateTime.now();
      });
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
            colors: [Colors.greenAccent, Colors.lightGreenAccent],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Post a New Job',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find skilled workers for your cinnamon plantation needs',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _jobTitleController,
                            decoration: InputDecoration(
                              labelText: 'Job Title',
                              hintText: 'e.g., Cinnamon Harvester',
                              prefixIcon: const Icon(Icons.work),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),

                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _jobType,
                            hint: const Text("Select Job Type"),
                            decoration: InputDecoration(
                              labelText: 'Job Type',
                              prefixIcon: Icon(Icons.category),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items:
                                [
                                  'Cinnamon Cutting',
                                  'Cinnamon Peeling',
                                  'Cinnamon Scraping',
                                  'Cinnamon Rolling',
                                ].map((job) {
                                  return DropdownMenuItem(
                                    value: job,
                                    child: Text(job),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _jobType = value;
                              });
                            },

                            validator: (value) {
                              if (value == null) {
                                return 'Please select a job type';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Job Description',
                              hintText:
                                  'Describe the cinnamon farming tasks required',
                              prefixIcon: const Icon(Icons.description),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a job description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: 'Plantation Location',
                              prefixIcon: const Icon(Icons.location_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _workersController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Number of Workers Needed',
                              prefixIcon: Icon(Icons.group),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),

                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter number of workers';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _wageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Payment',
                              prefixIcon: const Icon(Icons.currency_bitcoin),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a wage amount';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Start Date',
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              child: Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _submitJob,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'Post Job',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
