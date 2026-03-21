import 'package:flutter/material.dart';
import 'package:cinnalink/l10n/app_localizations.dart'; // Ensure this import exists
import '../backend/auth.dart';
import '../backend/job_repository.dart';

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
  final _phoneController = TextEditingController();

  String? _jobType;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

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

  Future<void> _submitJob() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.loginToPost)));
      return;
    }

    final profile = await AuthService.getCurrentUserProfile();
    final landownerName = (profile?['name'] as String?)?.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      await JobRepository.createJob(
        landownerId: currentUserId,
        landownerName: landownerName == null || landownerName.isEmpty
            ? 'Landowner'
            : landownerName,
        title: _jobTitleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        jobType: _jobType!,
        paymentRate: double.parse(_wageController.text.trim()),
        requiredWorkers: int.parse(_workersController.text.trim()),

        startDate: _selectedDate,
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.jobPostedSuccess)));

      _jobTitleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _wageController.clear();
      _workersController.clear();
      _phoneController.clear();
      setState(() {
        _jobType = null;
        _selectedDate = DateTime.now();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.failedToPost}: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildPostedJobsSection(AppLocalizations l10n) {
    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<List<JobRecord>>(
      stream: JobRepository.streamJobsForLandowner(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Error loading jobs', // You can add a specific key for this if needed
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final jobs = snapshot.data ?? const <JobRecord>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              l10n.yourPostedJobs,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),
            if (jobs.isEmpty)
              Text(
                l10n.noJobsPosted,
                style: const TextStyle(color: Colors.white70),
              )
            else
              ...jobs.map(
                (job) => Card(
                  margin: const EdgeInsets.only(top: 12),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF101917)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.agriculture, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                job.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                job.status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(job.description),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text('${l10n.jobType}: ${job.jobType}'),
                            Text(
                              '${l10n.workersNeeded}: ${job.requiredWorkers}',
                            ),
                            Text(
                              '${l10n.payment}: LKR ${job.paymentRate.toStringAsFixed(0)}',
                            ),
                            Text(
                              '${l10n.startDate}: ${_formatDate(job.startDate)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellTopColors = isDark
        ? const [Color(0xFF1A130F), Color(0xFF352417)]
        : const [Color(0xFF8D5A2B), Color(0xFFC58A45)];
    final inputFill = isDark ? const Color(0xFF241B15) : Colors.grey.shade50;
    final cardColor = isDark ? const Color(0xFF18130F) : Colors.white;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: shellTopColors,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.postNewJob,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.jobSubtitle,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 8,
                  color: cardColor,
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
                              labelText: l10n.jobTitle,
                              hintText: l10n.jobTitleHint,
                              prefixIcon: const Icon(Icons.work),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: inputFill,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l10n.errorTitle
                                : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _jobType,
                            hint: Text(l10n.selectJobType),
                            decoration: InputDecoration(
                              labelText: l10n.jobType,
                              prefixIcon: const Icon(Icons.category),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items:
                                [
                                  "Cinnamon Cutting",
                                  "Cinnamon Peeling",
                                  "Cinnamon Scraping",
                                  "Cinnamon Rolling",
                                  "Cinnamon Drying",
                                  "Cinnamon Grading & Sorting",
                                  "Cinnamon Packing & Transporting",
                                  "Cinnamon Plantation & Maintenance",
                                ].map((job) {
                                  return DropdownMenuItem(
                                    value: job,
                                    child: Text(job),
                                  );
                                }).toList(),
                            onChanged: (value) =>
                                setState(() => _jobType = value),
                            validator: (v) =>
                                (v == null) ? l10n.selectJobType : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: l10n.jobDescription,
                              hintText: l10n.jobDescHint,
                              prefixIcon: const Icon(Icons.description),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: inputFill,
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? l10n.errorDesc
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: l10n.plantationLocation,
                              prefixIcon: const Icon(Icons.location_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: inputFill,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l10n.errorLocation
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _workersController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.workersNeeded,
                              prefixIcon: const Icon(Icons.group),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) {
                              final count = int.tryParse(v ?? '');
                              return (count == null || count <= 0)
                                  ? l10n.errorWorkers
                                  : null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _wageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.payment,
                              prefixIcon: const Icon(Icons.attach_money),
                              suffixText: 'LKR',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: inputFill,
                            ),
                            validator: (v) {
                              final wage = double.tryParse(v ?? '');
                              return (wage == null || wage <= 0)
                                  ? l10n.errorWage
                                  : null;
                            },
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.startDate,
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: inputFill,
                              ),
                              child: Text(_formatDate(_selectedDate)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Contact Number',
                              hintText: 'e.g. 0771234567',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter contact number';
                              }
                              if (value.length != 10) {
                                return 'Enter valid 10-digit number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitJob,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      l10n.postJobButton,
                                      style: const TextStyle(
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
                _buildPostedJobsSection(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _wageController.dispose();
    _workersController.dispose();
    _phoneController.dispose(); // ADD THIS
    super.dispose();
  }
}
