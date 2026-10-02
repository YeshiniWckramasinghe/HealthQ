import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'terms_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String contactNo;
  const VerificationScreen({super.key, required this.contactNo});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // Firebase OTP is 6 digits
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String? _verificationId;
  int? _resendToken;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _statusMessage;
  bool _isError = false;

  Timer? _timer;
  int _cooldown = 60;
  bool _canResend = false;

  late String _formattedPhone;

  @override
  void initState() {
    super.initState();
    _formattedPhone = _normalizePhoneNumber(widget.contactNo);
    _sendOtp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// Converts local Sri Lankan numbers (e.g. 0712345678) to E.164 international format (+94712345678)
  String _normalizePhoneNumber(String raw) {
    String cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    if (cleaned.startsWith('0')) {
      return '+94${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('94')) {
      return '+$cleaned';
    }
    return '+94$cleaned';
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() {
      _cooldown = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldown > 1) {
        setState(() => _cooldown--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isSending = true;
      _statusMessage = 'Sending OTP to $_formattedPhone...';
      _isError = false;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _formattedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Verification automatically completed by Android SMS Retriever');
          if (credential.smsCode != null && credential.smsCode!.length == 6) {
            for (int i = 0; i < 6; i++) {
              _controllers[i].text = credential.smsCode![i];
            }
          }
          await _handleAuthSuccess(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('VERIFY PHONE FAILED: ${e.code} — ${e.message}');
          String errorText = 'Failed to send OTP to $_formattedPhone.';
          if (e.code == 'invalid-phone-number') {
            errorText = 'The phone number $_formattedPhone is invalid.';
          } else if (e.code == 'quota-exceeded') {
            errorText = 'SMS quota exceeded for this Firebase project.';
          } else if (e.code == 'app-not-authorized' ||
              e.code == 'missing-client-identifier') {
            errorText =
                'Firebase Phone Auth not configured. Please enable Phone provider in Firebase Console.';
          } else if (e.message != null) {
            errorText = e.message!;
          }

          if (mounted) {
            setState(() {
              _isSending = false;
              _isError = true;
              _statusMessage = errorText;
              _canResend = true;
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('OTP code sent successfully: verificationId=$verificationId');
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
              _isSending = false;
              _isError = false;
              _statusMessage = 'OTP code sent! Please check your SMS inbox.';
            });
            _startCooldown();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.primary400,
                content: Text('6-digit OTP code sent to $_formattedPhone'),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          debugPrint('Auto retrieval timeout for $verificationId');
        },
      );
    } catch (e) {
      debugPrint('Unexpected error sending OTP: $e');
      if (mounted) {
        setState(() {
          _isSending = false;
          _isError = true;
          _statusMessage = 'Could not initiate SMS: $e';
          _canResend = true;
        });
      }
    }
  }

  Future<void> _verify() async {
    final code = _controllers.map((c) => c.text.trim()).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit OTP code.')),
      );
      return;
    }

    if (_verificationId == null) {
      // If verificationId is null (e.g. in test or development fallback)
      _proceedToTerms();
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await _handleAuthSuccess(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('OTP VERIFICATION ERROR: ${e.code} — ${e.message}');
      String msg = 'Incorrect OTP code. Please try again.';
      if (e.code == 'invalid-verification-code') {
        msg = 'Invalid OTP code entered. Please check your SMS.';
      } else if (e.code == 'session-expired') {
        msg = 'OTP has expired. Please tap Resend OTP.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red.shade700, content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleAuthSuccess(PhoneAuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        debugPrint('Phone link exception (continuing): ${e.code}');
      }

      // Record verified phone number in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'contactNo': _formattedPhone,
        'phoneVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (mounted) {
      _proceedToTerms();
    }
  }

  void _proceedToTerms() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TermsScreen()),
    );
  }

  String _maskedContact() {
    final digits = _formattedPhone;
    if (digits.length < 4) return digits;
    return '${digits.substring(0, 3)} •••• ${digits.substring(digits.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary500),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phone Verification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We've sent a 6-digit One Time Password (OTP) to your registered mobile number ending in ${_maskedContact()}.",
                style: const TextStyle(
                  color: AppColors.gray500,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Status Banner
              if (_statusMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _isError ? Colors.red.shade50 : AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isError
                          ? Colors.red.shade200
                          : AppColors.primary300.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_isSending)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _isError ? Icons.error_outline : Icons.info_outline,
                          size: 18,
                          color: _isError
                              ? Colors.red.shade700
                              : AppColors.primary400,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 11,
                            color: _isError
                                ? Colors.red.shade900
                                : AppColors.primary500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 6 Digit OTP Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 46,
                    height: 54,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary500,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primary300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primary400,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && i < 5) {
                          FocusScope.of(context)
                              .requestFocus(_focusNodes[i + 1]);
                        } else if (value.isEmpty && i > 0) {
                          FocusScope.of(context)
                              .requestFocus(_focusNodes[i - 1]);
                        }
                        // If all 6 digits entered, auto-verify
                        final fullCode =
                            _controllers.map((c) => c.text).join();
                        if (fullCode.length == 6) {
                          _verify();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),

              // Resend OTP Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: (_canResend && !_isSending) ? _sendOtp : null,
                    child: Text(
                      _canResend
                          ? "Didn't receive code? Resend OTP"
                          : "Resend OTP in ${_cooldown}s",
                      style: TextStyle(
                        color: _canResend
                            ? AppColors.primary300
                            : AppColors.gray400,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isVerifying || _isSending) ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary400,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify & Proceed',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Development / Testing Bypass helper (in case Firebase project has no active SMS billing)
              Center(
                child: TextButton.icon(
                  onPressed: _proceedToTerms,
                  icon: const Icon(Icons.skip_next, size: 16, color: AppColors.gray400),
                  label: const Text(
                    'Skip verification (Development Mode)',
                    style: TextStyle(fontSize: 11, color: AppColors.gray400),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}