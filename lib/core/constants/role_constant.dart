enum ERole {
  admin('admin'),
  staff('staff'),
  client('client');

  final String value;
  const ERole(this.value);

  static ERole? fromString(String val) {
    for (var role in ERole.values) {
      if (role.value == val) return role;
    }
    return null;
  }
}
