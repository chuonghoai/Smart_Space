import 'package:flutter/services.dart';

class UpperCaseUnaccentFormatter extends TextInputFormatter {
  static const _withDia =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđĐÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸ';
  static const _withoutDia =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydDAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYY';

  static String removeDiacritics(String str) {
    var result = str;
    for (int i = 0; i < _withDia.length; i++) {
      result = result.replaceAll(_withDia[i], _withoutDia[i]);
    }
    return result.toUpperCase();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = removeDiacritics(newValue.text);
    return newValue.copyWith(
      text: newText,
      selection: updateCursorPosition(newText, newValue.selection),
    );
  }

  TextSelection updateCursorPosition(String newText, TextSelection selection) {
    final offset = selection.baseOffset.clamp(0, newText.length);
    return TextSelection.collapsed(offset: offset);
  }
}

