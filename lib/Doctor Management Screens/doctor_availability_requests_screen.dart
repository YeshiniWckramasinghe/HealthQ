import 'package:flutter/material.dart';

import '../services/doctor_availability_service.dart';
import 'doctor_request_details_screen.dart';
import 'doctor_ui.dart';

class DoctorAvailabilityRequestsScreen extends StatefulWidget {
  const DoctorAvailabilityRequestsScreen({super.key});

  @override
  State<DoctorAvailabilityRequestsScreen> createState() =>
      _DoctorAvailabilityRequestsScreenState();
}

class _DoctorAvailabilityRequestsScreenState
    extends State<DoctorAvailabilityRequestsScreen> {
  // Value stored in the request's `status` field (null = no filter).
  static const List<List<String?>> _filters = <List<String?>>[
    <String?>['All', null],
    <String?>['Pending', 'pending'],
    <String?>['Approved', 'approved'],
    <String?>['Rejected', 'rejected'],
  ];

  String? _filter;
  Stream<List<AvailabilityRequest>>? _stream;
  String _streamKey = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = DoctorSessionScope.of(context).profile.staffId;
    if (id != _streamKey) {
      _streamKey = id;
      _stream = DoctorAvailabilityService.instance.requestsStream(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DoctorScaffold(
      child: Column(
        children: [
          const DoctorPageHeader(title: 'Availability Requests'),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f[1]),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: _filter == f[1]
                              ? DoctorColors.teal
                              : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: _filter == f[1]
                                ? DoctorColors.teal
                                : DoctorColors.line,
                          ),
                        ),
                        child: Text(
                          f[0]!,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _filter == f[1]
                                ? Colors.white
                                : DoctorColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<List<AvailabilityRequest>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return ErrorState(snap.error!);

                final all = snap.data ?? const <AvailabilityRequest>[];
                final shown = _filter == null
                    ? all
                    : all.where((r) => r.status == _filter).toList();

                if (shown.isEmpty) {
                  return EmptyState(
                    icon: Icons.inbox_outlined,
                    message: all.isEmpty
                        ? 'You have not submitted any availability requests yet.'
                        : 'No requests match this filter.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _RequestCard(
                    request: shown[i],
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => DoctorRequestDetailsScreen(
                          requestId: shown[i].id,
                          initial: shown[i],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final AvailabilityRequest request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DoctorFmt.dateLong(request.date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: DoctorColors.ink,
                  ),
                ),
              ),
              StatusChip(DoctorStatus.request(request.status)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 18, color: DoctorColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${request.slotLabel} · ${DoctorStatus.availabilityLabel(request.requestedStatus)} Requested',
                  style: const TextStyle(
                      fontSize: 13, color: DoctorColors.muted),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: DoctorColors.line),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Submitted: ${DoctorFmt.dateShortOf(request.submittedAt)}',
                  style: const TextStyle(
                      fontSize: 12.5, color: DoctorColors.muted),
                ),
              ),
              const Text(
                'View Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: DoctorColors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
