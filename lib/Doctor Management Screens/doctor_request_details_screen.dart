import 'package:flutter/material.dart';

import '../services/doctor_availability_service.dart';
import 'doctor_request_edit_screen.dart';
import 'doctor_ui.dart';

class DoctorRequestDetailsScreen extends StatefulWidget {
  final String requestId;

  /// Optional already-loaded copy so the screen paints instantly.
  final AvailabilityRequest? initial;

  const DoctorRequestDetailsScreen({
    super.key,
    required this.requestId,
    this.initial,
  });

  @override
  State<DoctorRequestDetailsScreen> createState() =>
      _DoctorRequestDetailsScreenState();
}

class _DoctorRequestDetailsScreenState
    extends State<DoctorRequestDetailsScreen> {
  late final Stream<AvailabilityRequest?> _stream;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _stream =
        DoctorAvailabilityService.instance.requestStream(widget.requestId);
  }

  Future<void> _cancel(AvailabilityRequest r) async {
    if (_cancelling) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Cancel request?',
      message:
          'Your request to change ${r.slotLabel} on ${DoctorFmt.dateShort(r.date)} will be withdrawn.',
      confirmLabel: 'Cancel Request',
      cancelLabel: 'Keep',
      danger: true,
    );
    if (!ok || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await DoctorAvailabilityService.instance.cancelRequest(r);
      if (!mounted) return;
      showDoctorSnack(context, 'Request ${r.id} cancelled.');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) {
        setState(() => _cancelling = false);
        showDoctorSnack(context, cleanError(e), error: true);
      }
    }
  }

  Future<void> _edit(AvailabilityRequest r) async {
    if (_cancelling) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => DoctorRequestEditScreen(request: r),
      ),
    );
    if (saved == true && mounted) {
      showDoctorSnack(context, 'Request ${r.id} updated.');
    }
  }

  Widget _row(String label, Widget value, {bool last = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 118,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13.5, color: DoctorColors.muted)),
              ),
              Expanded(
                child: Align(alignment: Alignment.centerRight, child: value),
              ),
            ],
          ),
        ),
        if (!last) const Divider(height: 1, color: DoctorColors.line),
      ],
    );
  }

  Widget _bold(String t, {Color color = DoctorColors.ink}) => Text(
        t,
        textAlign: TextAlign.right,
        style:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
      );

  @override
  Widget build(BuildContext context) {
    return DoctorScaffold(
      child: Column(
        children: [
          const DoctorPageHeader(title: 'Request Details'),
          Expanded(
            child: StreamBuilder<AvailabilityRequest?>(
              stream: _stream,
              initialData: widget.initial,
              builder: (context, snap) {
                final r = snap.data;

                if (r == null) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) return ErrorState(snap.error!);
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    message: 'This request could not be found.',
                  );
                }

                final style = DoctorStatus.request(r.status);
                final banner = r.status == 'pending'
                    ? 'Pending Review'
                    : style.label;
                final bannerIcon = r.status == 'approved'
                    ? Icons.check_circle_outline_rounded
                    : r.status == 'rejected'
                        ? Icons.cancel_outlined
                        : r.status == 'cancelled'
                            ? Icons.block_rounded
                            : Icons.access_time_rounded;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: style.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              banner,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: style.fg,
                              ),
                            ),
                          ),
                          Icon(bannerIcon, color: style.fg, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    DoctorCard(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      child: Column(
                        children: [
                          _row('Request ID', _bold(r.id)),
                          _row('Doctor', _bold(r.doctorName)),
                          _row('Target Date', _bold(DoctorFmt.dateLong(r.date))),
                          _row('Time Slot', _bold(r.slotLabel)),
                          _row(
                            'Current Status',
                            _bold(DoctorStatus.availabilityLabel(r.currentStatus),
                                color:
                                    DoctorStatus.availability(r.currentStatus)),
                          ),
                          _row(
                            'Requested Status',
                            _bold(
                                DoctorStatus.availabilityLabel(r.requestedStatus),
                                color: DoctorStatus.availability(
                                    r.requestedStatus)),
                          ),
                          // Reason: label above, full text below (can be long).
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Reason for Change',
                                      style: TextStyle(
                                          fontSize: 13.5,
                                          color: DoctorColors.muted)),
                                  const SizedBox(height: 5),
                                  Text(r.reason,
                                      style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: DoctorColors.ink,
                                          height: 1.35)),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: DoctorColors.line),
                          if (r.reviewerNote != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Reviewer Note',
                                        style: TextStyle(
                                            fontSize: 13.5,
                                            color: DoctorColors.muted)),
                                    const SizedBox(height: 5),
                                    Text(r.reviewerNote!,
                                        style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w600,
                                            color: DoctorColors.ink,
                                            height: 1.35)),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1, color: DoctorColors.line),
                          ],
                          _row(
                            'Submitted Time',
                            _bold(DoctorFmt.dateTime(r.submittedAt)),
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const SectionTitle('Request Progress'),
                    const SizedBox(height: 14),
                    _Timeline(request: r),
                    if (r.isPending) ...[
                      const SizedBox(height: 22),
                      PrimaryButton(
                        label: 'Edit Request',
                        icon: Icons.edit_outlined,
                        onPressed: _cancelling ? null : () => _edit(r),
                      ),
                      const SizedBox(height: 12),
                      OutlineActionButton(
                        label: _cancelling ? 'Cancelling…' : 'Cancel Request',
                        icon: Icons.delete_outline_rounded,
                        color: DoctorColors.red,
                        onPressed: _cancelling ? null : () => _cancel(r),
                      ),
                    ],
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

class _Step {
  final String title;
  final String subtitle;
  final Color color;
  const _Step(this.title, this.subtitle, this.color);
}

class _Timeline extends StatelessWidget {
  final AvailabilityRequest request;
  const _Timeline({required this.request});

  List<_Step> _steps() {
    final steps = <_Step>[
      _Step('Submitted successfully', DoctorFmt.dateTime(request.submittedAt),
          DoctorColors.teal),
      if (request.editedAt != null)
        _Step('Request edited', DoctorFmt.dateTime(request.editedAt!),
            DoctorColors.blue),
    ];
    final when = request.reviewedAt != null
        ? DoctorFmt.dateTime(request.reviewedAt!)
        : '';
    final by = request.reviewedBy == null ? '' : ' by ${request.reviewedBy}';

    switch (request.status) {
      case 'approved':
        steps.add(_Step('Approved by hospital staff',
            when.isEmpty ? 'Completed' : '$when$by', DoctorColors.green));
        break;
      case 'rejected':
        steps.add(_Step('Rejected by hospital staff',
            when.isEmpty ? 'Completed' : '$when$by', DoctorColors.red));
        break;
      case 'cancelled':
        steps.add(const _Step(
            'Cancelled by you', 'Request withdrawn', DoctorColors.muted));
        break;
      default:
        steps.add(const _Step('Pending medical superintendent review',
            'In Progress', DoctorColors.amber));
    }
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps();
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: steps[i].color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 38,
                        color: DoctorColors.teal.withValues(alpha: 0.5),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[i].title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: DoctorColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      steps[i].subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: DoctorColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
