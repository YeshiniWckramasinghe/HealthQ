import 'package:flutter/material.dart';

import '../services/doctor_availability_service.dart';
import 'doctor_request_change_screen.dart';
import 'doctor_request_details_screen.dart';
import 'doctor_ui.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  /// yyyy-MM-dd
  final String date;

  const DoctorAvailabilityScreen({super.key, required this.date});

  @override
  State<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  Stream<List<DoctorAvailabilitySlot>>? _stream;
  String _streamKey = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = DoctorSessionScope.of(context).profile.staffId;
    final key = '$id|${widget.date}';
    if (key != _streamKey) {
      _streamKey = key;
      _stream =
          DoctorAvailabilityService.instance.slotsStream(id, widget.date);
    }
  }

  void _onSlotTap(DoctorAvailabilitySlot slot) {
    if (slot.hasRequest) {
      Navigator.of(context).push<void>(MaterialPageRoute<void>(
        builder: (_) => DoctorRequestDetailsScreen(requestId: slot.requestId!),
      ));
    } else {
      Navigator.of(context).push<void>(MaterialPageRoute<void>(
        builder: (_) => DoctorRequestChangeScreen(
            initialDate: slot.date, initialSlotId: slot.id),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = DoctorSessionScope.of(context).profile;
    final dept = profile.department.isEmpty ? 'OPD' : profile.department;

    return DoctorScaffold(
      child: Column(
        children: [
          const DoctorPageHeader(title: 'Available Time Slots'),
          Expanded(
            child: StreamBuilder<List<DoctorAvailabilitySlot>>(
              stream: _stream,
              builder: (context, snap) {
                final slots = snap.data ?? const <DoctorAvailabilitySlot>[];
                final loading = snap.connectionState ==
                        ConnectionState.waiting &&
                    !snap.hasData;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  children: [
                    DoctorCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  color: DoctorColors.teal, size: 19),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  DoctorFmt.dateLongWithDay(widget.date),
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: DoctorColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(Icons.apartment_rounded,
                                  color: DoctorColors.muted, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '$dept - ${profile.hospitalShort}',
                                  style: const TextStyle(
                                      fontSize: 13, color: DoctorColors.muted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (snap.hasError)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: ErrorState(snap.error!),
                      )
                    else if (slots.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: EmptyState(
                          icon: Icons.event_busy_outlined,
                          message: 'No time slots are scheduled for this day.',
                        ),
                      )
                    else
                      for (final s in slots)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SlotRow(slot: s, onTap: () => _onSlotTap(s)),
                        ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: PrimaryButton(
              label: 'Request Status Change',
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      DoctorRequestChangeScreen(initialDate: widget.date),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final DoctorAvailabilitySlot slot;
  final VoidCallback onTap;

  const _SlotRow({required this.slot, required this.onTap});

  Color _clockColor(String s) {
    switch (s) {
      case 'unavailable':
        return DoctorColors.hint;
      case 'pending':
        return DoctorColors.amber;
      case 'approved':
        return DoctorColors.blue;
      case 'rejected':
        return DoctorColors.red;
      default:
        return DoctorColors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = slot.displayStatus;
    final greyed = display == 'unavailable';

    return DoctorCard(
      onTap: onTap,
      radius: 14,
      color: greyed ? const Color(0xFFF6F8F8) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, color: _clockColor(display), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              slot.label,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: greyed ? DoctorColors.hint : DoctorColors.ink,
              ),
            ),
          ),
          StatusChip(DoctorStatus.slot(display)),
        ],
      ),
    );
  }
}
