class VietQRHelper {
  static String getQrImageUrl({
    required String bankCode,
    required String accountNumber,
    required double amount,
    required String accountName,
    String memo = 'Rut tien vi SmartSpace',
  }) {
    final cleanBank = bankCode.trim();
    final cleanAcc = accountNumber.trim();
    final amt = amount.round();
    final encMemo = Uri.encodeComponent(memo);
    final encName = Uri.encodeComponent(accountName.trim());
    return 'https://img.vietqr.io/image/$cleanBank-$cleanAcc-compact2.png?amount=$amt&addInfo=$encMemo&accountName=$encName';
  }
}

