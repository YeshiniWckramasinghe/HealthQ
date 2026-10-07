import 'dart:async';

import 'package:flutter/material.dart';

import '../services/doctor_service.dart';
import 'doctor_ui.dart';

class DoctorConsultationScreen extends StatefulWidget {
  final DoctorAppointment appointment;

  const DoctorConsultationScreen({super.key, required this.appointment});

  static Future<void> open(BuildContext context, DoctorAppointment appointment) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DoctorConsultationScreen(appointment: appointment),
      ),
    );
  }

  @override
  State<DoctorConsultationScreen> createState() =>
      _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
  static const String _other = 'Other';
  static const List<String> _diagnoses = <String>[
    'Common Cold',
    'Type 2 Diabetes Mellitus (Follow up)',
    'Hypertension',
    'Acute Gastritis',
    'Urinary Tract Infection',
    'Bronchial Asthma',
    'Routine Health Check',
    _other,
  ];

  late final TextEditingController _notes;
  late final TextEditingController _rx;
  late final TextEditingController _otherDx;
  String? _dx;

  // Last values known to be in Firestore - used to detect real edits (a
  // controller listener would also fire on cursor moves).
  String _savedNotes = '';
  String _savedRx = '';
  String _savedDx = '';

  bool _saving = false;
  bool _completing = false;
  bool _completedHere = false;

  bool get _readOnly => widget.appointment.isCompleted;

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    _notes = TextEditingController(text: a.notes ?? '');
    _rx = TextEditingController(text: a.prescription ?? '');
    _otherDx = TextEditingController();

    final saved = a.diagnosis;
    if (saved != null && saved.isNotEmpty) {
      if (_diagnoses.contains(saved)) {
        _dx = saved;
      } else {
        _dx = _other;
        _otherDx.text = saved;
      }
    }

    _savedNotes = _notes.text;
    _savedRx = _rx.text;
    _savedDx = _diagnosisText;
  }

  bool get _hasChanges =>
      _notes.text != _savedNotes ||
      _rx.text != _savedRx ||
      _diagnosisText != _savedDx;

  void _rememberSaved() {
    _savedNotes = _notes.text;
    _savedRx = _rx.text;
    _savedDx = _diagnosisText;
  }

  String get _diagnosisText =>
      _dx == _other ? _otherDx.text.trim() : (_dx ?? '');

  @override
  void dispose() {
    // Don't lose typed notes if the doctor just navigates away.
    if (!_readOnly && !_completedHere && _hasChanges) {
      unawaited(
        DoctorService.instance
            .saveConsultationNotes(
              appointmentId: widget.appointment.id,
              notes: _notes.text,
              diagnosis: _diagnosisText,
              prescription: _rx.text,
            )
            .catchError((Object e) => debugPrint('Draft autosave failed: $e')),
      );
    }
    _notes.dispose();
    _rx.dispose();
    _otherDx.dispose();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    if (_saving || _readOnly) return;
    setState(() => _saving = true);
    try {
      await DoctorService.instance.saveConsultationNotes(
        appointmentId: widget.appointment.id,
        notes: _notes.text,
        diagnosis: _diagnosisText,
        prescription: _rx.text,
      );
      _rememberSaved();
      if (mounted) showDoctorSnack(context, 'Draft saved.');
    } catch (e) {
      if (mounted) showDoctorSnack(context, 'Save failed: ${cleanError(e)}', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _complete() async {
    if (_completing) return;
    final a = widget.appointment;
    final scope = DoctorSessionScope.of(context);

    if (_diagnosisText.isEmpty) {
      showDoctorSnack(
        context,
        _dx == _other
            ? 'Please enter the diagnosis before completing.'
            : 'Please select a diagnosis before completing.',
        error: true,
      );
      return;
    }

    final ok = await showConfirmDialog(
      context,
      title: 'Complete Consultation',
      message:
          'This will mark ${a.patientName} as Completed and the queue will move to the next patient.',
      confirmLabel: 'Complete',
    );
    if (!ok || !mounted) return;

    setState(() => _completing = true);
    try {
      await DoctorService.instance.completeConsultation(
        doctorId: scope.profile.staffId,
        date: a.date,
        appointmentId: a.id,
        notes: _notes.text,
        diagnosis: _diagnosisText,
        prescription: _rx.text,
      );
      _completedHere = true;
      if (!mounted) return;
      showDoctorSnack(context, '${a.patientName} marked as completed.');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) showDoctorSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    final time = DoctorFmt.time12(a.time);

    return DoctorScaffold(
      child: Column(
        children: [
          DoctorPageHeader(
            title: 'Consultation',
            trailing: _readOnly
                ? null
                : PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: DoctorColors.teal),
                    color: Colors.white,
                    onSelected: (v) {
                      if (v == 'save') _saveDraft();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem<String>(
                          value: 'save', child: Text('Save draft')),
                    ],
                  ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                // ── Patient + appointment time ──────────────────────
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: DoctorCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              InitialsAvatar(name: a.patientName, size: 56),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      a.patientName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: DoctorColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      a.demographics,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: DoctorColors.muted),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Patient ID: ${a.patientId}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: DoctorColors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 12, color: DoctorColors.teal),
                                SizedBox(width: 4),
                                Text('Appt Time',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: DoctorColors.muted)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: DoctorColors.teal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DoctorFmt.dateShort(a.date),
                              style: const TextStyle(
                                  fontSize: 10.5, color: DoctorColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (_readOnly) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: DoctorColors.greenBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: DoctorColors.green, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This consultation is completed. Notes are read-only.',
                            style: TextStyle(
                                color: DoctorColors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Consultation notes ──────────────────────────────
                _Section(
                  icon: Icons.assignment_outlined,
                  title: 'Consultation Notes',
                  child: _BoxedField(
                    label: 'Notes',
                    controller: _notes,
                    maxLength: 500,
                    minLines: 4,
                    maxLines: 6,
                    readOnly: _readOnly,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Diagnosis ───────────────────────────────────────
                _Section(
                  icon: Icons.medical_services_outlined,
                  title: 'Diagnosis',
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
                        decoration: _fieldDecoration(_readOnly),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Diagnosis',
                                style: TextStyle(
                                    fontSize: 12, color: DoctorColors.muted)),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _dx,
                                hint: const Text('Select diagnosis',
                                    style: TextStyle(
                                        color: DoctorColors.hint,
                                        fontSize: 14.5)),
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    color: DoctorColors.muted),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: DoctorColors.ink,
                                ),
                                dropdownColor: Colors.white,
                                items: [
                                  for (final d in _diagnoses)
                                    DropdownMenuItem<String>(
                                      value: d,
                                      child: Text(d,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                ],
                                onChanged: _readOnly
                                    ? null
                                    : (v) {
                                        if (v == null) return;
                                        setState(() => _dx = v);
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_dx == _other) ...[
                        const SizedBox(height: 10),
                        _BoxedField(
                          label: 'Specify diagnosis',
                          controller: _otherDx,
                          maxLength: 120,
                          minLines: 1,
                          maxLines: 2,
                          readOnly: _readOnly,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Prescription ────────────────────────────────────
                _Section(
                  icon: Icons.medication_outlined,
                  title: 'Prescription / Medication',
                  child: _BoxedField(
                    label: 'Prescription / Medication',
                    controller: _rx,
                    maxLength: 1000,
                    minLines: 5,
                    maxLines: 8,
                    readOnly: _readOnly,
                  ),
                ),

                // ── Complete ────────────────────────────────────────
                if (!_readOnly) ...[
                  const SizedBox(height: 14),
                  DoctorCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: DoctorColors.greenBg,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.check_circle_outline,
                                  color: DoctorColors.green, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Complete Consultation',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: DoctorColors.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'This patient will be marked as Completed and the queue will move to the next patient.',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: DoctorColors.muted,
                              height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton(
                          label: 'Complete Consultation',
                          icon: Icons.check_rounded,
                          loading: _completing,
                          onPressed: _complete,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _fieldDecoration(bool readOnly) => BoxDecoration(
      color: readOnly ? const Color(0xFFF6F8F8) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFD5E0DF)),
    );

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Section({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DoctorColors.teal, size: 21),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: DoctorColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Text area with the label inside the box and a live "n/max" counter, as in
/// the design.
class _BoxedField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLength;
  final int minLines;
  final int maxLines;
  final bool readOnly;

  const _BoxedField({
    required this.label,
    required this.controller,
    required this.maxLength,
    required this.minLines,
    required this.maxLines,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: _fieldDecoration(readOnly),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: DoctorColors.muted)),
          TextField(
            controller: controller,
            readOnly: readOnly,
            maxLength: maxLength,
            minLines: minLines,
            maxLines: maxLines,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
                fontSize: 14.5, color: DoctorColors.ink, height: 1.4),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.only(top: 8, bottom: 6),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, v, __) => Text(
                '${v.text.length}/$maxLength',
                style: const TextStyle(fontSize: 11.5, color: DoctorColors.hint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
