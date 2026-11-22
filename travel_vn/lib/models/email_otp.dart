class EmailOtp {
  final int otpId;
  final String memberId;
  final String email;
  final String codeHash;
  final String purpose;
  final DateTime expiresAt;
  final bool isUsed;
  final int attempts;
  final DateTime createdAt;

  EmailOtp({
    required this.otpId,
    required this.memberId,
    required this.email,
    required this.codeHash,
    required this.purpose,
    required this.expiresAt,
    required this.isUsed,
    required this.attempts,
    required this.createdAt,
  });

  factory EmailOtp.fromMap(Map<String, dynamic> map) {
    return EmailOtp(
      otpId: map['otpId'],
      memberId: map['memberId'],
      email: map['email'],
      codeHash: map['codeHash'],
      purpose: map['purpose'],
      expiresAt: DateTime.parse(map['expiresAt']),
      isUsed: map['isUsed'],
      attempts: map['attempts'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'otpId': otpId,
      'memberId': memberId,
      'email': email,
      'codeHash': codeHash,
      'purpose': purpose,
      'expiresAt': expiresAt.toIso8601String(),
      'isUsed': isUsed,
      'attempts': attempts,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
