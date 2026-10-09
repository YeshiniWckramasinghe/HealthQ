import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/doctor_attachment_service.dart';
import '../services/doctor_service.dart';
import 'doctor_ui.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

IconData attachmentIcon(ConsultationAttachment a) {
  if (a.isImage) return Icons.image_outlined;
  if (a.isPdf) return Icons.picture_as_pdf_outlined;
  return Icons.description_outlined;
}

Color attachmentColor(ConsultationAttachment a) {
  if (a.isPdf) return DoctorColors.red;
  if (a.isImage) return DoctorColors.blue;
  return DoctorColors.teal;
}

Future<void> _openExternally(BuildContext context, String url) async {
  try {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      showDoctorSnack(context, 'No app found to open this file.', error: true);
    }
  } catch (e) {
    debugPrint('openAttachment: $e');
    if (context.mounted) {
      showDoctorSnack(context, 'Could not open the file.', error: true);
    }
  }
}

/// Images open in a full-screen zoomable viewer; PDFs / documents open in the
/// phone's own viewer app.
Future<void> openAttachment(
    BuildContext context, ConsultationAttachment a) async {
  if (a.isImage) {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AttachmentImageViewer(attachment: a),
      ),
    );
    return;
  }
  await _openExternally(context, a.url);
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen image viewer
// ─────────────────────────────────────────────────────────────────────────────

class AttachmentImageViewer extends StatelessWidget {
  final ConsultationAttachment attachment;
  const AttachmentImageViewer({super.key, required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          attachment.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () => _openExternally(context, attachment.url),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image.network(
            attachment.url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final total = progress.expectedTotalBytes;
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  value:
                      total == null ? null : progress.cumulativeBytesLoaded / total,
                ),
              );
            },
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Could not load this image.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One file row
// ─────────────────────────────────────────────────────────────────────────────

class AttachmentTile extends StatelessWidget {
  final ConsultationAttachment attachment;

  /// Replaces the default "PDF · 1.2 MB · 8 Oct 2026" line.
  final String? subtitle;

  /// Show a small image preview for pictures (downloads the image).
  final bool showThumbnail;

  /// When set, a delete button is shown.
  final VoidCallback? onDelete;
  final bool busy;

  const AttachmentTile({
    super.key,
    required this.attachment,
    this.subtitle,
    this.showThumbnail = true,
    this.onDelete,
    this.busy = false,
  });

  Widget _leading() {
    final color = attachmentColor(attachment);
    final iconBox = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(attachmentIcon(attachment), color: color, size: 22),
    );
    if (!(attachment.isImage && showThumbnail)) return iconBox;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Image.network(
          attachment.url,
          fit: BoxFit.cover,
          cacheWidth: 132,
          errorBuilder: (_, __, ___) => iconBox,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : iconBox,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final line = subtitle ??
        '${attachment.typeLabel} · ${attachment.sizeLabel} · ${DoctorFmt.dateShortOf(attachment.uploadedAt)}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: busy ? null : () => openAttachment(context, attachment),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DoctorColors.line),
          ),
          child: Row(
            children: [
              _leading(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: DoctorColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, color: DoctorColors.muted),
                    ),
                  ],
                ),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (onDelete != null)
                IconButton(
                  tooltip: 'Remove file',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: DoctorColors.red, size: 21),
                  onPressed: onDelete,
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.chevron_right, color: DoctorColors.hint),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Consultation screen: "Attachments" section
// ─────────────────────────────────────────────────────────────────────────────

class _UploadJob {
  final String name;
  double progress = 0;
  _UploadJob(this.name);
}

/// Self-contained: picks files, uploads them, lists them, deletes them.
/// Needs nothing from the host screen except the appointment + doctor id.
class ConsultationAttachmentsSection extends StatefulWidget {
  final DoctorAppointment appointment;
  final String doctorId;
  final bool readOnly;

  const ConsultationAttachmentsSection({
    super.key,
    required this.appointment,
    required this.doctorId,
    required this.readOnly,
  });

  @override
  State<ConsultationAttachmentsSection> createState() =>
      _ConsultationAttachmentsSectionState();
}

