import 'package:flutter/material.dart';

import '../services/doctor_availability_service.dart';
import 'doctor_request_submitted_screen.dart';
import 'doctor_ui.dart';

class DoctorRequestChangeScreen extends StatefulWidget {
  final String? initialDate;
  final String? initialSlotId;

  const DoctorRequestChangeScreen({
    super.key,
    this.initialDate,
    this.initialSlotId,
  });

  @override
  State<DoctorRequestChangeScreen> createState() =>
      _DoctorRequestChangeScreenState();
}

class _DoctorRequestChangeScreenState extends State<DoctorRequestChangeScreen> {
  final TextEditingController _reason = TextEditingController();

  // Raw user selections. The values actually used are derived in build() so
  // they always stay valid when the slot list changes under us.
  String? _date;
  String? _slotId;
  String? _requested; // null = "opposite of current"

  String? _reasonError;
  String? _formError;
  bool _submitting = false;

  Stream<List<DoctorAvailabilitySlot>>? _stream;
  String _streamKey = '';

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _slotId = widget.initialSlotId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = DoctorSessionScope.of(context).profile.staffId;
    if (id != _streamKey) {
      _streamKey = id;
      _stream = DoctorAvailabilityService.instance.upcomingSlotsStream(id);
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit({
    required DoctorAvailabilitySlot slot,
    required String requested,
  }) async {
    if (_submitting) return;
    final profile = DoctorSessionScope.of(context).profile;

    String? reasonError;
    String? formError;
    final reason = _reason.text.trim();

    if (slot.hasOpenRequest) {
      formError = 'A change request for this slot is already pending.';
    } else if (slot.status == requested) {
      formError =
          'This slot is already ${DoctorStatus.availabilityLabel(requested)}. Choose the other status.';
    }
    if (reason.length < 5) {
      reasonError = 'Please give a short reason (at least 5 characters).';
    }
    if (reasonError != null || formError != null) {
      setState(() {
        _reasonError = reasonError;
        _formError = formError;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _reasonError = null;
      _formError = null;
    });

    try {
      final request = await DoctorAvailabilityService.instance
          .submitChangeRequest(
        doctorId: profile.staffId,
        doctorName: profile.name,
        hospital: profile.hospital,
        slot: slot,
        requestedStatus: requested,
        reason: reason,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DoctorRequestSubmittedScreen(request: request),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _formError = cleanError(e);
      });
    }
  }

  // ── small builders ────────────────────────────────────────────────────────

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: DoctorColors.ink)),
      );

  Widget _dropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DoctorColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon:
              const Icon(Icons.keyboard_arrow_down, color: DoctorColors.teal),
          dropdownColor: Colors.white,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DoctorColors.ink),
          items: items,
          onChanged: _submitting
              ? null
              : (v) {
                  if (v != null) onChanged(v);
                },
        ),
      ),
    );
  }

  Widget _statusToggle(String requested) {
    Widget option(String value) {
      final selected = requested == value;
      final color = DoctorStatus.availability(value);
      return Expanded(
        child: GestureDetector(
          onTap: _submitting
              ? null
              : () => setState(() {
                    _requested = value;
                    _formError = null;
                  }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              DoctorStatus.availabilityLabel(value),
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: selected ? color : DoctorColors.muted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [option('available'), option('unavailable')]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = DoctorSessionScope.of(context).profile;

    return DoctorScaffold(
      child: Column(
        children: [
          const DoctorPageHeader(title: 'Request Change'),
          Expanded(
            child: StreamBuilder<List<DoctorAvailabilitySlot>>(
              stream: _stream,
              builder: (context, snap) {
                final slots = snap.data ?? const <DoctorAvailabilitySlot>[];

                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return ErrorState(snap.error!);

                final dates = <String>[];
                for (final s in slots) {
                  if (!dates.contains(s.date)) dates.add(s.date);
                }
                if (dates.isEmpty) {
                  return const EmptyState(
                    icon: Icons.event_busy_outlined,
                    message:
                        'There are no upcoming time slots to change.\nAsk hospital staff to schedule your availability first.',
                  );
                }

                // Derive valid selections.
                final date = dates.contains(_date) ? _date! : dates.first;
                final daySlots = slots.where((s) => s.date == date).toList();
                final slot =
                    daySlots.where((s) => s.id == _slotId).firstOrNull ??
                        daySlots.first;
                final current = slot.status;
                final requested =
                    _requested ?? DoctorAvailabilityService.oppositeStatus(current);

                final summary =
                    '${profile.name} requests ${slot.startTime}-${slot.endTime} on ${DoctorFmt.dateShort(slot.date)} to be marked as ${DoctorStatus.availabilityLabel(requested)}.';

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    DoctorCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Date'),
                          _dropdown(
                            value: date,
                            items: [
                              for (final d in dates)
                                DropdownMenuItem<String>(
                                  value: d,
                                  child: Text(DoctorFmt.dateLong(d)),
                                ),
                            ],
                            onChanged: (v) => setState(() {
                              _date = v;
                              _slotId = null;
                              _requested = null;
                              _formError = null;
                            }),
                          ),
                          const SizedBox(height: 16),
                          _label('Time Slot'),
                          _dropdown(
                            value: slot.id,
                            items: [
                              for (final s in daySlots)
                                DropdownMenuItem<String>(
                                  value: s.id,
                                  child:
                                      Text('${s.startTime} – ${s.endTime}'),
                                ),
                            ],
                            onChanged: (v) => setState(() {
                              _slotId = v;
                              _requested = null;
                              _formError = null;
                            }),
                          ),
                          const SizedBox(height: 16),
                          _label('Requested Status'),
                          _statusToggle(requested),
                          const SizedBox(height: 16),
                          _label('Reason / Note'),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _reasonError == null
                                    ? DoctorColors.line
                                    : DoctorColors.red,
                              ),
                            ),
                            child: TextField(
                              controller: _reason,
                              enabled: !_submitting,
                              maxLength: 300,
                              minLines: 3,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (_) {
                                if (_reasonError != null) {
                                  setState(() => _reasonError = null);
                                }
                              },
                              style: const TextStyle(
                                  fontSize: 14.5, color: DoctorColors.ink),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                hintText: 'Enter reason for change...',
                                hintStyle: TextStyle(color: DoctorColors.hint),
                              ),
                            ),
                          ),
                          if (_reasonError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 5, left: 4),
                              child: Text(_reasonError!,
                                  style: const TextStyle(
                                      fontSize: 12, color: DoctorColors.red)),
                            ),
                          const SizedBox(height: 16),
                          _label('Current Status'),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: DoctorColors.bg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outline_rounded,
                                    size: 18, color: DoctorColors.muted),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    DoctorStatus.availabilityLabel(current),
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: DoctorStatus.availability(current),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: DoctorColors.greenBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'Current',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: DoctorColors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (slot.hasOpenRequest)
                            const Padding(
                              padding: EdgeInsets.only(top: 8, left: 4),
                              child: Text(
                                'A request for this slot is already pending.',
                                style: TextStyle(
                                    fontSize: 12, color: DoctorColors.amber),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Change summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBD7FB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Change Summary',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: DoctorColors.blue,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            summary,
                            style: const TextStyle(
                                fontSize: 13,
                                color: DoctorColors.ink,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),

                    if (_formError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DoctorColors.redBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formError!,
                          style: const TextStyle(
                              fontSize: 13, color: DoctorColors.red),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    PrimaryButton(
                      label: 'Send Request to Hospital Staff',
                      loading: _submitting,
                      onPressed: () => _submit(slot: slot, requested: requested),
                    ),
                    const SizedBox(height: 12),
                    OutlineActionButton(
                      label: 'Cancel',
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: DoctorColors.muted),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your request will be reviewed by hospital staff. The availability status will change only after approval.',
                            style: TextStyle(
                                fontSize: 12,
                                color: DoctorColors.muted,
                                height: 1.4),
                          ),
                        ),
                      ],
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
