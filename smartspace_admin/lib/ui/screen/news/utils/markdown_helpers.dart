import 'package:flutter/material.dart';

/// Controller for auto-continuing and auto-exiting lists (numbered & bulleted)
/// when the user presses Enter in a Markdown text area.
class MarkdownAutoListEditingController extends TextEditingController {
  MarkdownAutoListEditingController({super.text});

  @override
  set value(TextEditingValue newValue) {
    final oldValue = value;

    // Check if user pressed Enter (single character '\n' inserted, collapsed cursor)
    if (oldValue.selection.isCollapsed &&
        newValue.selection.isCollapsed &&
        oldValue.selection.baseOffset >= 0 &&
        newValue.text.length == oldValue.text.length + 1 &&
        newValue.selection.baseOffset > 0 &&
        newValue.text[newValue.selection.baseOffset - 1] == '\n') {
      final cursorOffset = oldValue.selection.baseOffset;
      // Find the start of the line that was just completed
      int lineStart = oldValue.text.lastIndexOf('\n', cursorOffset - 1);
      lineStart = lineStart == -1 ? 0 : lineStart + 1;
      final line = oldValue.text.substring(lineStart, cursorOffset);

      // 1. Numbered list: e.g. "1. ", "  2. text"
      final numMatch = RegExp(r'^(\s*)(\d+)\.\s*(.*)$').firstMatch(line);
      if (numMatch != null) {
        final indent = numMatch.group(1) ?? '';
        final number = int.tryParse(numMatch.group(2) ?? '1') ?? 1;
        final content = numMatch.group(3) ?? '';

        if (content.trim().isEmpty) {
          // Empty item: user hit Enter on e.g. "1. " -> exit list mode
          final beforeLine =
              oldValue.text.substring(0, lineStart + indent.length);
          final afterLine = oldValue.text.substring(cursorOffset);
          final newText = beforeLine + afterLine;
          final newOffset = lineStart + indent.length;
          super.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newOffset),
          );
          return;
        } else {
          // Non-empty item: user hit Enter on e.g. "1. Hello" -> insert "2. "
          final nextPrefix = '$indent${number + 1}. ';
          final before = oldValue.text.substring(0, cursorOffset);
          final after = oldValue.text.substring(cursorOffset);
          final newText = '$before\n$nextPrefix$after';
          final newOffset = cursorOffset + 1 + nextPrefix.length;
          super.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newOffset),
          );
          return;
        }
      }

      // 2. Bullet list: e.g. "- ", "* ", "+ "
      final bulletMatch = RegExp(r'^(\s*)([-*+])\s*(.*)$').firstMatch(line);
      if (bulletMatch != null) {
        final indent = bulletMatch.group(1) ?? '';
        final bullet = bulletMatch.group(2) ?? '-';
        final content = bulletMatch.group(3) ?? '';

        if (content.trim().isEmpty) {
          // Empty item: user hit Enter on e.g. "- " -> exit bullet list mode
          final beforeLine =
              oldValue.text.substring(0, lineStart + indent.length);
          final afterLine = oldValue.text.substring(cursorOffset);
          final newText = beforeLine + afterLine;
          final newOffset = lineStart + indent.length;
          super.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newOffset),
          );
          return;
        } else {
          // Non-empty item: user hit Enter on e.g. "- Hello" -> insert "- "
          final nextPrefix = '$indent$bullet ';
          final before = oldValue.text.substring(0, cursorOffset);
          final after = oldValue.text.substring(cursorOffset);
          final newText = '$before\n$nextPrefix$after';
          final newOffset = cursorOffset + 1 + nextPrefix.length;
          super.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newOffset),
          );
          return;
        }
      }
    }

    super.value = newValue;
  }
}

/// Formatter that preserves 100% of the user's manual newlines (single or multiple)
/// when rendered by CommonMark markdown viewers (flutter_markdown).
String formatMarkdownPreservingNewlines(String raw) {
  if (raw.isEmpty) return raw;

  final lines = raw.split('\n');
  final buffer = StringBuffer();
  bool inCodeBlock = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    if (trimmed.startsWith('```')) {
      inCodeBlock = !inCodeBlock;
      buffer.write(line);
    } else if (inCodeBlock) {
      buffer.write(line);
    } else {
      // In CommonMark, appending 2 trailing spaces forces a hard line break (<br>)
      if (!line.endsWith('  ')) {
        buffer.write('$line  ');
      } else {
        buffer.write(line);
      }
    }

    if (i < lines.length - 1) {
      buffer.write('\n');
    }
  }

  return buffer.toString();
}
