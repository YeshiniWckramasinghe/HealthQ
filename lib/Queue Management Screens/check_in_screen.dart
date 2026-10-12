import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'appointment_service.dart';
import 'queue_status_screen.dart';

// ============================================================================
// APPOINTMENT MODEL
// ============================================================================
//
// Appointment booking / Firestore backend provides these values.
// No sample patient values are included.
// ============================================================================

class CheckInAppointment {
  const CheckInAppointment({
    required this.appointmentId,
    required this.nic,
    required this.hospital,
    required this.date,
    required this.session,
    required this.doctor,
    required this.speciality,
    required this.patient,
    required this.contact,
    this.estimatedQueueNumber = '',
    this.dateOfBirth = '',
  });

  final String appointmentId;
  final String nic;
  final String hospital;
  final String date;
  final String session;
  final String doctor;
  final String speciality;
  final String patient;
  final String contact;
  final String estimatedQueueNumber;
  final String dateOfBirth;
}

// ============================================================================
// OPTIONAL LOOKUP CALLBACK
// ============================================================================

typedef CheckInAppointmentLookup = Future<CheckInAppointment?> Function(
  String nic,
  String? appointmentId,
);

// ============================================================================
// CHECK IN SCREEN
// ============================================================================

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({
    super.key,
    this.bookedAppointment,
    this.lookupAppointment,
    this.onCheckIn,
    this.onBackToHome,
  });

  final CheckInAppointment? bookedAppointment;

  // Optional custom backend lookup.
  // When this is null, AppointmentService.findAppointment()
  // will be used automatically.
  final CheckInAppointmentLookup? lookupAppointment;

  // Receives the matched appointment after successful check-in.
  final ValueChanged<CheckInAppointment>? onCheckIn;

  // Check-in is displayed inside HomeScreen's IndexedStack.
  // This callback returns directly to Home.
  final VoidCallback? onBackToHome;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

// ============================================================================
// STATE
// ============================================================================

class _CheckInScreenState extends State<CheckInScreen> {
  static const _background = Color(0xFFF0F7F6);
  static const _primary = Color(0xFF007471);
  static const _dark = Color(0xFF063A37);
  static const _muted = Color(0xFF7C9A9C);
  static const _border = Color(0xFFD6E5E5);
  static const _error = Color(0xFFB3261E);


  static final _nicFormat = RegExp(
    r'^(?:[0-9]{12}|[0-9]{9}[VX])$',
  );

  final _formKey = GlobalKey<FormState>();

  final _nicController = TextEditingController();

  final _appointmentController =
      TextEditingController();

  CheckInAppointment? _appointment;

  bool _loading = false;

  String? _lookupError;

  // Prevent an old lookup result from filling the card
  // after input changes.
  int _requestVersion = 0;

  String get _nic =>
      _nicController.text.trim().toUpperCase();

