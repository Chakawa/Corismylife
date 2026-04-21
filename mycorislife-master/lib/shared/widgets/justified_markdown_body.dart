import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Widget qui affiche du contenu Markdown avec les paragraphes justifiés.
/// Préserve le formatage gras, italique et code des éléments inline.
class JustifiedMarkdownBody extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet styleSheet;

  const JustifiedMarkdownBody({
    super.key,
    required this.data,
    required this.styleSheet,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      styleSheet: styleSheet,
      builders: {
        'p': _JustifiedParagraphBuilder(
          pStyle: styleSheet.p,
          strongStyle: styleSheet.strong,
        ),
      },
    );
  }
}

/// Builder personnalisé pour les paragraphes markdown.
/// Rend le texte avec TextAlign.justify en préservant gras/italique.
class _JustifiedParagraphBuilder extends MarkdownElementBuilder {
  final TextStyle? pStyle;
  final TextStyle? strongStyle;

  _JustifiedParagraphBuilder({this.pStyle, this.strongStyle});

  List<InlineSpan> _buildSpans(List<md.Node>? nodes, TextStyle? baseStyle) {
    final spans = <InlineSpan>[];
    for (final node in nodes ?? []) {
      if (node is md.Text) {
        spans.add(TextSpan(text: node.text, style: baseStyle));
      } else if (node is md.Element) {
        TextStyle? childStyle;
        switch (node.tag) {
          case 'strong':
            childStyle = strongStyle ??
                baseStyle?.copyWith(fontWeight: FontWeight.bold) ??
                const TextStyle(fontWeight: FontWeight.bold);
            break;
          case 'em':
            childStyle = baseStyle?.copyWith(fontStyle: FontStyle.italic) ??
                const TextStyle(fontStyle: FontStyle.italic);
            break;
          case 'code':
            childStyle = baseStyle?.copyWith(fontFamily: 'monospace') ??
                const TextStyle(fontFamily: 'monospace');
            break;
          default:
            childStyle = baseStyle;
        }
        spans.addAll(_buildSpans(node.children, childStyle));
      }
    }
    return spans;
  }

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final effectiveStyle = pStyle ?? preferredStyle;
    final spans = _buildSpans(element.children, effectiveStyle);
    if (spans.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(children: spans),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
