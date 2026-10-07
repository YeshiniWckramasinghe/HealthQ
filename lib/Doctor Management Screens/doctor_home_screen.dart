import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/doctor_service.dart';
import 'doctor_patient_details_screen.dart';
import 'doctor_ui.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
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

  /// Three rows centred on where the doctor is in the day: one finished
  /// visit for context, then the current / upcoming ones.
  List<DoctorAppointment> _preview(List<DoctorAppointment> all) {
    if (all.isEmpty) return const <DoctorAppointment>[];
    final firstActive = all.indexWhere((a) => !a.isCompleted);
    final start = firstActive < 0
        ? math.max(0, all.length - 3)
        : math.max(0, firstActive - 1);
    return all.skip(start).take(3).toList();
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
          final stats = DoctorService.instance.computeStats(all);
          final nextPatient = all.where((a) => a.isNext).firstOrNull ??
              all.where((a) => a.isUpcoming).firstOrNull;
          final preview = _preview(all);
          final percent = (stats.progressPercent * 100).round();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // ── Header ───────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DoctorFmt.greeting()}, ${scope.profile.name}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: DoctorColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DoctorFmt.headerDate(DateTime.now()),
                          style: const TextStyle(
                              fontSize: 13, color: DoctorColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const DoctorBell(),
                ],
              ),
              const SizedBox(height: 20),

              if (snap.hasError) ...[
                DoctorCard(
                  child: Text(
                    'Could not load today\'s appointments.\n${cleanError(snap.error!)}',
                    style: const TextStyle(color: DoctorColors.red),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Stats ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.calendar_today_rounded,
                      iconColor: DoctorColors.blue,
                      iconBg: DoctorColors.blueBg,
                      value: stats.totalAppointments,
                      label: 'Total Appointments',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.hourglass_bottom_rounded,
                      iconColor: DoctorColors.orange,
                      iconBg: DoctorColors.orangeBg,
                      value: stats.waitingPatients,
                      label: 'Waiting Patients',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.medical_services_outlined,
                      iconColor: DoctorColors.teal,
                      iconBg: DoctorColors.tealSoft,
                      value: stats.inConsultation,
                      label: 'In Consultation',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: DoctorColors.green,
                      iconBg: DoctorColors.greenBg,
                      value: stats.completed,
                      label: 'Completed Tasks',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Today's overview ─────────────────────────────────
              DoctorCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 62,
                      height: 62,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 62,
                            height: 62,
                            child: CircularProgressIndicator(
                              value: stats.progressPercent,
                              strokeWidth: 6,
                              backgroundColor: DoctorColors.tealSoft,
                              color: DoctorColors.teal,
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: DoctorColors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today\'s Overview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: DoctorColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stats.completed} out of ${stats.totalAppointments} Appointments done',
                            style: const TextStyle(
                                fontSize: 13, color: DoctorColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── Next patient ─────────────────────────────────────
              const SectionTitle('Next Patient'),
              const SizedBox(height: 10),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (nextPatient != null)
                _NextPatientCard(
                  appointment: nextPatient,
                  onTap: () => DoctorPatientDetailsScreen.open(
                      context, nextPatient),
                )
              else
                const DoctorCard(
                  child: Center(
                    child: Text('No patients waiting.',
                        style: TextStyle(color: DoctorColors.muted)),
                  ),
                ),
              const SizedBox(height: 22),

              // ── Today's appointments ─────────────────────────────
              SectionTitle(
                'Today\'s Appointments',
                trailing: GestureDetector(
                  onTap: () => scope.switchTab(1),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DoctorColors.teal,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (!loading && preview.isEmpty)
                const DoctorCard(
                  child: Center(
                    child: Text('No appointments today.',
                        style: TextStyle(color: DoctorColors.muted)),
                  ),
                )
              else
                for (final a in preview)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AppointmentRow(
                      appointment: a,
                      onTap: () =>
                          DoctorPatientDetailsScreen.open(context, a),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final int value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: DoctorColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: DoctorColors.muted),
          ),
        ],
      ),
    );
  }
}

class _NextPatientCard extends StatelessWidget {
  final DoctorAppointment appointment;
  final VoidCallback onTap;

  const _NextPatientCard({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = DoctorFmt.time12Parts(appointment.time);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DoctorColors.teal,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: DoctorColors.teal.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    t[1],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Token #${appointment.queueNo.toString().padLeft(2, '0')} · ${appointment.room}',
                    style: const TextStyle(
                        color: Color(0xFFD4ECEA), fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final DoctorAppointment appointment;
  final VoidCallback onTap;

  const _AppointmentRow({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = DoctorStatus.appointment(appointment.status, waiting: true);
    return DoctorCard(
      onTap: onTap,
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          InitialsAvatar(
            name: appointment.patientName,
            size: 42,
            color: DoctorColors.tealSoft,
            textColor: DoctorColors.teal,
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
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: DoctorColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DoctorFmt.time12(appointment.time)} · Token #${appointment.queueNo.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 12, color: DoctorColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(style),
        ],
      ),
    );
  }
}