  String get _appointmentId =>
      _appointmentController.text.trim().toUpperCase();

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    _applyBookingToFields(
      widget.bookedAppointment,
    );
  }

  // ==========================================================================
  // APPLY BOOKED APPOINTMENT
  // ==========================================================================

  void _applyBookingToFields(
    CheckInAppointment? booking,
  ) {
    if (booking == null) {
      return;
    }

    _nicController.text = booking.nic;

    _appointmentController.text =
        booking.appointmentId;

    _appointment = booking;
  }

  // ==========================================================================
  // WIDGET UPDATE
  // ==========================================================================

  @override
  void didUpdateWidget(
    covariant CheckInScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.bookedAppointment !=
            widget.bookedAppointment ||
        oldWidget.lookupAppointment !=
            widget.lookupAppointment) {
      _applyBookingToFields(
        widget.bookedAppointment,
      );

      _inputChanged();
    }
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _requestVersion++;

    _nicController.dispose();

    _appointmentController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // NIC VALIDATION
  // ==========================================================================

  String? _validateNic(String? value) {
    final nic =
        (value ?? '').trim().toUpperCase();

    if (nic.isEmpty) {
      return 'NIC is required.';
    }

    if (!_nicFormat.hasMatch(nic)) {
      return 'Invalid NIC: use 12 digits or 9 digits + V/X.';
    }

    return null;
  }

  // ==========================================================================
  // CHECK APPOINTMENT MATCH
  // ==========================================================================

  bool _matches(
    CheckInAppointment appointment,
  ) {
    final matchesNic =
        appointment.nic
                .trim()
                .toUpperCase() ==
            _nic;

    final matchesId =
        _appointmentId.isEmpty ||
        appointment.appointmentId
                .trim()
                .toUpperCase() ==
            _appointmentId;

    return matchesNic && matchesId;
  }

  // ==========================================================================
  // INPUT CHANGED
  // ==========================================================================

  void _inputChanged() {
    _requestVersion++;

    final booking =
        widget.bookedAppointment;

    setState(() {
      _loading = false;

      _lookupError = null;

      _appointment =
          _validateNic(_nic) == null &&
                  booking != null &&
                  _matches(booking)
              ? booking
              : null;
    });
  }

  // ==========================================================================
  // CHECK IN
  // ==========================================================================

  Future<void> _checkIn() async {
    if (_loading) {
      return;
    }

    if (!(_formKey.currentState?.validate() ??
        false)) {
      return;
    }

    FocusScope.of(context).unfocus();

    final lookup =
        widget.lookupAppointment;

    var matchedAppointment =
        _appointment;

    // ------------------------------------------------------------------------
    // LOOKUP APPOINTMENT
    // ------------------------------------------------------------------------

    if (matchedAppointment == null) {
      final request =
          ++_requestVersion;

      final requestedNic = _nic;

      final requestedId =
          _appointmentId;

      setState(() {
        _loading = true;

        _lookupError = null;
      });

      try {
        CheckInAppointment? result;

        // --------------------------------------------------------------------
        // If parent supplied a custom lookup, use it.
        // Otherwise use the real Firestore backend.
        // --------------------------------------------------------------------

        if (lookup != null) {
          result = await lookup(
            requestedNic,
            requestedId.isEmpty
                ? null
                : requestedId,
          );
        } else {
          result =
              await AppointmentService.findAppointment(
            nic: requestedNic,
            appointmentId:
                requestedId.isEmpty
                    ? null
                    : requestedId,
          );
        }

        if (!mounted ||
            request != _requestVersion) {
          return;
        }

        matchedAppointment =
            result != null &&
                    _matches(result)
                ? result
                : null;

        setState(() {
          _loading = false;

          _appointment =
              matchedAppointment;
        });
      } catch (e) {
        if (!mounted ||
            request != _requestVersion) {
          return;
        }

        setState(() {
          _loading = false;

          _appointment = null;

          _lookupError =
              'Unable to load appointment details. Please try again.';
        });

        return;
      }
    }

    if (!mounted) {
      return;
    }

    // ------------------------------------------------------------------------
    // NO APPOINTMENT FOUND
    // ------------------------------------------------------------------------

    if (matchedAppointment == null) {
      setState(() {
        _lookupError =
            'No matching appointment found. Check your details.';
      });

      return;
    }

    // ------------------------------------------------------------------------
    // VALIDATE APPOINTMENT ID WHEN PROVIDED
    // ------------------------------------------------------------------------

    if (!_matches(matchedAppointment)) {
      setState(() {
        _lookupError =
            'Appointment details do not match the entered NIC.';
      });

      return;
    }

    // ------------------------------------------------------------------------
    // GET QUEUE NUMBER
    // ------------------------------------------------------------------------

    final queueNumber = int.tryParse(
      matchedAppointment
          .estimatedQueueNumber
          .trim(),
    );

    if (queueNumber == null ||
        queueNumber <= 0) {
      setState(() {
        _lookupError =
            'Queue number is not available for this appointment.';
      });

      return;
    }

    // ------------------------------------------------------------------------
    // UPDATE FIRESTORE
    // ------------------------------------------------------------------------

    setState(() {
      _loading = true;

      _lookupError = null;
    });

    try {
      await AppointmentService.markAsCheckedIn(
        appointmentId:
            matchedAppointment.appointmentId,
        queueNumber: queueNumber,
      );

      // ----------------------------------------------------------------------
      // Notify parent / HomeScreen
      // ----------------------------------------------------------------------

      widget.onCheckIn?.call(
        matchedAppointment,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      // ----------------------------------------------------------------------
      // GO TO QUEUE STATUS
      // ----------------------------------------------------------------------

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QueueStatusScreen(
            appointmentId: matchedAppointment?.appointmentId,
            initialAppointment: matchedAppointment,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;

        _lookupError =
            'Check-in failed. Please try again.';
      });
    }
  }

  // ==========================================================================
  // BACK TO HOME
  // ==========================================================================

  void _goBackToHome() {
    if (widget.onBackToHome != null) {
      widget.onBackToHome!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // ==========================================================================
  // INPUT BORDER
  // ==========================================================================

  OutlineInputBorder _outline(
    Color color, {
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(12),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }

  // ==========================================================================
  // INPUT DECORATION
  // ==========================================================================

  InputDecoration _decoration({
    String? hint,
    Widget? label,
  }) {
    return InputDecoration(
      hintText: hint,
      label: label,
      hintStyle: const TextStyle(
        color: _muted,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      enabledBorder:
          _outline(_border),
      border:
          _outline(_border),
      focusedBorder:
          _outline(
        _primary,
        width: 1.5,
      ),
      errorBorder:
          _outline(_error),
      focusedErrorBorder:
          _outline(
        _error,
        width: 1.5,
      ),
      errorStyle: const TextStyle(
        color: _error,
        fontSize: 11,
        height: 1.2,
      ),
      errorMaxLines: 2,
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<
        SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.dark,
        statusBarBrightness:
            Brightness.light,
        systemNavigationBarColor:
            _background,
        systemNavigationBarIconBrightness:
            Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _background,
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: const QueueBottomBar(selectedIndex: -1),
        body: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 480,
              ),
              child:
                  SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .onDrag,
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  28,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      // ------------------------------------------------------
                      // HEADER + BACK BUTTON
                      // ------------------------------------------------------

                      Row(
                        children: [
                          Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _goBackToHome,
                              customBorder: const CircleBorder(),
                              child: const SizedBox(
                                width: 42,
                                height: 42,
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: _dark,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          const Text(
                            'Check In',
                            style: TextStyle(
                              color: _dark,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Enter your details to check in for your\nappointment today.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                        ),
                        child: Column(
                          children: [
                            // ------------------------------------------------
                            // NIC
                            // ------------------------------------------------

                            TextFormField(
                              controller:
                                  _nicController,
                              validator:
                                  _validateNic,
                              autovalidateMode:
                                  AutovalidateMode
                                      .onUserInteraction,
                              onChanged: (_) =>
                                  _inputChanged(),
                              textInputAction:
                                  TextInputAction
                                      .next,
                              textCapitalization:
                                  TextCapitalization
                                      .characters,
                              autocorrect: false,
                              enableSuggestions:
                                  false,
                              style:
                                  const TextStyle(
                                color: _dark,
                                fontSize: 14,
                              ),
                              decoration:
                                  _decoration(
                                label:
                                    const Text
                                        .rich(
                                  TextSpan(
                                    text: 'NIC',
                                    style:
                                        TextStyle(
                                      color:
                                          _muted,
                                      fontSize:
                                          14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: ' *',
                                        style:
                                            TextStyle(
                                          color:
                                              _error,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            // ------------------------------------------------
                            // APPOINTMENT ID
                            // ------------------------------------------------

                            TextFormField(
                              controller:
                                  _appointmentController,
                              onChanged: (_) =>
                                  _inputChanged(),
                              textInputAction:
                                  TextInputAction
                                      .done,
                              onFieldSubmitted:
                                  (_) =>
                                      _checkIn(),
                              textCapitalization:
                                  TextCapitalization
                                      .characters,
                              autocorrect: false,
                              enableSuggestions:
                                  false,
                              style:
                                  const TextStyle(
                                color: _dark,
                                fontSize: 14,
                              ),
                              decoration:
                                  _decoration(
                                hint:
                                    'Appointment ID',
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            // ------------------------------------------------
                            // CHECK IN BUTTON
                            // ------------------------------------------------

                            SizedBox(
                              width:
                                  double.infinity,
                              height: 48,
                              child:
                                  ElevatedButton(
                                onPressed:
                                    _loading
                                        ? null
                                        : _checkIn,
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      _primary,
                                  foregroundColor:
                                      Colors.white,
                                  disabledBackgroundColor:
                                      _primary,
                                  disabledForegroundColor:
                                      Colors.white,
                                  elevation: 0,
                                  shape:
                                      const StadiumBorder(),
                                  textStyle:
                                      const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                          color:
                                              Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Check In',
                                      ),
                              ),
                            ),

                            // ------------------------------------------------
                            // ERROR
                            // ------------------------------------------------

                            if (_lookupError !=
                                null)
                              Padding(
                                padding:
                                    const EdgeInsets
                                        .only(
                                  top: 8,
                                ),
                                child: Text(
                                  _lookupError!,
                                  style:
                                      const TextStyle(
                                    color:
                                        _error,
                                    fontSize:
                                        11,
                                  ),
                                ),
                              ),

                            const SizedBox(
                              height: 18,
                            ),

                            // ------------------------------------------------
                            // APPOINTMENT DETAILS
                            // ------------------------------------------------

                            _buildDetailsCard(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // APPOINTMENT DETAILS CARD
  // ==========================================================================

  Widget _buildDetailsCard() {
    final appointment = _appointment;

    final estQueue = appointment?.estimatedQueueNumber ?? '';
    final formattedQueue = estQueue.isNotEmpty
        ? (estQueue.startsWith('#') ? estQueue : '#$estQueue')
        : '-';

    final rows = <MapEntry<String, String>>[
      MapEntry('Hospital', appointment?.hospital.isNotEmpty == true ? appointment!.hospital : '-'),
      MapEntry('Date', appointment?.date.isNotEmpty == true ? appointment!.date : '-'),
      MapEntry('Session', appointment?.session.isNotEmpty == true ? appointment!.session : '-'),
      MapEntry('Doctor', appointment?.doctor.isNotEmpty == true ? appointment!.doctor : '-'),
      MapEntry('Speciality', appointment?.speciality.isNotEmpty == true ? appointment!.speciality : '-'),
      MapEntry('Patient', appointment?.patient.isNotEmpty == true ? appointment!.patient : '-'),
      MapEntry('NIC', _nic.isNotEmpty ? _nic : (appointment?.nic.isNotEmpty == true ? appointment!.nic : '-')),
      MapEntry('Contact', appointment?.contact.isNotEmpty == true ? appointment!.contact : '-'),
      MapEntry('Est. Queue No.', formattedQueue),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: List.generate(
          rows.length,
          (index) {
            final row = rows[index];

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == rows.length - 1 ? 0 : 9,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      row.key,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    flex: 7,
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: row.key == 'Est. Queue No.' ? _primary : _dark,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}