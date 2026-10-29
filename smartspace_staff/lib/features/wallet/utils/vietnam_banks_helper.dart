class BankInfo {
  final String code;
  final String shortName;
  final String fullName;

  const BankInfo({
    required this.code,
    required this.shortName,
    required this.fullName,
  });

  String get displayName => '$shortName - $fullName';
}

class VietnamBanksHelper {
  static const List<BankInfo> popularBanks = [
    BankInfo(code: 'MB', shortName: 'MBBank', fullName: 'Ngân hàng Quân Đội'),
    BankInfo(code: 'VCB', shortName: 'Vietcombank', fullName: 'Ngân hàng Ngoại Thương Việt Nam'),
    BankInfo(code: 'ICB', shortName: 'VietinBank', fullName: 'Ngân hàng Công Thương Việt Nam'),
    BankInfo(code: 'BIDV', shortName: 'BIDV', fullName: 'Ngân hàng Đầu tư và Phát triển Việt Nam'),
    BankInfo(code: 'TCB', shortName: 'Techcombank', fullName: 'Ngân hàng Kỹ Thương Việt Nam'),
    BankInfo(code: 'ACB', shortName: 'ACB', fullName: 'Ngân hàng Á Châu'),
    BankInfo(code: 'VPB', shortName: 'VPBank', fullName: 'Ngân hàng Việt Nam Thịnh Vượng'),
    BankInfo(code: 'TPB', shortName: 'TPBank', fullName: 'Ngân hàng Tiên Phong'),
    BankInfo(code: 'STB', shortName: 'Sacombank', fullName: 'Ngân hàng Sài Gòn Thương Tín'),
    BankInfo(code: 'HDB', shortName: 'HDBank', fullName: 'Ngân hàng Phát triển TP.HCM'),
    BankInfo(code: 'VBA', shortName: 'Agribank', fullName: 'Ngân hàng Nông nghiệp và PT Nông thôn'),
    BankInfo(code: 'SHB', shortName: 'SHB', fullName: 'Ngân hàng Sài Gòn - Hà Nội'),
    BankInfo(code: 'VIB', shortName: 'VIB', fullName: 'Ngân hàng Quốc tế Việt Nam'),
    BankInfo(code: 'MSB', shortName: 'MSB', fullName: 'Ngân hàng Hàng Hải'),
    BankInfo(code: 'OCB', shortName: 'OCB', fullName: 'Ngân hàng Phương Đông'),
    BankInfo(code: 'LPB', shortName: 'LPBank', fullName: 'Ngân hàng Lộc Phát Việt Nam'),
    BankInfo(code: 'SEAB', shortName: 'SeABank', fullName: 'Ngân hàng Đông Nam Á'),
    BankInfo(code: 'NAB', shortName: 'Nam A Bank', fullName: 'Ngân hàng Nam Á'),
    BankInfo(code: 'EIB', shortName: 'Eximbank', fullName: 'Ngân hàng Xuất Nhập Khẩu'),
    BankInfo(code: 'BVB', shortName: 'BVBank', fullName: 'Ngân hàng Bản Việt'),
    BankInfo(code: 'BAB', shortName: 'Bac A Bank', fullName: 'Ngân hàng Bắc Á'),
    BankInfo(code: 'PVB', shortName: 'PVcomBank', fullName: 'Ngân hàng Đại Chúng Việt Nam'),
    BankInfo(code: 'KLB', shortName: 'Kienlongbank', fullName: 'Ngân hàng Kiên Long'),
    BankInfo(code: 'SGB', shortName: 'Saigonbank', fullName: 'Ngân hàng Sài Gòn Công Thương'),
    BankInfo(code: 'PGB', shortName: 'PGBank', fullName: 'Ngân hàng Thịnh vượng và Phát triển'),
  ];

  static BankInfo? findBank(String query) {
    if (query.trim().isEmpty) return null;
    final q = query.trim().toLowerCase();
    for (final b in popularBanks) {
      if (b.code.toLowerCase() == q ||
          b.shortName.toLowerCase() == q ||
          b.fullName.toLowerCase() == q ||
          b.displayName.toLowerCase().contains(q)) {
        return b;
      }
    }
    return null;
  }
}

