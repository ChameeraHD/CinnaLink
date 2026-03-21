import 'package:flutter/material.dart';

import '../backend/job_repository.dart';

class ProfileReviewsSection extends StatelessWidget {
  const ProfileReviewsSection({
    super.key,
    required this.userId,
    required this.summaryTitle,
  });

  final String userId;
  final String summaryTitle;

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Recent';
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _roleLabel(String role) {
    if (role == 'worker') {
      return 'Worker';
    }
    if (role == 'landowner') {
      return 'Landowner';
    }
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDark ? const Color(0xFF14201D) : Colors.grey.shade50;
    final tileBorder =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200;

    return StreamBuilder<List<RatingRecord>>(
      stream: JobRepository.streamRatingsForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Text(
            'Unable to load reviews right now.',
            style: TextStyle(color: Colors.redAccent),
          );
        }

        final ratings = snapshot.data ?? const <RatingRecord>[];
        final total = ratings.length;
        final average = total == 0
            ? 0.0
            : ratings.map((r) => r.rating).reduce((a, b) => a + b) / total;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  average.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      size: 20,
                      color: index < average.round()
                          ? Colors.amber
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '($total)',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              summaryTitle,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (ratings.isEmpty)
              const Text(
                'No ratings yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...ratings.map((review) {
                final role = _roleLabel(review.fromUserRole);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tileBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              review.fromUserName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            _formatDate(review.createdAt),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              Icons.star,
                              size: 16,
                              color: index < review.rating.round()
                                  ? Colors.amber
                                  : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            role,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        review.feedback.isEmpty
                            ? 'No written review.'
                            : review.feedback,
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}