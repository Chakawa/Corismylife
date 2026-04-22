import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// Types de ligne markdown
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

/// Widget qui affiche du contenu Markdown avec les paragraphes justifiés.
/// Sépare les titres, séparateurs, listes et paragraphes ligne par ligne
/// pour garantir la séparation visuelle même sans lignes vides dans le markdown.
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

      // Heading et separator : chaque ligne = son propre bloc
      if (type == _LineType.heading || type == _LineType.separator) {
        flush();
        blocks.add(_Block(line.trim(), type));
        currentType = _LineType.empty;
        continue;
      }

      // Changement de type → flush et démarrer un nouveau bloc
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
      children: blocks.map((block) {
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

/// Paragraphe justifié avec parsing inline : **gras**, *italique*, `code`
class _JustifiedParagraph extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const _JustifiedParagraph({required this.text, this.baseStyle});

  List<InlineSpan> _parseInline(String text, TextStyle style) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(
      r'\*\*\*(.+?)\*\*\*|\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`',
      dotAll: true,
    );
    int lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: style));
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
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: style));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: style));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final effective = baseStyle ?? DefaultTextStyle.of(context).style;
    // Jointure des lignes multiples avec un espace
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


/// Widget qui affiche du contenu Markdown avec les paragraphes justifiés.
///
/// Stratégie : on découpe le markdown en blocs (séparés par des lignes vides).
/// - Blocs paragraphe → RichText(textAlign: TextAlign.justify) avec parsing
///   inline manuel (gras, italique, code).
/// - Blocs non-paragraphe (titres, listes, etc.) → MarkdownBody standard.
///
/// Cette approche évite totalement le mécanisme MarkdownElementBuilder de
/// flutter_markdown, qui causait l'assertion '_inlines.isEmpty: is not true'.
class JustifiedMarkdownBody extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet styleSheet;

  const JustifiedMarkdownBody({
    super.key,
    required this.data,
    required this.styleSheet,
  });

  // Découpe le markdown en blocs (séparés par une ou plusieurs lignes vides)
  List<String> _splitIntoBlocks(String text) {
    return text
        .split(RegExp(r'\n[ \t]*\n'))
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();
  }

  // Détermine si un bloc est un paragraphe simple (pas un titre, liste, etc.)
  bool _isParagraph(String block) {
    final t = block;
    // Ligne horizontale (---, ***, ___)
    if (RegExp(r'^[-*_]{3,}$').hasMatch(t.replaceAll(' ', ''))) return false;
    // Titre (#, ##, ###, etc.)
    if (RegExp(r'^#{1,6}\s').hasMatch(t)) return false;
    // Liste non-ordonnée
    if (RegExp(r'^[-*+]\s').hasMatch(t)) return false;
    // Liste ordonnée
    if (RegExp(r'^\d+\.\s').hasMatch(t)) return false;
    // Bloc de code indenté
    if (t.startsWith('    ') || t.startsWith('\t')) return false;
    // Bloc de code clôturé
    if (t.startsWith('```')) return false;
    // Citation
    if (t.startsWith('>')) return false;
    // Tableau
    if (t.startsWith('|')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _splitIntoBlocks(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: blocks.map((block) {
        if (_isParagraph(block)) {
          return _JustifiedParagraph(
            text: block,
            baseStyle: styleSheet.p,
          );
        } else {
          return MarkdownBody(data: block, styleSheet: styleSheet);
        }
      }).toList(),
    );
  }
}

/// Rendu d'un paragraphe avec TextAlign.justify et parsing inline simplifié.
class _JustifiedParagraph extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const _JustifiedParagraph({required this.text, this.baseStyle});

  /// Parse le markdown inline : ***bold+italic***, **bold**, *italic*, `code`
  List<InlineSpan> _parseInline(String text, TextStyle style) {
    final spans = <InlineSpan>[];
    // Ordre important : tester ***...*** avant **...** avant *...*
    final pattern = RegExp(
      r'\*\*\*(.+?)\*\*\*'  // ***bold+italic***
      r'|\*\*(.+?)\*\*'     // **bold**
      r'|\*(.+?)\*'         // *italic*
      r'|`(.+?)`',          // `code`
      dotAll: true,
    );

    int lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      // Texte brut avant le match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: style,
        ));
      }

      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: style.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
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

    // Texte restant après le dernier match
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: style));
    }

    // Fallback : texte brut sans formatage
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: style));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final effective = baseStyle ?? DefaultTextStyle.of(context).style;
    // Normaliser les retours à la ligne simples (soft breaks) → espace
    final normalized = text.replaceAll(RegExp(r'(?<!\n)\n(?!\n)'), ' ');
    final spans = _parseInline(normalized, effective);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(style: effective, children: spans),
        textAlign: TextAlign.justify,
        textScaler: MediaQuery.textScalerOf(context),
      ),
    );
  }
}

