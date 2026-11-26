import 'package:flutter/material.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;

  const MarkdownToolbar({
    super.key,
    required this.controller,
  });

  void _wrapSelection(String prefix, String suffix, {String defaultText = ''}) {
    final text = controller.text;
    final selection = controller.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start + prefix.length,
          extentOffset: selection.start + prefix.length + selectedText.length,
        ),
      );
    } else {
      final insertPosition = selection.isValid ? selection.start : text.length;
      final insertText = '$prefix$defaultText$suffix';
      final newText = text.replaceRange(
        insertPosition,
        insertPosition,
        insertText,
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: insertPosition + prefix.length,
          extentOffset: insertPosition + prefix.length + defaultText.length,
        ),
      );
    }
  }

  void _insertPrefixAtLineStart(String prefix) {
    final text = controller.text;
    final selection = controller.selection;
    final cursorIndex = selection.isValid ? selection.start : text.length;

    int lineStart = text.lastIndexOf('\n', cursorIndex > 0 ? cursorIndex - 1 : 0);
    if (lineStart == -1) {
      lineStart = 0;
    } else {
      lineStart += 1;
    }

    final newText = text.replaceRange(lineStart, lineStart, prefix);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: cursorIndex + prefix.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? colorScheme.surfaceVariant.withOpacity(0.3)
        : colorScheme.surfaceVariant.withOpacity(0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildButton(
              context: context,
              icon: Icons.format_bold,
              tooltip: l10n.formatBold,
              onPressed: () => _wrapSelection('**', '**', defaultText: 'văn bản đậm'),
            ),
            _buildButton(
              context: context,
              icon: Icons.format_italic,
              tooltip: l10n.formatItalic,
              onPressed: () => _wrapSelection('*', '*', defaultText: 'văn bản nghiêng'),
            ),
            _buildButton(
              context: context,
              icon: Icons.title,
              tooltip: l10n.formatHeading,
              onPressed: () => _insertPrefixAtLineStart('## '),
            ),
            const SizedBox(
              height: 20,
              child: VerticalDivider(width: 12, thickness: 1),
            ),
            _buildButton(
              context: context,
              icon: Icons.format_list_bulleted,
              tooltip: l10n.formatBulletList,
              onPressed: () => _insertPrefixAtLineStart('- '),
            ),
            _buildButton(
              context: context,
              icon: Icons.format_list_numbered,
              tooltip: l10n.formatNumberedList,
              onPressed: () => _insertPrefixAtLineStart('1. '),
            ),
            _buildButton(
              context: context,
              icon: Icons.format_quote,
              tooltip: l10n.formatQuote,
              onPressed: () => _insertPrefixAtLineStart('> '),
            ),
            _buildButton(
              context: context,
              icon: Icons.code,
              tooltip: l10n.formatCode,
              onPressed: () => _wrapSelection('`', '`', defaultText: 'code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
