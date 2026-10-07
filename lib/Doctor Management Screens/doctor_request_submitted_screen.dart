import 'package:flutter/material.dart';

import '../services/doctor_availability_service.dart';
import 'doctor_availability_requests_screen.dart';
import 'doctor_ui.dart';

class DoctorRequestSubmittedScreen extends StatelessWidget {
  final AvailabilityRequest request;

  const DoctorRequestSubmittedScreen({super.key, required this.request});

  Widget _row(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: DoctorColors.muted)),
          const Spacer(),
          value,
        ],
      ),
    );
  }

  Widget _bold(String text, {Color color = DoctorColors.ink}) => Text(
        text,
        style: TextStyle(
            fontSize: 14.5, fontWeight: FontWeight.w800, color: color),
      );

  @override
  Widget build(BuildContext context) {
    final requested = request.requestedStatus;

    return DoctorScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
        children: [
          Center(
            child: Container(
              width: 128,
              height: 128,
              decoration: const BoxDecoration(
                color: DoctorColors.greenBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: DoctorColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 46),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Request Submitted!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: DoctorColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hospital admin staff have been notified.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: DoctorColors.muted),
          ),
          const SizedBox(height: 28),
          DoctorCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              children: [
                _row('Request ID', _bold(request.id)),
                const Divider(height: 1, color: DoctorColors.line),
                _row('Requested Date', _bold(DoctorFmt.dateLong(request.date))),
                const Divider(height: 1, color: DoctorColors.line),
                _row('Time Slot', _bold(request.slotLabel)),
                const Divider(height: 1, color: DoctorColors.line),
                _row(
                  'Requested Status',
                  _bold(
                    DoctorStatus.availabilityLabel(requested),
                    color: DoctorStatus.availability(requested),
                  ),
                ),
                const Divider(height: 1, color: DoctorColors.line),
                _row(
                  'Status',
                  const StatusChip(StatusStyle(
                      'Pending Staff Approval',
                      DoctorColors.amber,
                      DoctorColors.amberBg)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'View My Requests',
            onPressed: () {
              final nav = Navigator.of(context);
              nav.popUntil((r) => r.isFirst);
              nav.push<void>(MaterialPageRoute<void>(
                  builder: (_) => const DoctorAvailabilityRequestsScreen()));
            },
          ),
          const SizedBox(height: 12),
          OutlineActionButton(
            label: 'Back to Profile',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    );
  }
}
