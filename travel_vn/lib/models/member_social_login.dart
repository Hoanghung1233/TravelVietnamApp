class MemberSocialLogin {
  final int socialLoginId;
  final String memberId;
  final String provider;
  final String providerUserId;
  final DateTime createdAt;

  MemberSocialLogin({
    required this.socialLoginId,
    required this.memberId,
    required this.provider,
    required this.providerUserId,
    required this.createdAt,
  });

  factory MemberSocialLogin.fromMap(Map<String, dynamic> map) {
    return MemberSocialLogin(
      socialLoginId: map['socialLoginId'],
      memberId: map['memberId'],
      provider: map['provider'],
      providerUserId: map['providerUserId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'socialLoginId': socialLoginId,
      'memberId': memberId,
      'provider': provider,
      'providerUserId': providerUserId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
