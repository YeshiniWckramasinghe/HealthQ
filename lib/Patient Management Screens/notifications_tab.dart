import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  static const _items = [
    ('Appointment Confirmed', '2h ago',
        'Your appointment at City General Hospital on 22 Sep is confirmed.'),
    ('Queue Update', '3h ago',
        'Queue #09 — 5 patients ahead. Please arrive within 30 minutes.'),
    ('Reminder', '1d ago',
        'Upcoming appointment tomorrow at Teaching Hospital — Dr. R. Fernando.'),
    ('Appointment Completed', '13d ago',
        'Your visit to District Hospital on 03 Sep has been marked complete.'),
    ('System Notice', '14d ago',
        'Scheduled maintenance on 25 Sep from 2:00–4:00 AM.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notifications',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary500)),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              children: [
                for (final n in _items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gray100),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(width: 3, color: AppColors.primary300),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(n.$1,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color:
                                                        AppColors.primary500)),
                                          ),
                                          Text(n.$2,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.gray400)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(n.$3,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              height: 1.4,
                                              color: AppColors.gray400)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}