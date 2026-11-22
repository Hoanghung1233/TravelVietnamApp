enum Role {
  Admin,
  Member,
}

class UpdateRoleModel {
  final String memberId;
  final Role role;

  UpdateRoleModel({
    required this.memberId,
    required this.role,
  });

  factory UpdateRoleModel.fromMap(Map<String, dynamic> map) {
    return UpdateRoleModel(
      memberId: map['memberId'],
      role: Role.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => Role.Member,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'role': role.name,
    };
  }
}
