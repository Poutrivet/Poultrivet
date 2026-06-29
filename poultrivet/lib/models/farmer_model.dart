class FarmerModel {
  final String uid;
  final String fullName;
  final String district;       // ← was "location", now a proper district name
  final String phoneNumber;
  final bool termsAccepted;
  final bool dataConsentAccepted;
  final DateTime createdAt;

  FarmerModel({
    required this.uid,
    required this.fullName,
    required this.district,
    required this.phoneNumber,
    required this.termsAccepted,
    required this.dataConsentAccepted,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'district': district,
      'phoneNumber': phoneNumber,
      'termsAccepted': termsAccepted,
      'dataConsentAccepted': dataConsentAccepted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FarmerModel.fromMap(Map<String, dynamic> map) {
    return FarmerModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      district: map['district'] ?? map['location'] ?? '', // fallback for old docs
      phoneNumber: map['phoneNumber'] ?? '',
      termsAccepted: map['termsAccepted'] ?? false,
      dataConsentAccepted: map['dataConsentAccepted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
