import 'package:flutter/material.dart';

import '../services/doctor_service.dart';
import 'doctor_patient_details_screen.dart';
import 'doctor_ui.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  static const List<String> _filters = <String>['All', 'Scheduled', 'Completed'];

  String _filter = 'All';
  String _query = '';
  final TextEditingController _search = TextEditingController();

  Stream<List<DoctorAppointment>>? _stream;
  String _streamKey = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = DoctorSessionScope.of(context);
    final key = '${s.profile.staffId}|${s.today}';
    if (key != _streamKey) {
      _streamKey = key;
      _stream =
          DoctorService.instance.appointmentsStream(s.profile.staffId, s.today);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _isScheduled(DoctorAppointment a) => a.isWaiting;

  List<DoctorAppointment> _apply(List<DoctorAppointment> all) {
    Iterable<DoctorAppointment> r = all;
    if (_filter == 'Completed') r = r.where((a) => a.isCompleted);
    if (_filter == 'Scheduled') r = r.where(_isScheduled);
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      r = r.where((a) => a.patientName.toLowerCase().contains(q));
    }
    return r.toList();
  }

  @override
  Widget build(BuildContext context) {
    final scope = DoctorSessionScope.of(context);

    return DoctorScaffold(
      child: StreamBuilder<List<DoctorAppointment>>(
        stream: _stream,
        builder: (context, snap) {
          final all = snap.data ?? const <DoctorAppointment>[];
          final loading =
              snap.connectionState == ConnectionState.waiting && !snap.hasData;
          final shown = _apply(all);

          return Column(
            children: [
              DoctorHeader(
                title: 'Today\'s Appointments',
                subtitle: DoctorFmt.headerDate(DateTime.now()),
                // This screen is a tab root, so "back" returns to Home
                // instead of popping the dashboard route.
                onBack: () => scope.switchTab(0),
              ),

              // Filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final f in _filters)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _FilterChip(
                          label: f == 'All' && all.isNotEmpty
                              ? 'All (${all.length})'
                              : f,
                          selected: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DoctorColors.line),
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search patient name...',
                      hintStyle: const TextStyle(
                          color: DoctorColors.hint, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: DoctorColors.muted, size: 21),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: DoctorColors.muted),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // List
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : snap.hasError
                        ? ErrorState(snap.error!)
                        : shown.isEmpty
                            ? EmptyState(
                                icon: Icons.event_busy_outlined,
                                message: all.isEmpty
                                    ? 'No appointments today.'
                                    : 'No appointments match your filter.',
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                itemCount: shown.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) => _AppointmentCard(
                                  appointment: shown[i],
                                  onTap: () => DoctorPatientDetailsScreen.open(
                                      context, shown[i]),
                                ),
                              ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: selected ? DoctorColors.teal : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: selected ? DoctorColors.teal : DoctorColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : DoctorColors.ink,
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final DoctorAppointment appointment;
  final VoidCallback onTap;

  const _AppointmentCard({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = DoctorStatus.appointment(appointment.status);
    final isNext = appointment.isNext;
    final time = DoctorFmt.time12Parts(appointment.time);

    return DoctorCard(
      onTap: onTap,
      radius: 16,
      borderColor: isNext ? DoctorColors.teal : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: isNext ? DoctorColors.tealDark : DoctorColors.teal,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time[0],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: DoctorColors.teal,
                ),
              ),
              Text(
                time[1],
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: DoctorColors.muted),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DoctorColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${appointment.type} · ${appointment.room}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: DoctorColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(style),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: DoctorColors.hint, size: 20),
        ],
      ),
    );
  }
}
