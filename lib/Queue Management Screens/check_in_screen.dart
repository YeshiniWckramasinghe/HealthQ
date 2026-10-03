import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'queue_status_screen.dart';

// ===================================================================
// APPOINTMENT MODEL
// ===================================================================

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

// ===================================================================
// APPOINTMENT LOOKUP
// ===================================================================

typedef CheckInAppointmentLookup =
    Future<CheckInAppointment?> Function(
  String nic,
  String? appointmentId,
);

// ===================================================================
// CHECK-IN SCREEN
// ===================================================================

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({
    super.key,
    this.bookedAppointment,
    this.lookupAppointment,
    this.onCheckIn,
    this.onNavigationSelected,
  });

  final CheckInAppointment? bookedAppointment;

  final CheckInAppointmentLookup? lookupAppointment;

  final ValueChanged<CheckInAppointment>? onCheckIn;

  final ValueChanged<int>? onNavigationSelected;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final TextEditingController _nicController =
      TextEditingController();

  final TextEditingController _appointmentController =
      TextEditingController();

  CheckInAppointment? _appointment;

  bool _loading = false;

  String? _errorMessage;

  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _applyBookingToFields();
  }

  @override
  void didUpdateWidget(
    covariant CheckInScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.bookedAppointment !=
        widget.bookedAppointment) {
      _applyBookingToFields();

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _nicController.dispose();
    _appointmentController.dispose();
    super.dispose();
  }

  // =================================================================
  // APPLY BOOKING
  // =================================================================

  void _applyBookingToFields() {
    final booking = widget.bookedAppointment;

    if (booking == null) {
      _appointment = null;
      return;
    }

    _nicController.text = booking.nic;
    _appointmentController.text = booking.appointmentId;

    _appointment = booking;
    _errorMessage = null;
  }

  // =================================================================
  // INPUT CHANGED
  // =================================================================

  void _inputChanged() {
    final booking = widget.bookedAppointment;

    if (booking != null &&
        _nicController.text.trim().toUpperCase() ==
            booking.nic.toUpperCase()) {
      setState(() {
        _appointment = booking;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _appointment = null;
      _errorMessage = null;
    });
  }

  // =================================================================
  // NIC VALIDATION
  // =================================================================

  bool _isValidNic(String value) {
    final nic = value.trim().toUpperCase();

    final newNic = RegExp(r'^\d{12}$');
    final oldNic = RegExp(r'^\d{9}[VX]$');

    return newNic.hasMatch(nic) ||
        oldNic.hasMatch(nic);
  }

  // =================================================================
  // CHECK IN
  // =================================================================

  Future<void> _checkIn() async {
    FocusScope.of(context).unfocus();

    final nic =
        _nicController.text.trim().toUpperCase();

    final appointmentId =
        _appointmentController.text.trim();

    if (!_isValidNic(nic)) {
      setState(() {
        _errorMessage =
            'Please enter a valid NIC number.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final int requestId = ++_requestVersion;

    try {
      CheckInAppointment? matchedAppointment;

      // -------------------------------------------------------------
      // CHECK BOOKED APPOINTMENT FIRST
      // -------------------------------------------------------------

      final booked = widget.bookedAppointment;

      if (booked != null &&
          booked.nic.toUpperCase() == nic) {
        matchedAppointment = booked;
      }

      // -------------------------------------------------------------
      // OPTIONAL LOOKUP
      // -------------------------------------------------------------

      if (matchedAppointment == null &&
          widget.lookupAppointment != null) {
        matchedAppointment =
            await widget.lookupAppointment!(
          nic,
          appointmentId.isEmpty
              ? null
              : appointmentId,
        );
      }

      if (!mounted ||
          requestId != _requestVersion) {
        return;
      }

      // -------------------------------------------------------------
      // NO APPOINTMENT
      // -------------------------------------------------------------

      if (matchedAppointment == null) {
        setState(() {
          _loading = false;
          _errorMessage =
              'No appointment found for the entered details.';
        });
        return;
      }

      // -------------------------------------------------------------
      // APPOINTMENT FOUND
      // -------------------------------------------------------------

      setState(() {
        _appointment = matchedAppointment;
        _loading = false;
        _errorMessage = null;
      });

      widget.onCheckIn?.call(
        matchedAppointment,
      );

      if (!mounted) return;

      // -------------------------------------------------------------
      // QUEUE STATUS
      // -------------------------------------------------------------

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QueueStatusScreen(
            appointment: matchedAppointment!,
          ),
        ),
      );
    } catch (e) {
      if (!mounted ||
          requestId != _requestVersion) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage =
            'Something went wrong. Please try again.';
      });

      debugPrint(
        'Check-in error: $e',
      );
    }
  }

  // =================================================================
  // BUILD
  // =================================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final double screenWidth =
            constraints.maxWidth;

        // Responsive horizontal padding
        final double horizontalPadding =
            screenWidth < 600
                ? 18
                : screenWidth < 1000
                    ? 30
                    : 60;

        // Content max width for laptop/tablet
        final double contentMaxWidth =
            screenWidth < 700
                ? double.infinity
                : 850;

        return Container(
          color: AppColors.primary100,
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: contentMaxWidth,
                ),
                child: Column(
                  children: [
                    _buildHeader(
                      screenWidth,
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          30,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            _buildHospitalBanner(
                              screenWidth,
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            _buildCheckInForm(
                              screenWidth,
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            if (_appointment != null)
                              _buildDetailsCard(
                                screenWidth,
                              ),

                            const SizedBox(
                              height: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =================================================================
  // HEADER
  // =================================================================

  Widget _buildHeader(
    double screenWidth,
  ) {
    final double titleSize =
        screenWidth < 600 ? 25 : 29;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        screenWidth < 600 ? 18 : 30,
        14,
        screenWidth < 600 ? 18 : 30,
        12,
      ),
      child: Text(
        'Check In',
        style: TextStyle(
          color: AppColors.primary900,
          fontSize: titleSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // =================================================================
  // HOSPITAL BANNER
  // =================================================================

  Widget _buildHospitalBanner(
    double screenWidth,
  ) {
    final double bannerHeight =
        screenWidth < 600
            ? 150
            : screenWidth < 1000
                ? 190
                : 220;

    final double titleSize =
        screenWidth < 600 ? 19 : 23;

    return Container(
      width: double.infinity,
      height: bannerHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/check_in_hospital.jpg',
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                color: AppColors.primary300,
                child: const Center(
                  child: Icon(
                    Icons.local_hospital_outlined,
                    size: 65,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.65),
                ],
              ),
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Text(
              'Check in for your appointment',
              style: TextStyle(
                color: Colors.white,
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // CHECK-IN FORM
  // =================================================================

  Widget _buildCheckInForm(
    double screenWidth,
  ) {
    final double titleSize =
        screenWidth < 600 ? 18 : 21;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        screenWidth < 600 ? 18 : 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your details',
            style: TextStyle(
              color: AppColors.primary900,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _nicController,
            textCapitalization:
                TextCapitalization.characters,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9a-zA-Z]'),
              ),
              LengthLimitingTextInputFormatter(
                12,
              ),
            ],
            onChanged: (_) {
              _inputChanged();
            },
            decoration: InputDecoration(
              labelText: 'NIC Number',
              hintText: 'Enter your NIC',
              prefixIcon: const Icon(
                Icons.badge_outlined,
              ),
              filled: true,
              fillColor:
                  AppColors.primary100,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller:
                _appointmentController,
            keyboardType: TextInputType.text,
            onChanged: (_) {
              _inputChanged();
            },
            decoration: InputDecoration(
              labelText: 'Appointment ID',
              hintText:
                  'Enter appointment ID if available',
              prefixIcon: const Icon(
                Icons.confirmation_number_outlined,
              ),
              filled: true,
              fillColor:
                  AppColors.primary100,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 14),

          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              margin:
                  const EdgeInsets.only(
                bottom: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.red
                    .withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style:
                          const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _loading ? null : _checkIn,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary300,
                foregroundColor:
                    Colors.white,
                disabledBackgroundColor:
                    AppColors.gray300,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Check In',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // APPOINTMENT DETAILS
  // =================================================================

  Widget _buildDetailsCard(
    double screenWidth,
  ) {
    final appointment =
        _appointment!;

    final double titleSize =
        screenWidth < 600 ? 19 : 21;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        screenWidth < 600 ? 18 : 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Details',
            style: TextStyle(
              color: AppColors.primary900,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 18),

          _detailRow(
            Icons.local_hospital_outlined,
            'Hospital',
            appointment.hospital,
          ),

          _detailRow(
            Icons.calendar_today_outlined,
            'Date',
            appointment.date,
          ),

          _detailRow(
            Icons.access_time_outlined,
            'Session',
            appointment.session,
          ),

          _detailRow(
            Icons.person_outline,
            'Doctor',
            appointment.doctor,
          ),

          _detailRow(
            Icons.medical_services_outlined,
            'Speciality',
            appointment.speciality,
          ),

          _detailRow(
            Icons.person_outline,
            'Patient',
            appointment.patient,
          ),

          _detailRow(
            Icons.badge_outlined,
            'NIC',
            appointment.nic,
          ),

          if (appointment
              .dateOfBirth
              .isNotEmpty)
            _detailRow(
              Icons.cake_outlined,
              'Date of Birth',
              appointment.dateOfBirth,
            ),

          if (appointment
              .contact
              .isNotEmpty)
            _detailRow(
              Icons.phone_outlined,
              'Contact',
              appointment.contact,
            ),

          if (appointment
              .appointmentId
              .isNotEmpty)
            _detailRow(
              Icons.confirmation_number_outlined,
              'Appointment ID',
              appointment
                  .appointmentId,
            ),

          if (appointment
              .estimatedQueueNumber
              .isNotEmpty)
            _detailRow(
              Icons.people_alt_outlined,
              'Est. Queue No.',
              appointment
                  .estimatedQueueNumber,
            ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary300,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                        AppColors.gray500,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value.isEmpty
                      ? '-'
                      : value,
                  softWrap: true,
                  style: TextStyle(
                    color:
                        AppColors.primary900,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}