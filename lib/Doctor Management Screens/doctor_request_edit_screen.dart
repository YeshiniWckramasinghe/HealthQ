import 'package:flutter/material.dart';

import '../services/doctor_availability_service.dart';
import 'doctor_ui.dart';

/// Edit a request that is still pending. Pops with `true` when saved.
///
/// Mirrors the "Request Change" form, pre-filled from the request. It reads
/// the doctor id from the request itself, so it does not depend on the
/// dashboard session.
class DoctorRequestEditScreen extends StatefulWidget {
  final AvailabilityRequest request;

  const DoctorRequestEditScreen({super.key, required this.request});

  @override
  State<DoctorRequestEditScreen> createState() =>
      _DoctorRequestEditScreenState();
}

class _DoctorRequestEditScreenState extends State<DoctorRequestEditScreen> {
  late final TextEditingController _reason;
  late final Stream<List<DoctorAvailabilitySlot>> _stream;

  // Raw selections; the values actually used are derived in build() so they
  // stay valid when the slot list changes under us.
  late String? _date;
  late String? _slotId;
  String? _requested; // null = default (see build)

  String? _reasonError;
  String? _formError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.request;
    _reason = TextEditingController(text: r.reason == '-' ? '' : r.reason);
    _date = r.date;
    _slotId = r.slotId;
    _stream =
        DoctorAvailabilityService.instance.upcomingSlotsStream(r.doctorId);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save({
    required DoctorAvailabilitySlot slot,
    required String requested,
  }) async {
    if (_saving) return;
    final r = widget.request;
    final reason = _reason.text.trim();

    String? reasonError;
    String? formError;

    final moved = slot.id != r.slotId;
    if (moved && slot.hasOpenRequest) {
      formError = 'A change request for that slot is already pending.';
    } else if (slot.status == requested) {
      formError =
          'This slot is already ${DoctorStatus.availabilityLabel(requested)}. Choose the other status.';
    }
    if (reason.length < 5) {
      reasonError = 'Please give a short reason (at least 5 characters).';
    }
    if (reasonError == null &&
        formError == null &&
        !moved &&
        requested == r.requestedStatus &&
        reason == r.reason) {
      formError = 'You have not changed anything.';
    }
    if (reasonError != null || formError != null) {
      setState(() {
        _reasonError = reasonError;
        _formError = formError;
      });
      return;
    }

    setState(() {
      _saving = true;
      _reasonError = null;
      _formError = null;
    });

    try {
      await DoctorAvailabilityService.instance.updateRequest(
        request: r,
        slot: slot,
        requestedStatus: requested,
        reason: reason,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = cleanError(e);
      });
    }
  }

  // ── small builders (same look as the Request Change form) ────────────────

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
          icon: const Icon(Icons.keyboard_arrow_down, color: DoctorColors.teal),
          dropdownColor: Colors.white,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DoctorColors.ink),
          items: items,
          onChanged: _saving
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
          onTap: _saving
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
    final r = widget.request;

    return DoctorScaffold(
      child: Column(
        children: [
          const DoctorPageHeader(title: 'Edit Request'),
          Expanded(
            child: StreamBuilder<List<DoctorAvailabilitySlot>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return ErrorState(snap.error!);

                final slots = snap.data ?? const <DoctorAvailabilitySlot>[];
                final dates = <String>[];
                for (final s in slots) {
                  if (!dates.contains(s.date)) dates.add(s.date);
                }
                if (dates.isEmpty) {
                  return const EmptyState(
                    icon: Icons.event_busy_outlined,
                    message: 'There are no upcoming time slots to move this request to.',
                  );
                }

                // Derive valid selections.
                final originalListed = slots.any((s) => s.id == r.slotId);
                final date = dates.contains(_date) ? _date! : dates.first;
                final daySlots = slots.where((s) => s.date == date).toList();
                final slot =
                    daySlots.where((s) => s.id == _slotId).firstOrNull ??
                        daySlots.first;
                final moved = slot.id != r.slotId;

                final requested = _requested ??
                    (moved
                        ? DoctorAvailabilityService.oppositeStatus(slot.status)
                        : r.requestedStatus);

                final summary =
                    '${r.doctorName} requests ${slot.startTime}-${slot.endTime} on ${DoctorFmt.dateShort(slot.date)} to be marked as ${DoctorStatus.availabilityLabel(requested)}.';

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: DoctorColors.amberBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note_rounded,
                              size: 20, color: DoctorColors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Editing request ${r.id}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: DoctorColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!originalListed)
                      const Padding(
                        padding: EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          'The original time slot is no longer listed. Choose a new slot to continue.',
                          style: TextStyle(
                              fontSize: 12, color: DoctorColors.amber),
                        ),
                      ),
                    const SizedBox(height: 14),
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
                                  child: Text('${s.startTime} – ${s.endTime}'),
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
                              enabled: !_saving,
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
                                    DoctorStatus.availabilityLabel(slot.status),
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: DoctorStatus.availability(
                                          slot.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (moved && slot.hasOpenRequest)
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
                      label: 'Save Changes',
                      icon: Icons.check_rounded,
                      loading: _saving,
                      onPressed: () => _save(slot: slot, requested: requested),
                    ),
                    const SizedBox(height: 12),
                    OutlineActionButton(
                      label: 'Cancel',
                      onPressed:
                          _saving ? null : () => Navigator.of(context).maybePop(),
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
                            'You can edit a request only while it is pending. The availability status still changes only after hospital staff approve it.',
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
