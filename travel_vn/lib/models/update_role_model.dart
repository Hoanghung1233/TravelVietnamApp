enum Role {
  admin,
  member,
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
      role: switch (map['role']?.toString().toLowerCase()) {
        '0' || 'admin' => Role.admin,
        _ => Role.member,
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'role': role.index,
    };
  }
}
