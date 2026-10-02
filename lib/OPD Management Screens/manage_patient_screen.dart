import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'opd_bottom_nav.dart';

class ManagePatientScreen extends StatefulWidget {
  final String? searchNic;

  const ManagePatientScreen({
    super.key,
    this.searchNic,
  });

  @override
  State<ManagePatientScreen> createState() => _ManagePatientScreenState();
}

class _ManagePatientScreenState extends State<ManagePatientScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _dobController;
  late final TextEditingController _nicController;
  late final TextEditingController _addressController;
  late final TextEditingController _emailController;
  late final TextEditingController _contactController;

  String _gender = 'Male';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.searchNic ?? '952345678V');
    _firstNameController = TextEditingController(text: 'Suresh');
    _lastNameController = TextEditingController(text: 'Jayawardena');
    _dobController = TextEditingController(text: '14/05/1995');
    _nicController = TextEditingController(text: '952345678V');
    _addressController =
        TextEditingController(text: 'No. 45, Galle Road, Colombo 03.');
    _emailController = TextEditingController(text: 'suresh.j@gmail.com');
    _contactController = TextEditingController(text: '071-234-5678');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _nicController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    if (!_isEditing) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 5, 14),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: OpdColors.primary400,
              onPrimary: OpdColors.white,
              onSurface: OpdColors.primary500,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _saveRecord() {
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: OpdColors.primary400,
        content: Text('Patient record updated successfully!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OpdColors.primary100,
      appBar: AppBar(
        backgroundColor: OpdColors.primary400,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OpdColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Patient Management',
              style: TextStyle(
                color: OpdColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Manage Patient Record',
              style: TextStyle(
                color: Color(0xFFD1E8E6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search / NIC Lookup bar
            Container(
              decoration: BoxDecoration(
                color: OpdColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: OpdColors.primary300.withValues(alpha: 0.7),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: OpdColors.primary500,
                ),
                decoration: const InputDecoration(
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

            const SizedBox(height: 16),

            _buildField(
              label: 'FIRST NAME',
              controller: _firstNameController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 10),

            _buildField(
              label: 'LAST NAME',
              controller: _lastNameController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 10),

            _buildField(
              label: 'DOB',
              controller: _dobController,
              enabled: _isEditing,
              trailingIcon: Icons.calendar_today_outlined,
              onTrailingTap: _selectDate,
              readOnly: true,
              onTap: _selectDate,
            ),
            const SizedBox(height: 10),

            // Gender Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GENDER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: OpdColors.primary500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: OpdColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: OpdColors.primary300.withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _gender,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: OpdColors.primary300,
                      ),
                      onChanged: _isEditing
                          ? (newVal) {
                              if (newVal != null) {
                                setState(() => _gender = newVal);
                              }
                            }
                          : null,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _buildField(
              label: 'NIC NO',
              controller: _nicController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 10),

            _buildField(
              label: 'ADDRESS',
              controller: _addressController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 10),

            _buildField(
              label: 'GMAIL',
              controller: _emailController,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),

            _buildField(
              label: 'CONTACT NO',
              controller: _contactController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            // Action Buttons Row: Edit | Save | Cancel
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OpdColors.primary400,
                        side: const BorderSide(
                          color: OpdColors.primary300,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _saveRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OpdColors.primary400,
                        foregroundColor: OpdColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        if (_isEditing) {
                          setState(() => _isEditing = false);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OpdColors.textMuted,
                        side: BorderSide(
                          color: OpdColors.borderLight,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const OpdBottomNav(currentIndex: 0),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    IconData? trailingIcon,
    VoidCallback? onTrailingTap,
    VoidCallback? onTap,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: OpdColors.primary500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: enabled ? OpdColors.white : const Color(0xFFF9FBFA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? OpdColors.primary300.withValues(alpha: 0.7)
                  : OpdColors.borderLight,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 12,
              color: OpdColors.textDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              border: InputBorder.none,
              suffixIcon: trailingIcon != null
                  ? IconButton(
                      icon: Icon(
                        trailingIcon,
                        size: 18,
                        color: OpdColors.primary300,
                      ),
                      onPressed: onTrailingTap,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
