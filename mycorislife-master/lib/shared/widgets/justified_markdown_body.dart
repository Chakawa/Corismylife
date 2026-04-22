import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

enum _LineType { heading, separator, listItem, paragraph, empty }

_LineType _classifyLine(String line) {
  final t = line.trim();
  if (t.isEmpty) return _LineType.empty;
  if (RegExp(r'^#{1,6}\s').hasMatch(t)) return _LineType.heading;
  if (RegExp(r'^[-*_]{3,}$').hasMatch(t.replaceAll(' ', ''))) return _LineType.separator;
  if (RegExp(r'^[-*+]\s').hasMatch(t)) return _LineType.listItem;
  if (RegExp(r'^\d+\.\s').hasMatch(t)) return _LineType.listItem;
  return _LineType.paragraph;
}

class _Block {
  final String content;
  final _LineType type;
  _Block(this.content, this.type);
}

class JustifiedMarkdownBody extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet styleSheet;

  const JustifiedMarkdownBody({
    super.key,
    required this.data,
    required this.styleSheet,
  });

  List<_Block> _parseBlocks(String text) {
    final lines = text.split('\n');
    final blocks = <_Block>[];
    final currentLines = <String>[];
    var currentType = _LineType.empty;

    void flush() {
      if (currentLines.isEmpty) return;
      blocks.add(_Block(currentLines.join('\n'), currentType));
      currentLines.clear();
    }

    for (final line in lines) {
      final type = _classifyLine(line);

      if (type == _LineType.empty) {
        flush();
        currentType = _LineType.empty;
        continue;
      }

      if (type == _LineType.heading || type == _LineType.separator) {
        flush();
        blocks.add(_Block(line.trim(), type));
        currentType = _LineType.empty;
        continue;
      }

      if (currentLines.isNotEmpty && type != currentType) {
        flush();
      }

      currentType = type;
      currentLines.add(line);
    }

    flush();
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: blocks.map<Widget>((block) {
        switch (block.type) {
          case _LineType.heading:
          case _LineType.separator:
          case _LineType.listItem:
            return Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: MarkdownBody(
                data: block.content,
                styleSheet: styleSheet,
              ),
            );
          case _LineType.paragraph:
            return _JustifiedParagraph(
              text: block.content,
              baseStyle: styleSheet.p,
            );
          case _LineType.empty:
            return const SizedBox(height: 4);
        }
      }).toList(),
    );
  }
}

class _JustifiedParagraph extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const _JustifiedParagraph({required this.text, this.baseStyle});

  List<InlineSpan> _parseInline(String raw, TextStyle style) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(
      r'\*\*\*(.+?)\*\*\*|\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`',
      dotAll: true,
    );
    int lastEnd = 0;
    for (final match in pattern.allMatches(raw)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: raw.substring(lastEnd, match.start), style: style));
      }
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: style.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: style.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(3),
          style: style.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: style.copyWith(fontFamily: 'monospace'),
        ));
      }
      lastEnd = match.end;
    }
    if (lastEnd < raw.length) {
      spans.add(TextSpan(text: raw.substring(lastEnd), style: style));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: raw, style: style));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final effective = baseStyle ?? DefaultTextStyle.of(context).style;
    final normalized = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(style: effective, children: _parseInline(normalized, effective)),
        textAlign: TextAlign.justify,
        textScaler: MediaQuery.textScalerOf(context),
      ),
    );
  }
}
