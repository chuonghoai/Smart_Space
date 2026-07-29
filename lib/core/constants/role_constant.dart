enum Role {
  admin('admin'),
  staff('staff'),
  user('user');

  final String value;
  const Role(this.value);

  static Role? fromString(String val) {
    for (var role in Role.values) {
      if (role.value == val) return role;
    }
    return null;
  }
}
