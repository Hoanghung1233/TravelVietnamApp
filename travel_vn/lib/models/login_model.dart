class LoginModel {
  final String email;
  final String password;

  LoginModel({
    required this.email,
    required this.password,
  });

  factory LoginModel.fromMap(Map<String, dynamic> map) {
    return LoginModel(
      email: map['email'],
      password: map['password'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class LoginResult {
  final bool success;
  final String? token;
  final String message;

  LoginResult({
    required this.success,
    this.token,
    required this.message,
  });

  factory LoginResult.fromMap(Map<String, dynamic> map) {
    return LoginResult(
      success: map['success'] ?? false,
      token: map['token'],
      message: map['message'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'token': token,
      'message': message,
    };
  }
}
