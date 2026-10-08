import 'dart:async';

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
  static const _genders = ['MALE', 'FEMALE', 'OTHER'];

  bool isLoading = true;
  bool isSaving = false;
  bool isEditing = false;
  bool isPincodeLoading = false;

  String? errorMessage;

  AgentProfileModel? profile;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();

  String? selectedGender;

  List<String> cityOptions = [];

  Timer? _pincodeDebounce;

  @override
  void initState() {
    super.initState();

    pincodeController.addListener(_onPincodeChanged);

    _loadProfile();
  }

  @override
  void dispose() {
    _pincodeDebounce?.cancel();

    pincodeController.removeListener(_onPincodeChanged);

    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    dateOfBirthController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();

    super.dispose();
  }

  Future<void> _loadProfile() async {
    // Refreshing while editing would discard the unsaved changes.
    if (isEditing) {
      return;
    }

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
    fullNameController.text = data.fullName;

    emailController.text = data.email;

    phoneController.text = data.phone;

    dateOfBirthController.text = data.dateOfBirth ?? '';

    addressController.text = data.address ?? '';

    cityController.text = data.city ?? '';

    stateController.text = data.state ?? '';

    pincodeController.text = data.pincode ?? '';

    final gender = data.gender?.toUpperCase();

    selectedGender = _genders.contains(gender) ? gender : null;
  }

  void _startEditing() {
    if (profile == null) {
      return;
    }

    _populateFields(profile!);

    setState(() {
      isEditing = true;
      cityOptions = [];
    });

    final pincode = pincodeController.text.trim();

    if (RegExp(r'^\d{6}$').hasMatch(pincode)) {
      _lookupPincode(pincode, keepExistingCity: true);
    }
  }

  void _cancelEditing() {
    _pincodeDebounce?.cancel();

    setState(() {
      isEditing = false;
      isPincodeLoading = false;
      cityOptions = [];
    });

    if (profile != null) {
      _populateFields(profile!);
    }
  }

  void _onPincodeChanged() {
    if (!isEditing || isSaving) {
      return;
    }

    final pincode = pincodeController.text.trim();

    _pincodeDebounce?.cancel();

    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      if (cityOptions.isNotEmpty ||
          cityController.text.isNotEmpty ||
          stateController.text.isNotEmpty ||
          isPincodeLoading) {
        setState(() {
          cityOptions = [];
          cityController.clear();
          stateController.clear();
          isPincodeLoading = false;
        });
      }

      return;
    }

    _pincodeDebounce = Timer(const Duration(milliseconds: 500), () {
      _lookupPincode(pincode);
    });
  }

  Future<void> _lookupPincode(
    String pincode, {
    bool keepExistingCity = false,
  }) async {
    final existingCity = keepExistingCity ? cityController.text.trim() : '';

    setState(() {
      isPincodeLoading = true;
      cityOptions = [];

      if (!keepExistingCity) {
        cityController.clear();
        stateController.clear();
      }
    });

    PincodeResult? result;
    String? lookupError;

    try {
      result = await AgentProfileService.lookupPincode(pincode);
    } catch (e) {
      lookupError = e.toString().replaceFirst('Exception: ', '');
    }

    // Ignore the answer if the PIN code was changed in the meantime.
    if (!mounted || !isEditing || pincodeController.text.trim() != pincode) {
      return;
    }

    if (result == null) {
      setState(() {
        isPincodeLoading = false;
      });

      _showError(lookupError ?? 'Unable to verify this PIN code.');

      return;
    }

    final areas = result.areas;
    final state = result.state;

    final matchingCity = areas
        .where((area) => area.toLowerCase() == existingCity.toLowerCase())
        .firstOrNull;

    setState(() {
      isPincodeLoading = false;
      cityOptions = areas;
      stateController.text = state;
      cityController.text = matchingCity ?? '';
    });
  }

  Future<void> _saveProfile() async {
    final pincode = pincodeController.text.trim();
    final city = cityController.text.trim();
    final state = stateController.text.trim();

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

    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      _showError('Please enter a valid 6-digit PIN code.');
      return;
    }

    if (isPincodeLoading) {
      _showError('Please wait while we verify the PIN code.');
      return;
    }

    if (cityOptions.isEmpty || state.isEmpty) {
      _showError('Please enter a valid PIN code and select your city/area.');
      return;
    }

    if (!cityOptions.contains(city)) {
      _showError('Please select your city/area.');
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
        city: city,
        state: state,
        pincode: pincode,
      );

      if (!mounted) return;

      profile = result;

      setState(() {
        isEditing = false;
        isSaving = false;
        cityOptions = [];
      });

      _populateFields(result);

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

          const SizedBox(height: 20),

          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildBasicInformation() {
    return _sectionCard(
      title: 'Basic Information',
      children: [
        if (!isEditing) ...[
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

        if (isEditing) ...[
          TextField(
            controller: fullNameController,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
              helperText: 'Full name cannot be changed',
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: emailController,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              helperText: 'Email cannot be changed',
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: phoneController,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone_outlined),
              helperText: 'Phone number cannot be changed',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPersonalInformation() {
    return _sectionCard(
      title: 'Personal Information',
      children: [
        if (!isEditing) ...[
          _infoRow(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: profile!.dateOfBirth ?? 'Not provided',
          ),

          const Divider(),

          _infoRow(
            icon: Icons.person_outline,
            label: 'Gender',
            value: profile!.gender ?? 'Not provided',
          ),
        ],

        if (isEditing) ...[
          TextField(
            controller: dateOfBirthController,
            enabled: !isSaving,
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
            onChanged: isSaving
                ? null
                : (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
          ),
        ],
      ],
    );
  }

  Widget _buildAddressInformation() {
    return _sectionCard(
      title: 'Address',
      children: [
        if (!isEditing) ...[
          _infoRow(
            icon: Icons.home_outlined,
            label: 'Address',
            value: profile!.address ?? 'Not provided',
          ),

          const Divider(),

          _infoRow(
            icon: Icons.pin_drop_outlined,
            label: 'PIN Code',
            value: profile!.pincode ?? 'Not provided',
          ),

          const Divider(),

          _infoRow(
            icon: Icons.location_city_outlined,
            label: 'City / Area',
            value: profile!.city ?? 'Not provided',
          ),

          const Divider(),

          _infoRow(
            icon: Icons.map_outlined,
            label: 'State',
            value: profile!.state ?? 'Not provided',
          ),
        ],

        if (isEditing) ...[
          TextField(
            controller: addressController,
            enabled: !isSaving,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.home_outlined),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: pincodeController,
            enabled: !isSaving,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'PIN Code',
              prefixIcon: const Icon(Icons.pin_drop_outlined),
              counterText: '',
              helperText: cityOptions.isEmpty
                  ? null
                  : '${cityOptions.length} area${cityOptions.length == 1 ? '' : 's'} found for this PIN',
              suffixIcon: isPincodeLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: cityOptions.contains(cityController.text)
                ? cityController.text
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'City / Area',
              prefixIcon: const Icon(Icons.location_city_outlined),
              hintText: cityOptions.isEmpty
                  ? 'Enter PIN code first'
                  : 'Select your city / area',
            ),
            items: cityOptions.map((area) {
              return DropdownMenuItem<String>(
                value: area,
                child: Text(area, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: cityOptions.isEmpty || isSaving
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      cityController.text = value;
                    });
                  },
          ),

          const SizedBox(height: 16),

          TextField(
            controller: stateController,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'State',
              prefixIcon: Icon(Icons.map_outlined),
              helperText: 'State is automatically determined from PIN code',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    if (!isEditing) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _startEditing,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Profile'),
        ),
      );
    }

    return Column(
      children: [
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
            onPressed: isSaving ? null : _cancelEditing,
            child: const Text('Cancel'),
          ),
        ),
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
