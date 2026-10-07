import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/doctor_service.dart';

void showMedicalAttachmentViewerDialog(
  BuildContext context,
  MedicalAttachmentModel attachment,
) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: attachment.badgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      attachment.icon,
                      color: attachment.badgeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: attachment.badgeBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                attachment.type,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: attachment.badgeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${attachment.date} · ${attachment.fileSize}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Visual Preview Box
              Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  color: attachment.type.toLowerCase() == 'x-ray'
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: attachment.type.toLowerCase() == 'x-ray'
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (attachment.type.toLowerCase() == 'x-ray') ...[
                      // Simulated Radiography Grid
                      Positioned(
                        top: 10,
                        left: 12,
                        child: Text(
                          'DICOM #2025-RAD\nAP CHEST VIEW\nEXPOSURE: 110kVp',
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: 'monospace',
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Text(
                          'R',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: 64,
                            color: Colors.teal.shade200.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Digital Radiography Preview',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Simulated Lab / Scan Report Sheet
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_hospital,
                                      size: 16,
                                      color: AppColors.primary400,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Clinical Diagnostics Lab',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary500,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16, color: Color(0xFFE2E8F0)),
                            const SizedBox(height: 4),
                            Text(
                              'Test: ${attachment.name.replaceAll('.pdf', '').replaceAll('_', ' ')}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sample Collected: ${attachment.date}\nMethodology: Automated Spectrophotometry / Digital Immunoassay\nStatus: Final Approved Report',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.gray400,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Clinical Findings / Remarks
              if (attachment.findings.isNotEmpty) ...[
                const Text(
                  'Clinical Remarks & Findings',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    attachment.findings,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading ${attachment.name}... (Simulated)'),
                            backgroundColor: AppColors.primary400,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Export File'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary400),
                        foregroundColor: AppColors.primary400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary400,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
