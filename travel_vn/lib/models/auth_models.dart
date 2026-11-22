class RegisterModel {
  final String surname;
  final String givenName;
  final String email;
  final String password;
  final String? phone;

  RegisterModel({
    required this.surname,
    required this.givenName,
    required this.email,
    required this.password,
    this.phone,
  });

  factory RegisterModel.fromMap(Map<String, dynamic> map) {
    return RegisterModel(
      surname: map['surname'],
      givenName: map['givenName'],
      email: map['email'],
      password: map['password'],
      phone: map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'surname': surname,
      'givenName': givenName,
      'email': email,
      'password': password,
      'phone': phone,
    };
  }
}

class VerifyOtpModel {
  final String email;
  final String code;

  VerifyOtpModel({
    required this.email,
    required this.code,
  });

  factory VerifyOtpModel.fromMap(Map<String, dynamic> map) {
    return VerifyOtpModel(
      email: map['email'],
      code: map['code'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'code': code,
    };
  }
}

class SendOtpModel {
  final String email;

  SendOtpModel({
    required this.email,
  });

  factory SendOtpModel.fromMap(Map<String, dynamic> map) {
    return SendOtpModel(
      email: map['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
    };
  }
}

class ResetPasswordModel {
  final String email;
  final String code;
  final String newPassword;

  ResetPasswordModel({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  factory ResetPasswordModel.fromMap(Map<String, dynamic> map) {
    return ResetPasswordModel(
      email: map['email'],
      code: map['code'],
      newPassword: map['newPassword'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    };
  }
}

class SocialLoginModel {
  final String provider;
  final String accessToken;

  SocialLoginModel({
    required this.provider,
    required this.accessToken,
  });

  factory SocialLoginModel.fromMap(Map<String, dynamic> map) {
    return SocialLoginModel(
      provider: map['provider'],
      accessToken: map['accessToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'accessToken': accessToken,
    };
  }
}

class SetPasswordModel {
  final String newPassword;

  SetPasswordModel({
    required this.newPassword,
  });

  factory SetPasswordModel.fromMap(Map<String, dynamic> map) {
    return SetPasswordModel(
      newPassword: map['newPassword'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'newPassword': newPassword,
    };
  }
}

class UpdateEmailModel {
  final String email;

  UpdateEmailModel({
    required this.email,
  });

  factory UpdateEmailModel.fromMap(Map<String, dynamic> map) {
    return UpdateEmailModel(
      email: map['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
    };
  }
}

class UpdatePasswordModel {
  final String currentPassword;
  final String newPassword;

  UpdatePasswordModel({
    required this.currentPassword,
    required this.newPassword,
  });

  factory UpdatePasswordModel.fromMap(Map<String, dynamic> map) {
    return UpdatePasswordModel(
      currentPassword: map['currentPassword'],
      newPassword: map['newPassword'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
  }
}

class SocialUser {
  final String providerUserId;
  final String givenName;
  final String surname;
  final String? email;
  final bool isEmailVerified;
  final String? avatar;

  SocialUser({
    required this.providerUserId,
    required this.givenName,
    required this.surname,
    this.email,
    required this.isEmailVerified,
    this.avatar,
  });

  factory SocialUser.fromMap(Map<String, dynamic> map) {
    return SocialUser(
      providerUserId: map['providerUserId'],
      givenName: map['givenName'] ?? '',
      surname: map['surname'] ?? '',
      email: map['email'],
      isEmailVerified: map['isEmailVerified'] ?? false,
      avatar: map['avatar'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerUserId': providerUserId,
      'givenName': givenName,
      'surname': surname,
      'email': email,
      'isEmailVerified': isEmailVerified,
      'avatar': avatar,
    };
  }
}