class _ConsultationAttachmentsSectionState
    extends State<ConsultationAttachmentsSection> {
  late List<ConsultationAttachment> _files;
  final List<_UploadJob> _jobs = <_UploadJob>[];
  final Set<String> _deleting = <String>{};
  StreamSubscription<DoctorAppointment?>? _sub;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _files = widget.appointment.attachments;
    // Keep the list live (and in sync with what the history screen sees).
    _sub = DoctorService.instance
        .appointmentStream(widget.appointment.id)
        .listen(
      (a) {
        if (!mounted || a == null) return;
        setState(() => _files = a.attachments);
      },
      onError: (Object e) => debugPrint('Attachments stream: $e'),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Isolated on purpose: this is the ONLY place that touches the file_picker
  /// API. This is the file_picker 12.x form. For file_picker 10.x / 11.x use:
  ///   final r = await FilePicker.platform.pickFiles(   // 11.x: FilePicker.pickFiles
  ///     type: FileType.custom,
  ///     allowedExtensions: DoctorAttachmentService.allowedExtensions,
  ///     allowMultiple: true,
  ///     withData: true,
  ///   );
  ///   return r?.files ?? const <PlatformFile>[];
  Future<List<PlatformFile>> _pickFiles() {
    return FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: DoctorAttachmentService.allowedExtensions,
    );
  }

  Future<void> _pick() async {
    if (_picking || widget.readOnly) return;
    const max = DoctorAttachmentService.maxFilesPerVisit;
    final room = max - _files.length - _jobs.length;
    if (room <= 0) {
      showDoctorSnack(
          context, 'You can attach up to $max files per consultation.',
          error: true);
      return;
    }

    setState(() => _picking = true);
    List<PlatformFile> picked;
    try {
      picked = await _pickFiles();
    } catch (e) {
      debugPrint('File picker failed: $e');
      if (mounted) {
        setState(() => _picking = false);
        showDoctorSnack(context, 'Could not open the file picker.',
            error: true);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _picking = false);
    if (picked.isEmpty) return;

    var files = picked;
    if (files.length > room) {
      files = files.take(room).toList();
      showDoctorSnack(
        context,
        'Only $room more file${room == 1 ? '' : 's'} can be added. The rest were skipped.',
        error: true,
      );
    }

    for (final f in files) {
      await _uploadOne(f);
    }
  }

  Future<void> _uploadOne(PlatformFile f) async {
    final job = _UploadJob(f.name);
    if (mounted) setState(() => _jobs.add(job));
    try {
      // Check the size BEFORE reading the file into memory. In file_picker 13
      // the length can be null (unknown); the service re-checks the real byte
      // count after reading, so null is safe to let through here.
      final int? size = f.lengthSync() ?? await f.length();
      if (size != null && size > DoctorAttachmentService.maxFileBytes) {
        throw Exception(
            '"${f.name}" is larger than ${DoctorAttachmentService.maxFileBytes ~/ (1024 * 1024)} MB.');
      }
      final bytes = await f.readAsBytes();
      final att = await DoctorAttachmentService.instance.upload(
        appointmentId: widget.appointment.id,
        patientId: widget.appointment.patientId,
        doctorId: widget.doctorId,
        fileName: f.name,
        bytes: bytes,
        onProgress: (p) {
          if (mounted) setState(() => job.progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        if (!_files.any((x) => x.id == att.id)) _files = [..._files, att];
      });
      showDoctorSnack(context, '${f.name} attached.');
    } catch (e) {
      if (mounted) showDoctorSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _jobs.remove(job));
    }
  }

  Future<void> _delete(ConsultationAttachment a) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Remove file?',
      message: '"${a.name}" will be removed from this consultation.',
      confirmLabel: 'Remove',
      danger: true,
    );
    if (!ok || !mounted) return;

    setState(() => _deleting.add(a.id));
    try {
      await DoctorAttachmentService.instance.delete(
        appointmentId: widget.appointment.id,
        attachment: a,
      );
      if (!mounted) return;
      setState(() => _files = _files.where((x) => x.id != a.id).toList());
      showDoctorSnack(context, 'File removed.');
    } catch (e) {
      if (mounted) showDoctorSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _deleting.remove(a.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = widget.readOnly;
    final empty = _files.isEmpty && _jobs.isEmpty;

    return DoctorCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_file_rounded,
                  color: DoctorColors.teal, size: 21),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: DoctorColors.ink,
                  ),
                ),
              ),
              if (_files.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: DoctorColors.tealSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_files.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: DoctorColors.teal,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'X-rays, scans, lab reports and other documents',
            style: TextStyle(fontSize: 12, color: DoctorColors.muted),
          ),
          const SizedBox(height: 12),
          if (empty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD5E0DF)),
              ),
              child: Text(
                readOnly
                    ? 'No files were attached to this consultation.'
                    : 'No files attached yet.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 13, color: DoctorColors.muted),
              ),
            )
          else ...[
            for (final f in _files)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AttachmentTile(
                  attachment: f,
                  busy: _deleting.contains(f.id),
                  onDelete: readOnly ? null : () => _delete(f),
                ),
              ),
            for (final j in _jobs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _UploadRow(job: j),
              ),
          ],
          if (!readOnly) ...[
            const SizedBox(height: 6),
            OutlineActionButton(
              label: _picking ? 'Opening…' : 'Attach Files',
              icon: Icons.upload_file_rounded,
              onPressed: _picking ? null : _pick,
            ),
            const SizedBox(height: 8),
            Text(
              'PDF, JPG, PNG, DOC · max ${DoctorAttachmentService.maxFileBytes ~/ (1024 * 1024)} MB each · up to ${DoctorAttachmentService.maxFilesPerVisit} files',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: DoctorColors.hint),
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadRow extends StatelessWidget {
  final _UploadJob job;
  const _UploadRow({required this.job});

  @override
  Widget build(BuildContext context) {
    final pct = (job.progress * 100).clamp(0, 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DoctorColors.tealSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DoctorColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: job.progress > 0 ? job.progress : null,
              minHeight: 5,
              backgroundColor: Colors.white,
              color: DoctorColors.teal,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            job.progress > 0 ? 'Uploading… $pct%' : 'Uploading…',
            style: const TextStyle(fontSize: 11.5, color: DoctorColors.muted),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient medical history: "Medical Files" card
// ─────────────────────────────────────────────────────────────────────────────

class _FileEntry {
  final DoctorAppointment appointment;
  final ConsultationAttachment file;
  const _FileEntry(this.appointment, this.file);

  String get visitLabel {
    final dx = appointment.diagnosis;
    final what = (dx != null && dx.isNotEmpty) ? dx : appointment.type;
    return '${DoctorFmt.dateShort(appointment.date)} · $what';
  }
}

/// Lists every file attached to this patient's consultations (with this
/// doctor), newest visit first. Feed it the same appointments list the
/// "Previous Visits" card uses.
class MedicalFilesCard extends StatelessWidget {
  final List<DoctorAppointment> appointments;
  const MedicalFilesCard({super.key, required this.appointments});

  List<_FileEntry> _entries() {
    final sorted = [...appointments]..sort((a, b) {
        final d = b.date.compareTo(a.date);
        return d != 0 ? d : b.time.compareTo(a.time);
      });
    return <_FileEntry>[
      for (final a in sorted)
        for (final f in a.attachments) _FileEntry(a, f),
    ];
  }

  void _openSheet(BuildContext context, List<_FileEntry> entries) {
    // Group by visit, keeping the newest-first order.
    final groups = <String, List<_FileEntry>>{};
    for (final e in entries) {
      groups.putIfAbsent(e.appointment.id, () => <_FileEntry>[]).add(e);
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical Files (${entries.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: DoctorColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final g in groups.values) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 8),
                          child: Text(
                            g.first.visitLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: DoctorColors.teal,
                            ),
                          ),
                        ),
                        for (final e in g)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AttachmentTile(
                              attachment: e.file,
                              showThumbnail: false,
                            ),
                          ),
                      ],
                    ],
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
    final entries = _entries();
    final shown = entries.take(3).toList();

    return DoctorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: entries.isEmpty ? null : () => _openSheet(context, entries),
            child: Row(
              children: [
                const Icon(Icons.folder_open_outlined,
                    color: DoctorColors.teal, size: 21),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Medical Files',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: DoctorColors.ink,
                    ),
                  ),
                ),
                if (entries.isNotEmpty) ...[
                  Text(
                    entries.length > shown.length
                        ? 'View all (${entries.length})'
                        : '${entries.length}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: DoctorColors.teal,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: DoctorColors.hint),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (shown.isEmpty)
            const Text(
              'No files attached to previous visits',
              style: TextStyle(fontSize: 13.5, color: DoctorColors.muted),
            )
          else
            for (final e in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AttachmentTile(
                  attachment: e.file,
                  subtitle: e.visitLabel,
                  showThumbnail: false,
                ),
              ),
        ],
      ),
    );
  }
}
