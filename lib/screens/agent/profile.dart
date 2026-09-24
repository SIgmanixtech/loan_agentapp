import 'package:flutter/material.dart';

import '../../core/theme/appColors.dart';
import '../../core/widgets/appBar.dart';
import '../../models/agentProfileModel.dart';
import '../../services/agentProfileService.dart';

class AgentProfile extends StatefulWidget {
  final VoidCallback onLogout;

  const AgentProfile({super.key, required this.onLogout});

  @override
  State<AgentProfile> createState() => _AgentProfileState();
}

class _AgentProfileState extends State<AgentProfile> {
  bool isLoading = true;
  bool isSaving = false;
  bool isEditing = false;

  String? errorMessage;

  AgentProfileModel? profile;

  final dateOfBirthController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();

  String? selectedGender;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  @override
  void dispose() {
    dateOfBirthController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();

    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await AgentProfileService.getProfile();

      if (!mounted) return;

      profile = result;

      _populateFields(result);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _populateFields(AgentProfileModel data) {
    dateOfBirthController.text = data.dateOfBirth ?? '';

    addressController.text = data.address ?? '';

    cityController.text = data.city ?? '';

    stateController.text = data.state ?? '';

    pincodeController.text = data.pincode ?? '';

    selectedGender = data.gender;
  }

  Future<void> _saveProfile() async {
    if (dateOfBirthController.text.trim().isEmpty) {
      _showError('Please enter your date of birth.');
      return;
    }

    if (selectedGender == null || selectedGender!.isEmpty) {
      _showError('Please select your gender.');
      return;
    }

    if (addressController.text.trim().isEmpty) {
      _showError('Please enter your address.');
      return;
    }

    if (cityController.text.trim().isEmpty) {
      _showError('Please enter your city.');
      return;
    }

    if (stateController.text.trim().isEmpty) {
      _showError('Please enter your state.');
      return;
    }

    if (pincodeController.text.trim().isEmpty) {
      _showError('Please enter your pincode.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final result = await AgentProfileService.updateProfile(
        dateOfBirth: dateOfBirthController.text.trim(),
        gender: selectedGender!,
        address: addressController.text.trim(),
        city: cityController.text.trim(),
        state: stateController.text.trim(),
        pincode: pincodeController.text.trim(),
      );

      if (!mounted) return;

      profile = result;

      _populateFields(result);

      setState(() {
        isEditing = false;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initialDate = DateTime(1995, 1, 1);

    if (dateOfBirthController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(dateOfBirthController.text);
      } catch (_) {}
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) {
      return;
    }

    final month = selectedDate.month.toString().padLeft(2, '0');

    final day = selectedDate.day.toString().padLeft(2, '0');

    dateOfBirthController.text = '${selectedDate.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AgentAppBar(title: 'Profile', onLogout: widget.onLogout),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return _buildError();
    }

    if (profile == null) {
      return const Center(child: Text('Profile information unavailable.'));
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildBasicInformation(),

          const SizedBox(height: 20),

          _buildPersonalInformation(),

          const SizedBox(height: 20),

          _buildAddressInformation(),
        ],
      ),
    );
  }

  Widget _buildBasicInformation() {
    return _sectionCard(
      title: 'Basic Information',
      children: [
        _infoRow(
          icon: Icons.person_outline,
          label: 'Full Name',
          value: profile!.fullName,
        ),

        const Divider(),

        _infoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: profile!.email,
        ),

        const Divider(),

        _infoRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: profile!.phone,
        ),
      ],
    );
  }

  Widget _buildPersonalInformation() {
    return _sectionCard(
      title: 'Personal Information',
      children: [
        if (!isEditing)
          _infoRow(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: profile!.dateOfBirth ?? 'Not provided',
          ),

        if (!isEditing) const Divider(),

        if (!isEditing)
          _infoRow(
            icon: Icons.person_outline,
            label: 'Gender',
            value: profile!.gender ?? 'Not provided',
          ),

        if (isEditing) ...[
          TextField(
            controller: dateOfBirthController,
            readOnly: true,
            onTap: _selectDateOfBirth,
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              prefixIcon: Icon(Icons.cake_outlined),
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: selectedGender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('Male')),
              DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
              DropdownMenuItem(value: 'OTHER', child: Text('Other')),
            ],
            onChanged: (value) {
              setState(() {
                selectedGender = value;
              });
            },
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : _saveProfile,
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 50,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isSaving
                  ? null
                  : () {
                      if (profile != null) {
                        _populateFields(profile!);
                      }

                      setState(() {
                        isEditing = false;
                      });
                    },
              child: const Text('Cancel'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddressInformation() {
    return _sectionCard(
      title: 'Address',
      children: [
        if (!isEditing)
          _infoRow(
            icon: Icons.home_outlined,
            label: 'Address',
            value: profile!.address ?? 'Not provided',
          ),

        if (!isEditing) const Divider(),

        if (!isEditing)
          _infoRow(
            icon: Icons.location_city_outlined,
            label: 'City',
            value: profile!.city ?? 'Not provided',
          ),

        if (!isEditing) const Divider(),

        if (!isEditing)
          _infoRow(
            icon: Icons.map_outlined,
            label: 'State',
            value: profile!.state ?? 'Not provided',
          ),

        if (!isEditing) const Divider(),

        if (!isEditing)
          _infoRow(
            icon: Icons.pin_drop_outlined,
            label: 'Pincode',
            value: profile!.pincode ?? 'Not provided',
          ),

        if (isEditing) ...[
          TextField(
            controller: addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.home_outlined),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: stateController,
            decoration: const InputDecoration(
              labelText: 'State',
              prefixIcon: Icon(Icons.map_outlined),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: pincodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Pincode',
              prefixIcon: Icon(Icons.pin_drop_outlined),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          ...children,

          if (!isEditing && title != 'Basic Information') ...[
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    isEditing = true;
                  });
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profile'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),

          const Icon(Icons.error_outline, size: 56, color: AppColors.error),

          const SizedBox(height: 16),

          const Center(
            child: Text(
              'Unable to load profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}
