class Member {
  final String? memberId;
  final String? surname;
  final String? givenName;
  final String? email;
  final String? password;
  final String? phone;
  final String? avatar;
  final String role;
  final bool isEmailVerified;
  final DateTime? createdAt;

  Member({
    this.memberId,
    this.surname,
    this.givenName,
    this.email,
    this.password,
    this.phone,
    this.avatar,
    required this.role,
    required this.isEmailVerified,
    this.createdAt,
  });

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      memberId: map['memberId']?.toString(),
      surname: map['surname']?.toString(),
      givenName: map['givenName']?.toString(),
      email: map['email']?.toString(),
      password: map['password']?.toString(),
      phone: map['phone']?.toString(),
      avatar: map['avatar']?.toString(),
      role: map['role']?.toString() ?? 'Member',
      isEmailVerified: map['isEmailVerified'] == true ||
          map['isEmailVerified'] == 1 ||
          map['isEmailVerified'] == '1' ||
          map['isEmailVerified'] == 'true',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'surname': surname,
      'givenName': givenName,
      'email': email,
      'password': password,
      'phone': phone,
      'avatar': avatar,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
