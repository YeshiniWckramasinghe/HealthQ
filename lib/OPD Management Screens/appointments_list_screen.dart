import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'opd_bottom_nav.dart';
import 'appointment_details_screen.dart';

class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isTodaySelected = true;

  final List<Map<String, String>> _appointments = [
    {
      'token': 'T-001',
      'name': 'Kamal Perera',
      'department': 'General Medicine • 08:15',
      'status': 'Waiting',
    },
    {
      'token': 'T-002',
      'name': 'Nimali Bandara',
      'department': 'Cardiology • 08:30',
      'status': 'In Consult',
    },
    {
      'token': 'T-003',
      'name': 'Suresh Jayawardena',
      'department': 'General Medicine • 09:00',
      'status': 'Waiting',
    },
    {
      'token': 'T-004',
      'name': 'Dilrukshi Fernando',
      'department': 'Pediatrics • 09:15',
      'status': 'Waiting',
    },
    {
      'token': 'T-005',
      'name': 'Rohan Wickrama',
      'department': 'General Medicine • 09:30',
      'status': 'Absent',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OpdColors.primary100,
      appBar: AppBar(
        backgroundColor: OpdColors.primary400,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Appointments Management',
          style: TextStyle(
            color: OpdColors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: OpdColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: OpdColors.primary300.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by Token, Name or NIC...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: OpdColors.textMuted,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: OpdColors.primary300,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Segmented Toggle: [Today] | [By Date]
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: () =>
                              setState(() => _isTodaySelected = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTodaySelected
                                ? OpdColors.primary400
                                : OpdColors.white,
                            foregroundColor: _isTodaySelected
                                ? OpdColors.white
                                : OpdColors.primary400,
                            elevation: 0,
                            side: BorderSide(
                              color: OpdColors.primary300,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: () =>
                              setState(() => _isTodaySelected = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_isTodaySelected
                                ? OpdColors.primary400
                                : OpdColors.white,
                            foregroundColor: !_isTodaySelected
                                ? OpdColors.white
                                : OpdColors.primary400,
                            elevation: 0,
                            side: BorderSide(
                              color: OpdColors.primary300,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'By Date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Section Label
                const Text(
                  "TODAY'S APPOINTMENTS",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: OpdColors.primary500,
                  ),
                ),
              ],
            ),
          ),

          // Appointments List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final item = _appointments[index];
                return _buildAppointmentCard(context, item);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const OpdBottomNav(currentIndex: 1),
    );
  }

  Widget _buildAppointmentCard(
      BuildContext context, Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AppointmentDetailsScreen(
                token: item['token']!,
                patientName: item['name']!,
                status: item['status']!,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: OpdColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: OpdColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: OpdColors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Token Chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: OpdColors.primary100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: OpdColors.primary200.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  item['token']!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: OpdColors.primary400,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: OpdColors.primary500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['department']!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: OpdColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Chip
              _buildStatusChip(item['status']!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    Color border;

    switch (status) {
      case 'In Consult':
        bg = OpdColors.statusInConsultBg;
        fg = OpdColors.statusInConsultText;
        border = OpdColors.statusInConsultBorder;
        break;
      case 'Absent':
        bg = OpdColors.statusAbsentBg;
        fg = OpdColors.statusAbsentText;
        border = OpdColors.statusAbsentBorder;
        break;
      case 'Waiting':
      default:
        bg = OpdColors.statusWaitingBg;
        fg = OpdColors.statusWaitingText;
        border = OpdColors.statusWaitingBorder;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
