import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailResult {
  final bool success;
  final String? errorMessage;

  const EmailResult({required this.success, this.errorMessage});
}

class EmailService {
  // =========================================================================
  // GMAIL SMTP CONFIGURATION
  // =========================================================================
  // Sender account used to dispatch verification codes
  static String smtpEmail = 'l.priyankara000@gmail.com';
  static String smtpAppPassword = 'eutz keoq hpiv fldj';
  static String senderDisplayName = 'HealthQ';

  /// Sends a branded 6-digit OTP verification email directly to the patient's Gmail.
  static Future<EmailResult> sendVerificationOtpEmail({
    required String recipientEmail,
    required String code,
    String? recipientName,
  }) async {
    String activeEmail = smtpEmail.trim();
    String activePassword = smtpAppPassword.replaceAll(' ', '').trim();

    // Check if dynamic configuration exists in Firestore (app_config/smtp)
    try {
      final configDoc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('smtp')
          .get()
          .timeout(const Duration(seconds: 2));
      if (configDoc.exists) {
        final data = configDoc.data();
        if (data != null) {
          if (data['email'] != null && data['email'].toString().isNotEmpty) {
            activeEmail = data['email'].toString().trim();
          }
          if (data['appPassword'] != null &&
              data['appPassword'].toString().isNotEmpty) {
            activePassword = data['appPassword']
                .toString()
                .replaceAll(' ', '')
                .trim();
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore SMTP config check: $e');
    }

    // Queue into Firestore 'mail' collection asynchronously (for Firebase Trigger Email extension)
    try {
      unawaited(
        FirebaseFirestore.instance.collection('mail').add({
          'to': [recipientEmail],
          'message': {
            'subject': 'HealthQ Verification Code: $code',
            'text':
                'Your HealthQ verification code is: $code. This code is valid for 15 minutes.',
            'html': _buildHtmlBody(code: code, recipientName: recipientName),
          },
          'createdAt': FieldValue.serverTimestamp(),
        }).then<void>((_) => null, onError: (e) {
          debugPrint('Firestore mail add note: $e');
        }),
      );
    } catch (_) {}

    // Validate that credentials have been configured
    final isConfigured = activeEmail.isNotEmpty &&
        activePassword.isNotEmpty &&
        !activePassword.contains('your_app_password') &&
        activePassword.length >= 16;

    if (!isConfigured) {
      debugPrint('⚠️ SMTP credentials not set in lib/services/email_service.dart');
      return const EmailResult(
        success: false,
        errorMessage:
            'Sender Gmail not configured. Please set your Gmail and 16-character Google App Password in lib/services/email_service.dart.',
      );
    }

    // Attempt 1: Port 465 direct SSL (fastest & reliable on mobile networks, avoids greeting timeout)
    try {
      debugPrint('📧 EmailService: Dispatching email OTP...');
      debugPrint('   ↳ From (Sender): $activeEmail ($senderDisplayName)');
      debugPrint('   ↳ To (Patient): $recipientEmail');
      debugPrint('   ↳ Verification Code: $code');

      final server465 = SmtpServer(
        'smtp.gmail.com',
        port: 465,
        ssl: true,
        username: activeEmail,
        password: activePassword,
      );

      final message = Message()
        ..from = Address(activeEmail, senderDisplayName)
        ..recipients.add(recipientEmail)
        ..subject = 'HealthQ Verification Code: $code'
        ..text = _buildPlainText(code: code, recipientName: recipientName)
        ..html = _buildHtmlBody(code: code, recipientName: recipientName);

      final sendReport = await send(message, server465);
      debugPrint('✅ SMTP OTP email successfully delivered to $recipientEmail! Report: $sendReport');
      return const EmailResult(success: true);
    } on MailerException catch (e465) {
      debugPrint('Port 465 MailerException: ${e465.message}, trying port 587 fallback...');
      
      // Check for auth error
      if (e465.message.contains('535') || e465.message.contains('Username and Password not accepted')) {
        return const EmailResult(
          success: false,
          errorMessage:
              'Gmail SMTP authentication failed. Please verify your 16-character Google App Password.',
        );
      }

      // Attempt 2: Port 587 STARTTLS Fallback
      try {
        final server587 = gmail(activeEmail, activePassword);
        final message = Message()
          ..from = Address(activeEmail, senderDisplayName)
          ..recipients.add(recipientEmail)
          ..subject = 'HealthQ Verification Code: $code'
          ..text = _buildPlainText(code: code, recipientName: recipientName)
          ..html = _buildHtmlBody(code: code, recipientName: recipientName);

        final sendReport = await send(message, server587);
        debugPrint('SMTP OTP email sent via port 587 fallback: $sendReport');
        return const EmailResult(success: true);
      } on MailerException catch (e587) {
        debugPrint('Port 587 MailerException: ${e587.message}');
        return EmailResult(
          success: false,
          errorMessage: 'Could not send email to $recipientEmail. Please check network connection.',
        );
      }
    } catch (e) {
      debugPrint('Unexpected error sending SMTP OTP: $e');
      return EmailResult(
        success: false,
        errorMessage: 'Could not send verification email: $e',
      );
    }
  }

  static String _buildPlainText({required String code, String? recipientName}) {
    final nameGreeting = (recipientName != null && recipientName.isNotEmpty)
        ? 'Hello $recipientName,\n\n'
        : 'Hello,\n\n';

    return '${nameGreeting}Your HealthQ verification code is: $code\n\n'
        'This code will expire in 15 minutes.\n'
        'Please enter this code into the HealthQ application to verify your account.\n\n'
        'If you did not request this verification code, please ignore this email.\n\n'
        'Regards,\n'
        'HealthQ Hospital Care Team';
  }

  static String _buildHtmlBody({required String code, String? recipientName}) {
    final nameGreeting = (recipientName != null && recipientName.isNotEmpty)
        ? 'Hello <strong>$recipientName</strong>,'
        : 'Hello,';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>HealthQ Verification Code</title>
</head>
<body style="margin: 0; padding: 24px; font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F4F7F6; color: #333333;">
  <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 520px; margin: 0 auto; background-color: #FFFFFF; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 14px rgba(0,0,0,0.06); border: 1px solid #E5E7EB;">
    <!-- Header -->
    <tr>
      <td style="background: linear-gradient(135deg, #164E63 0%, #0891B2 100%); padding: 32px 24px; text-align: center;">
        <h1 style="margin: 0; color: #FFFFFF; font-size: 24px; font-weight: 700; letter-spacing: 0.5px;">HealthQ Hospital</h1>
        <p style="margin: 6px 0 0 0; color: #E0F2FE; font-size: 13px;">Smart Patient Care & Management System</p>
      </td>
    </tr>

    <!-- Body Content -->
    <tr>
      <td style="padding: 32px 28px; text-align: center;">
        <h2 style="margin: 0 0 12px 0; color: #164E63; font-size: 20px; font-weight: 700;">Account Verification</h2>
        <p style="margin: 0 0 20px 0; color: #4B5563; font-size: 14px; line-height: 1.5;">
          $nameGreeting<br>
          Please use the following 6-digit verification code to complete your registration in the HealthQ mobile app.
        </p>

        <!-- OTP Code Badge -->
        <table role="presentation" border="0" cellspacing="0" cellpadding="0" style="margin: 0 auto 24px auto;">
          <tr>
            <td style="background-color: #ECFEFF; border: 2px dashed #06B6D4; border-radius: 12px; padding: 18px 36px;">
              <span style="font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #0E7490; font-family: monospace; display: block;">
                $code
              </span>
            </td>
          </tr>
        </table>

        <!-- Validity Notice -->
        <div style="background-color: #FEF3C7; border-radius: 8px; padding: 10px 16px; display: inline-block; margin-bottom: 24px;">
          <span style="color: #92400E; font-size: 12px; font-weight: 600;">
            ⏱️ Valid for 15 minutes only
          </span>
        </div>

        <p style="margin: 0 0 16px 0; color: #6B7280; font-size: 12px; line-height: 1.5;">
          Enter this code directly on the verification screen in your HealthQ app.
        </p>

        <!-- Divider -->
        <hr style="border: none; border-top: 1px solid #E5E7EB; margin: 24px 0 20px 0;">

        <!-- Security Warning -->
        <p style="margin: 0; color: #9CA3AF; font-size: 11px; line-height: 1.4;">
          Security Alert: HealthQ staff will never ask for your verification code. Do not share this code with anyone. If you did not request this registration, please disregard this email.
        </p>
      </td>
    </tr>

    <!-- Footer -->
    <tr>
      <td style="background-color: #F9FAFB; padding: 16px; text-align: center; border-top: 1px solid #E5E7EB;">
        <p style="margin: 0; color: #9CA3AF; font-size: 11px;">
          &copy; 2026 HealthQ Hospital Management. All rights reserved.
        </p>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }
}
