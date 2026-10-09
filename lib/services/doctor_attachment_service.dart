import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Consultation attachments (X-rays, scans, PDFs, lab reports ...)
//
// The file itself lives in Firebase Storage:
//   consultation_files/{patientId}/{appointmentId}/{id}_{fileName}
//
// Its metadata lives on the appointment document the doctor already owns:
//   doctor_appointments/{appointmentId}.attachments = [
//     { id, name, url, storagePath, contentType, size, uploadedAtMs,
//       uploadedBy }
//   ]
//
// Because the metadata sits on `doctor_appointments`, NO new Firestore
// collection / rule is needed, and the patient's medical history can list
// every file straight from the appointments stream it already uses.
// ---------------------------------------------------------------------------

String _str(dynamic v) => v?.toString().trim() ?? '';

int _int(dynamic v) {
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class ConsultationAttachment {
  final String id;
  final String name;
  final String url;
  final String storagePath;
  final String contentType;
  final int size; // bytes
  final int uploadedAtMs; // epoch millis (server timestamps can't live in arrays)
  final String uploadedBy; // doctor staffId

  const ConsultationAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.storagePath,
    required this.contentType,
    required this.size,
    required this.uploadedAtMs,
    this.uploadedBy = '',
  });

  DateTime get uploadedAt =>
      DateTime.fromMillisecondsSinceEpoch(uploadedAtMs);

  bool get isImage => contentType.startsWith('image/');
  bool get isPdf => contentType == 'application/pdf';
  String get sizeLabel => formatFileSize(size);

  String get typeLabel {
    if (isPdf) return 'PDF';
    if (isImage) return 'Image';
    return 'Document';
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'url': url,
        'storagePath': storagePath,
        'contentType': contentType,
        'size': size,
        'uploadedAtMs': uploadedAtMs,
        'uploadedBy': uploadedBy,
      };

  /// Returns null for malformed entries so one bad item can never crash a
  /// screen.
  static ConsultationAttachment? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final url = _str(raw['url']);
    final id = _str(raw['id']);
    if (url.isEmpty || id.isEmpty) return null;
    final name = _str(raw['name']);
    return ConsultationAttachment(
      id: id,
      name: name.isEmpty ? 'Attachment' : name,
      url: url,
      storagePath: _str(raw['storagePath']),
      contentType: _str(raw['contentType']),
      size: _int(raw['size']),
      uploadedAtMs: _int(raw['uploadedAtMs']),
      uploadedBy: _str(raw['uploadedBy']),
    );
  }

  static List<ConsultationAttachment> listFrom(dynamic raw) {
    if (raw is! List) return const <ConsultationAttachment>[];
    final out = <ConsultationAttachment>[];
    for (final e in raw) {
      final a = tryParse(e);
      if (a != null) out.add(a);
    }
    return out;
  }
}

class DoctorAttachmentService {
  static final DoctorAttachmentService instance = DoctorAttachmentService._();
  DoctorAttachmentService._();

  static const int maxFileBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxFilesPerVisit = 10;

  /// Keep in sync with the Storage rules (content-type check).
  static const List<String> allowedExtensions = <String>[
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
    'doc',
    'docx',
  ];

  static const String _root = 'consultation_files';

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> _apptRef(String id) =>
      _db.collection('doctor_appointments').doc(id);

  // ---------- helpers ----------

  static String extensionOf(String fileName) {
    final i = fileName.lastIndexOf('.');
    if (i < 0 || i == fileName.length - 1) return '';
    return fileName.substring(i + 1).toLowerCase();
  }

  /// MIME type for an allowed file name, or null when the type is not allowed.
  static String? contentTypeFor(String fileName) {
    switch (extensionOf(fileName)) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return null;
    }
  }

  static String _segment(String s) =>
      s.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');

  static String _safeName(String s) =>
      s.replaceAll(RegExp(r'[^A-Za-z0-9._\-]'), '_');

  static String _friendly(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
      case 'unauthenticated':
        return 'Upload was blocked by the Storage rules. Publish the Storage rules for consultation_files.';
      case 'canceled':
        return 'Upload cancelled.';
      case 'retry-limit-exceeded':
      case 'network-request-failed':
        return 'Network problem while uploading. Please try again.';
      case 'quota-exceeded':
        return 'Storage quota exceeded.';
      case 'bucket-not-found':
      case 'project-not-found':
        return 'Firebase Storage is not set up for this project yet.';
      default:
        final m = e.message;
        return (m == null || m.isEmpty) ? 'Upload failed (${e.code}).' : m;
    }
  }

  // ---------- upload ----------

  /// Uploads [bytes] to Storage, then records it on the appointment.
  /// Throws an [Exception] with a readable message on failure; if the
  /// Firestore write fails the uploaded file is removed again.
  Future<ConsultationAttachment> upload({
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final contentType = contentTypeFor(fileName);
    if (contentType == null) {
      throw Exception('"$fileName" is not a supported file type.');
    }
    if (bytes.isEmpty) throw Exception('"$fileName" is empty.');
    if (bytes.length > maxFileBytes) {
      throw Exception(
          '"$fileName" is larger than ${maxFileBytes ~/ (1024 * 1024)} MB.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = '${now}_${Random().nextInt(1 << 20)}';
    final path =
        '$_root/${_segment(patientId)}/${_segment(appointmentId)}/${id}_${_safeName(fileName)}';
    final ref = _storage.ref(path);

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: <String, String>{
          'originalName': fileName,
          'doctorId': doctorId,
          'appointmentId': appointmentId,
        },
      ),
    );
    final sub = task.snapshotEvents.listen(
      (s) {
        if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
      },
      onError: (Object _) {},
    );

    final String url;
    try {
      await task;
      url = await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception(_friendly(e));
    } finally {
      await sub.cancel();
    }

    final attachment = ConsultationAttachment(
      id: id,
      name: fileName,
      url: url,
      storagePath: path,
      contentType: contentType,
      size: bytes.length,
      uploadedAtMs: now,
      uploadedBy: doctorId,
    );

    try {
      await _apptRef(appointmentId).update(<String, dynamic>{
        'attachments': FieldValue.arrayUnion(<Map<String, dynamic>>[
          attachment.toMap(),
        ]),
      });
    } catch (e) {
      // Don't leave an orphan file behind.
      unawaited(ref.delete().then((_) {}, onError: (Object _) {}));
      rethrow;
    }
    return attachment;
  }

  // ---------- delete ----------

  /// Removes the entry from the appointment first (so the UI never links to a
  /// missing file), then deletes the file from Storage on a best-effort basis.
  Future<void> delete({
    required String appointmentId,
    required ConsultationAttachment attachment,
  }) async {
    final ref = _apptRef(appointmentId);
    await _db.runTransaction<void>((tx) async {
      final snap = await tx.get(ref);
      final raw = snap.data()?['attachments'];
      if (raw is! List) return;
      final kept = raw
          .where((e) => !(e is Map && _str(e['id']) == attachment.id))
          .toList();
      tx.update(ref, <String, dynamic>{'attachments': kept});
    });

    if (attachment.storagePath.isEmpty) return;
    try {
      await _storage.ref(attachment.storagePath).delete();
    } catch (e) {
      debugPrint('DoctorAttachmentService: storage delete skipped: $e');
    }
  }
}
