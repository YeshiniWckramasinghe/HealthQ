import 'package:flutter/material.dart';

import '../services/doctor_availability_service.dart';
import '../services/doctor_service.dart';
import 'doctor_availability_requests_screen.dart';
import 'doctor_availability_screen.dart';
import 'doctor_edit_profile_screen.dart';
import 'doctor_request_change_screen.dart';
import 'doctor_ui.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Stream<List<DoctorAvailabilitySlot>>? _slots;
  Stream<List<AvailabilityRequest>>? _requests;
  String _streamKey = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = DoctorSessionScope.of(context).profile.staffId;
    if (id != _streamKey) {
      _streamKey = id;
      _slots = DoctorAvailabilityService.instance.upcomingSlotsStream(id);
      _requests = DoctorAvailabilityService.instance.requestsStream(id);
    }
  }

  void _openDay(String date) {
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
        builder: (_) => DoctorAvailabilityScreen(date: date)));
  }

  Future<void> _openCalendar() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Select a date',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: DoctorColors.teal,
                onPrimary: Colors.white,
              ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null && mounted) _openDay(DoctorService.dateKey(picked));
  }

  @override
  Widget build(BuildContext context) {
    final scope = DoctorSessionScope.of(context);
    final profile = scope.profile;
    final today = DateTime.now();

    return DoctorScaffold(
      child: StreamBuilder<List<DoctorAvailabilitySlot>>(
        stream: _slots,
        builder: (context, slotSnap) {
          return StreamBuilder<List<AvailabilityRequest>>(
            stream: _requests,
            builder: (context, reqSnap) {
              final slotsLoaded = slotSnap.hasData;
              final summary = AvailabilitySummary.fromSlots(
                  slotSnap.data ?? const <DoctorAvailabilitySlot>[]);
              final pending = (reqSnap.data ?? const <AvailabilityRequest>[])
                  .where((r) => r.isPending)
                  .length;

              final days = List<DateTime>.generate(
                  3, (i) => today.add(Duration(days: i)));

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: DoctorColors.ink,
                          ),
                        ),
                      ),
                      const DoctorBell(),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Profile card ──────────────────────────────────
                  DoctorCard(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    radius: 20,
                    child: Column(
                      children: [
                        DoctorAvatar(profile: profile, size: 98),
                        const SizedBox(height: 14),
                        Text(
                          profile.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: DoctorColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.specialty,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: DoctorColors.teal,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          profile.hospital,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: DoctorColors.muted),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          profile.staffId,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: DoctorColors.teal,
                          ),
                        ),
                        const SizedBox(height: 18),
                        OutlineActionButton(
                          label: 'Edit Profile',
                          height: 46,
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                                builder: (_) => const DoctorEditProfileScreen()),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlineActionButton(
                          label: 'Log Out',
                          height: 46,
                          color: DoctorColors.red,
                          onPressed: scope.logout,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── Availability summary ──────────────────────────
                  const SectionTitle('Availability Summary'),
                  const SizedBox(height: 10),
                  DoctorCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryTile(
                                label: 'Next Active',
                                value: !slotsLoaded
                                    ? '…'
                                    : (summary.nextActiveDate == null
                                        ? 'None'
                                        : DoctorFmt.dateShort(
                                            summary.nextActiveDate!)),
                                valueColor: DoctorColors.teal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryTile(
                                label: 'Total Slots',
                                value: !slotsLoaded
                                    ? '…'
                                    : '${summary.totalSlots} Scheduled',
                                valueColor: DoctorColors.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                                builder: (_) =>
                                    const DoctorAvailabilityRequestsScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: DoctorColors.amberBg.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Pending Change Requests',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: DoctorColors.amber,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '$pending Pending',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: DoctorColors.amber,
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        size: 18, color: DoctorColors.amber),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── My availability ───────────────────────────────
                  SectionTitle(
                    'My Availability',
                    trailing: GestureDetector(
                      onTap: _openCalendar,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'View Calendar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: DoctorColors.teal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < days.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _DayCard(
                            date: days[i],
                            slots: summary.slotsPerDate[
                                    DoctorService.dateKey(days[i])] ??
                                0,
                            selected: i == 0,
                            onTap: () => _openDay(DoctorService.dateKey(days[i])),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  PrimaryButton(
                    label: 'Request Availability Change',
                    icon: Icons.calendar_month_outlined,
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                          builder: (_) => const DoctorRequestChangeScreen()),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DoctorColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: DoctorColors.muted)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime date;
  final int slots;
  final bool selected;
  final VoidCallback onTap;

  const _DayCard({
    required this.date,
    required this.slots,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iso = DoctorService.dateKey(date);
    final subColor = selected ? const Color(0xFFD4ECEA) : DoctorColors.muted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? DoctorColors.teal : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(DoctorFmt.weekdayShort(iso),
                style: TextStyle(fontSize: 12.5, color: subColor)),
            const SizedBox(height: 3),
            Text(
              DoctorFmt.dayMonth(iso),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : DoctorColors.ink,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '$slots ${slots == 1 ? 'slot' : 'slots'}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : DoctorColors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
