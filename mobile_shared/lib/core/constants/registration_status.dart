enum ERegistrationStatus {
  incomplete('incomplete'),
  completed('complete');

  final String value;
  const ERegistrationStatus(this.value);

  static ERegistrationStatus? fromString(String val) {
    for (var status in ERegistrationStatus.values) {
      if (status.value == val) return status;
    }
    return null;
  }
}
