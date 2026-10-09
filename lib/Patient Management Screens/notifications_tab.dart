import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  late final Stream<List<NotificationItem>> _stream =
      BookingService().myNotifications();

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  Widget _msg(String t) => Center(
      child: Text(t,
          style: const TextStyle(fontSize: 12, color: AppColors.gray400)));

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
            child: StreamBuilder<List<NotificationItem>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) return _msg('Could not load notifications');
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!;
                if (items.isEmpty) return _msg('No notifications yet');
                return ListView(
                  children: [
                    for (final n in items)
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
                                  Container(
                                      width: 3, color: AppColors.primary300),
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
                                                child: Text(n.title,
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors
                                                            .primary500)),
                                              ),
                                              Text(_ago(n.createdAt),
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          AppColors.gray400)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(n.body,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}