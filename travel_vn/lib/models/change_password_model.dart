class ChangePasswordModel {
  final String currentPassword;
  final String newPassword;

  ChangePasswordModel({
    required this.currentPassword,
    required this.newPassword,
  });

  factory ChangePasswordModel.fromMap(Map<String, dynamic> map) {
    return ChangePasswordModel(
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
