class EmergencyContact {
  final String name;
  final String phoneNumber;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  // Convert EmergencyContact to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
    };
  }

  // Create EmergencyContact from JSON
  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      relationship: json['relationship'] ?? '',
    );
  }
}
