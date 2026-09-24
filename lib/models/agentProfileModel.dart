class AgentProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;

  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;

  AgentProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.state,
    this.pincode,
  });

  factory AgentProfileModel.fromJson(Map<String, dynamic> json) {
    return AgentProfileModel(
      id: json['id']?.toString() ?? json['agentId']?.toString() ?? '',

      fullName: json['fullName']?.toString() ?? '',

      email: json['email']?.toString() ?? '',

      phone: json['phone']?.toString() ?? '',

      role: json['role']?.toString() ?? 'AGENT',

      dateOfBirth: json['dateOfBirth']?.toString(),

      gender: json['gender']?.toString(),

      address: json['address']?.toString(),

      city: json['city']?.toString(),

      state: json['state']?.toString(),

      pincode: json['pincode']?.toString(),
    );
  }
}
