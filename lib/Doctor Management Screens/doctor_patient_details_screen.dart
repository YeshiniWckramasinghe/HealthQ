import 'package:flutter/material.dart';

import '../services/doctor_patient_service.dart';
import '../services/doctor_service.dart';
import 'doctor_consultation_screen.dart';
import 'doctor_ui.dart';

class DoctorPatientDetailsScreen extends StatefulWidget {
  final DoctorAppointment appointment;
  final int initialTab; // 0 Overview, 1 History, 2 Appointments

  const DoctorPatientDetailsScreen({
    super.key,
    required this.appointment,
    this.initialTab = 0,
  });

  static Future<void> open(BuildContext context, DoctorAppointment appointment,
      {int initialTab = 0}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DoctorPatientDetailsScreen(
          appointment: appointment,
          initialTab: initialTab,
        ),
      ),
    );
  }

  @override
  State<DoctorPatientDetailsScreen> createState() =>
      _DoctorPatientDetailsScreenState();
}

class _DoctorPatientDetailsScreenState
    extends State<DoctorPatientDetailsScreen> {
  static const List<String> _tabs = <String>[
    'Overview',
    'History',
    'Appointments'
  ];

  late int _tab;
  late final Future<PatientRecord> _recordFuture;
  late final Stream<DoctorAppointment?> _apptStream;
  Stream<List<DoctorAppointment>>? _historyStream;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTab;
    _tab = t < 0 ? 0 : (t > 2 ? 2 : t);
    _recordFuture =
        DoctorPatientService.instance.loadRecord(widget.appointment);
    _apptStream =
        DoctorService.instance.appointmentStream(widget.appointment.id);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _historyStream ??= DoctorPatientService.instance.patientAppointmentsStream(
      widget.appointment.patientId,
      DoctorSessionScope.of(context).profile.staffId,
    );
  }

  Future<void> _startOrOpen(DoctorAppointment appt) async {
    if (_starting) return;
    final scope = DoctorSessionScope.of(context);
    final navigator = Navigator.of(context);

    var target = appt;
    if (appt.isWaiting) {
      setState(() => _starting = true);
      try {
        await DoctorService.instance.startConsultation(
          doctorId: scope.profile.staffId,
          date: appt.date,
          appointmentId: appt.id,
        );
        target = appt.copyWith(status: 'in_progress');
      } catch (e) {
        if (mounted) {
          setState(() => _starting = false);
          showDoctorSnack(context, cleanError(e), error: true);
        }
        return;
      }
    }
    if (!mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => DoctorConsultationScreen(appointment: target),
      ),
    );
  }

  String _buttonLabel(DoctorAppointment a) {
    if (a.isCompleted) return 'View Consultation';
    if (a.isInProgress) return 'Continue Consultation';
    return 'Start Consultation';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DoctorAppointment?>(
      stream: _apptStream,
      initialData: widget.appointment,
      builder: (context, apptSnap) {
        final appt = apptSnap.data ?? widget.appointment;

        return DoctorScaffold(
          child: Column(
            children: [
              DoctorPageHeader(
                title:
                    _tab == 1 ? 'Patient Medical History' : 'Patient Details',
                trailing: _tab == 1
                    ? PopupMenuButton<int>(
                        icon: const Icon(Icons.more_horiz,
                            color: DoctorColors.teal),
                        color: Colors.white,
                        onSelected: (i) => setState(() => _tab = i),
                        itemBuilder: (_) => const [
                          PopupMenuItem<int>(value: 0, child: Text('Overview')),
                          PopupMenuItem<int>(
                              value: 2, child: Text('Appointments')),
                        ],
                      )
                    : null,
              ),
              Expanded(
                child: FutureBuilder<PatientRecord>(
                  future: _recordFuture,
                  builder: (context, recSnap) {
                    final record =
                        recSnap.data ?? PatientRecord.fromAppointment(appt);
                    final loading =
                        recSnap.connectionState == ConnectionState.waiting;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      children: [
                        _PatientCard(record: record),
                        const SizedBox(height: 16),
                        _TabBar(
                          tabs: _tabs,
                          selected: _tab,
                          onSelect: (i) => setState(() => _tab = i),
                        ),
                        const SizedBox(height: 16),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_tab == 0)
                          _OverviewTab(record: record)
                        else if (_tab == 1)
                          _HistoryTab(
                              record: record, historyStream: _historyStream)
                        else
                          _AppointmentsTab(
                            currentId: appt.id,
                            historyStream: _historyStream,
                          ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: PrimaryButton(
                  label: _buttonLabel(appt),
                  icon: _tab == 1 ? Icons.medical_services_outlined : null,
                  loading: _starting,
                  onPressed: () => _startOrOpen(appt),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final PatientRecord record;
  const _PatientCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          InitialsAvatar(name: record.name, size: 68),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: DoctorColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.demographics,
                  style: const TextStyle(
                      fontSize: 13, color: DoctorColors.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  'Patient ID: ${record.patientId}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DoctorColors.teal,
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

class _TabBar extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  const _TabBar(
      {required this.tabs, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DoctorColors.line, width: 1.5)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == selected
                            ? DoctorColors.teal
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(
                    tabs[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: i == selected
                          ? DoctorColors.teal
                          : DoctorColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Overview ────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final PatientRecord record;
  const _OverviewTab({required this.record});

  @override
  Widget build(BuildContext context) {
    final rows = <PatientNote>[
      ...record.overview,
      PatientNote(
        title: 'Allergies',
        subtitle: record.allergySummary,
        details: record.allergies.isEmpty
            ? ''
            : record.allergies
                .map((a) =>
                    a.subtitle.isEmpty ? a.title : '${a.title} - ${a.subtitle}')
                .join('\n'),
      ),
    ];

    String orDash(String v) => v.trim().isEmpty ? 'Not recorded' : v;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Info',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: DoctorColors.ink)),
        const SizedBox(height: 10),
        DoctorCard(
          child: Column(
            children: [
              _InfoRow(label: 'Phone', value: orDash(record.phone)),
              const SizedBox(height: 14),
              _InfoRow(label: 'Address', value: orDash(record.address)),
              const SizedBox(height: 14),
              _InfoRow(
                label: 'Blood Group',
                value: orDash(record.bloodGroup),
                valueColor: record.bloodGroup.trim().isEmpty
                    ? DoctorColors.muted
                    : DoctorColors.red,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Medical History',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: DoctorColors.ink)),
        const SizedBox(height: 10),
        DoctorCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _ExpandRow(note: rows[i]),
                if (i < rows.length - 1)
                  const Divider(height: 1, color: DoctorColors.line),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor = DoctorColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(label,
              style:
                  const TextStyle(fontSize: 14, color: DoctorColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandRow extends StatefulWidget {
  final PatientNote note;
  const _ExpandRow({required this.note});

  @override
  State<_ExpandRow> createState() => _ExpandRowState();
}

class _ExpandRowState extends State<_ExpandRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.note;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: DoctorColors.teal, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: DoctorColors.ink,
                        ),
                      ),
                      if (n.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(n.subtitle,
                            style: const TextStyle(
                                fontSize: 12.5, color: DoctorColors.muted)),
                      ],
                    ],
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  color: DoctorColors.muted,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 0, 0, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                n.details.isEmpty ? 'No additional notes recorded.' : n.details,
                style: const TextStyle(
                    fontSize: 13, color: DoctorColors.muted, height: 1.45),
              ),
            ),
          ),
      ],
    );
  }
}

// ── History ─────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final PatientRecord record;
  final Stream<List<DoctorAppointment>>? historyStream;

  const _HistoryTab({required this.record, required this.historyStream});

  String _line(PatientNote n, {String sep = ' '}) =>
      n.subtitle.isEmpty ? n.title : '${n.title}$sep(${n.subtitle})';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HistoryCard(
          icon: Icons.warning_amber_rounded,
          iconColor: DoctorColors.red,
          title: 'Allergies',
          sheetTitle: 'Allergies',
          lines: [for (final a in record.allergies) _line(a)],
          emptyText: 'No known allergies',
        ),
        const SizedBox(height: 12),
        _HistoryCard(
          icon: Icons.medical_services_outlined,
          iconColor: DoctorColors.teal,
          title: 'Previous Conditions',
          sheetTitle: 'Previous Conditions',
          lines: [for (final c in record.conditions) _line(c)],
          emptyText: 'No previous conditions recorded',
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<DoctorAppointment>>(
          stream: historyStream,
          builder: (context, snap) {
            final visits = DoctorPatientService.buildVisits(
                record, snap.data ?? const <DoctorAppointment>[]);
            final lines = [
              for (final v in visits)
                '${DoctorFmt.dateShort(v.date)}|${v.title}',
            ];
            return _HistoryCard(
              icon: Icons.event_note_outlined,
              iconColor: DoctorColors.teal,
              title: 'Previous Visits',
              sheetTitle: 'Previous Visits',
              lines: lines,
              previewCount: 3,
              emptyText: 'No previous visits recorded',
              datedLines: true,
            );
          },
        ),
        const SizedBox(height: 12),
        _HistoryCard(
          icon: Icons.medication_outlined,
          iconColor: DoctorColors.teal,
          title: 'Current Medications',
          sheetTitle: 'Current Medications',
          lines: [
            for (final m in record.medications)
              m.subtitle.isEmpty ? m.title : '${m.title} – ${m.subtitle}',
          ],
          emptyText: 'No current medications',
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String sheetTitle;
  final List<String> lines;
  final String emptyText;
  final int previewCount;

  /// Lines formatted as "date|text" render the date in teal.
  final bool datedLines;

  const _HistoryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.sheetTitle,
    required this.lines,
    required this.emptyText,
    this.previewCount = 4,
    this.datedLines = false,
  });

  Widget _row(String line, {double size = 14}) {
    if (datedLines && line.contains('|')) {
      final i = line.indexOf('|');
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: line.substring(0, i),
                style: const TextStyle(
                    color: DoctorColors.teal, fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: ' – ${line.substring(i + 1)}',
                style: const TextStyle(color: DoctorColors.ink),
              ),
            ],
          ),
          style: TextStyle(fontSize: size),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('• $line',
          style: TextStyle(fontSize: size, color: DoctorColors.ink)),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sheetTitle,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: DoctorColors.ink)),
                const SizedBox(height: 12),
                Flexible(
                  child: lines.isEmpty
                      ? Text(emptyText,
                          style: const TextStyle(color: DoctorColors.muted))
                      : ListView(
                          shrinkWrap: true,
                          children: [for (final l in lines) _row(l, size: 15)],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = lines.take(previewCount).toList();
    return DoctorCard(
      onTap: () => _openSheet(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 21),
                    const SizedBox(width: 8),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: DoctorColors.ink)),
                  ],
                ),
                const SizedBox(height: 10),
                if (shown.isEmpty)
                  Text(emptyText,
                      style: const TextStyle(
                          fontSize: 13.5, color: DoctorColors.muted))
                else
                  for (final l in shown) _row(l),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.chevron_right, color: DoctorColors.hint),
          ),
        ],
      ),
    );
  }
}

// ── Appointments ────────────────────────────────────────────────────────────

class _AppointmentsTab extends StatelessWidget {
  final String currentId;
  final Stream<List<DoctorAppointment>>? historyStream;

  const _AppointmentsTab({required this.currentId, required this.historyStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DoctorAppointment>>(
      stream: historyStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ErrorState(snap.error!));
        }
        final list = snap.data ?? const <DoctorAppointment>[];
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: EmptyState(
                icon: Icons.event_busy_outlined,
                message: 'No appointments found for this patient.'),
          );
        }
        return Column(
          children: [
            for (final a in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DoctorCard(
                  radius: 14,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  onTap: a.isCompleted && a.id != currentId
                      ? () => DoctorConsultationScreen.open(context, a)
                      : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${DoctorFmt.dateShort(a.date)} · ${DoctorFmt.time12(a.time)}',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: DoctorColors.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              a.diagnosis != null
                                  ? '${a.type} · ${a.diagnosis}'
                                  : a.type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5, color: DoctorColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(DoctorStatus.appointment(a.status)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
