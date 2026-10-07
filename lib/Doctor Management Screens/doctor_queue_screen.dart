import 'package:flutter/material.dart';

import '../services/doctor_service.dart';
import 'doctor_consultation_screen.dart';
import 'doctor_patient_details_screen.dart';
import 'doctor_ui.dart';

class DoctorQueueScreen extends StatefulWidget {
  const DoctorQueueScreen({super.key});

  @override
  State<DoctorQueueScreen> createState() => _DoctorQueueScreenState();
}

class _DoctorQueueScreenState extends State<DoctorQueueScreen> {
  Stream<List<DoctorAppointment>>? _stream;
  String _streamKey = '';
  bool _busy = false;

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

  Future<void> _callNext(List<DoctorAppointment> inProgress) async {
    if (_busy) return;
    final scope = DoctorSessionScope.of(context);

    if (inProgress.isNotEmpty) {
      final go = await showConfirmDialog(
        context,
        title: 'Call next patient?',
        message:
            '${inProgress.first.patientName} is still in consultation. Call the next patient anyway?',
        confirmLabel: 'Call Next',
      );
      if (!go || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      final called = await DoctorService.instance
          .callNext(doctorId: scope.profile.staffId, date: scope.today);
      if (mounted) {
        showDoctorSnack(context, 'Calling ${called.patientName}…');
      }
    } catch (e) {
      if (mounted) showDoctorSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _quickComplete(DoctorAppointment a) async {
    final scope = DoctorSessionScope.of(context);
    final ok = await showConfirmDialog(
      context,
      title: 'Complete consultation?',
      message:
          'Mark ${a.patientName} as Completed. To add notes or a prescription first, open the consultation instead.',
      confirmLabel: 'Complete',
    );
    if (!ok || !mounted) return;
    try {
      await DoctorService.instance.completeConsultation(
        doctorId: scope.profile.staffId,
        date: a.date,
        appointmentId: a.id,
        notes: a.notes,
        diagnosis: a.diagnosis,
        prescription: a.prescription,
      );
      if (mounted) {
        showDoctorSnack(context, '${a.patientName} marked as completed.');
      }
    } catch (e) {
      if (mounted) showDoctorSnack(context, cleanError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DoctorScaffold(
      child: StreamBuilder<List<DoctorAppointment>>(
        stream: _stream,
        builder: (context, snap) {
          final all = snap.data ?? const <DoctorAppointment>[];
          final loading =
              snap.connectionState == ConnectionState.waiting && !snap.hasData;

          final inProgress = all.where((a) => a.isInProgress).toList();
          final next = all.where((a) => a.isNext).firstOrNull ??
              all.where((a) => a.isUpcoming).firstOrNull;
          final waiting = all
              .where((a) => a.isUpcoming && a.id != next?.id)
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.menu_rounded,
                        color: DoctorColors.teal, size: 26),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Consultation Queue',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: DoctorColors.ink,
                        ),
                      ),
                    ),
                    const DoctorBell(),
                  ],
                ),
              ),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : snap.hasError
                        ? ErrorState(snap.error!)
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            children: [
                              const _Label('NOW CONSULTING'),
                              const SizedBox(height: 10),
                              if (inProgress.isEmpty)
                                const DoctorCard(
                                  child: Text(
                                    'No patient is in consultation.',
                                    style: TextStyle(color: DoctorColors.muted),
                                  ),
                                )
                              else
                                for (final a in inProgress)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _NowConsultingCard(
                                      appointment: a,
                                      onTap: () =>
                                          DoctorConsultationScreen.open(
                                              context, a),
                                      onComplete: () => _quickComplete(a),
                                    ),
                                  ),
                              const SizedBox(height: 14),
                              const _Label('NEXT PATIENT'),
                              const SizedBox(height: 10),
                              if (next == null)
                                const DoctorCard(
                                  child: Text(
                                    'No patients waiting.',
                                    style: TextStyle(color: DoctorColors.muted),
                                  ),
                                )
                              else
                                _NextPatientCard(
                                  appointment: next,
                                  busy: _busy,
                                  onTap: () => DoctorPatientDetailsScreen.open(
                                      context, next),
                                  onCallNext: () => _callNext(inProgress),
                                ),
                              const SizedBox(height: 22),
                              Text(
                                'Waiting List (${waiting.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: DoctorColors.ink,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (waiting.isEmpty)
                                const DoctorCard(
                                  child: Text(
                                    'Nobody else is waiting.',
                                    style: TextStyle(color: DoctorColors.muted),
                                  ),
                                )
                              else
                                for (final a in waiting)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _WaitingRow(
                                      appointment: a,
                                      onTap: () =>
                                          DoctorPatientDetailsScreen.open(
                                              context, a),
                                    ),
                                  ),
                            ],
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: DoctorColors.muted,
      ),
    );
  }
}

class _NowConsultingCard extends StatelessWidget {
  final DoctorAppointment appointment;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const _NowConsultingCard({
    required this.appointment,
    required this.onTap,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
        decoration: BoxDecoration(
          color: DoctorColors.teal,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: DoctorColors.teal.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
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
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Queue No: ${appointment.queueNo.toString().padLeft(2, '0')} · ${DoctorFmt.time12(appointment.time)}',
                    style: const TextStyle(
                        color: Color(0xFFD4ECEA), fontSize: 12.5),
                  ),
                ],
              ),
            ),
            // Tap the tick to complete without opening the notes screen.
            IconButton(
              tooltip: 'Complete consultation',
              onPressed: onComplete,
              icon: const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextPatientCard extends StatelessWidget {
  final DoctorAppointment appointment;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onCallNext;

  const _NextPatientCard({
    required this.appointment,
    required this.busy,
    required this.onTap,
    required this.onCallNext,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      onTap: onTap,
      borderColor: DoctorColors.teal,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: DoctorColors.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Queue No: ${appointment.queueNo.toString().padLeft(2, '0')} · ${DoctorFmt.time12(appointment.time)}',
                  style: const TextStyle(
                      color: DoctorColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: busy ? null : onCallNext,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: DoctorColors.greenBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: DoctorColors.green),
                    )
                  : const Text(
                      'Call Next',
                      style: TextStyle(
                        color: DoctorColors.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingRow extends StatelessWidget {
  final DoctorAppointment appointment;
  final VoidCallback onTap;

  const _WaitingRow({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      onTap: onTap,
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              appointment.queueNo.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: DoctorColors.teal,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  DoctorFmt.time12(appointment.time),
                  style: const TextStyle(
                      fontSize: 12, color: DoctorColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(DoctorStatus.appointment(appointment.status,
              waiting: true)),
        ],
      ),
    );
  }
}
