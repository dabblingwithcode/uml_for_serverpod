import 'package:uml_for_serverpod/src/models.dart';

/// A piece of label text with one style.
class Run {
  final String text;
  final bool bold;
  final bool italic;
  final String? color;
  const Run(this.text, {this.bold = false, this.italic = false, this.color});

  Run withText(String text) =>
      Run(text, bold: bold, italic: italic, color: color);
}

/// Escapes text for a Graphviz HTML-like label.
String escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Average glyph width relative to the font size, used to estimate how many
/// characters fit a width. Graphviz does not wrap, so wrapping happens here.
const double averageGlyphWidth = 0.6;

/// Font size of field rows in class cards.
const double fieldFontSize = 12;

/// How many characters of [fontSize] text fit [maxWidth] points.
int charsForWidth(num maxWidth, {double fontSize = fieldFontSize}) =>
    (maxWidth / (fontSize * averageGlyphWidth)).floor().clamp(8, 100000);

/// Word-wraps styled [runs] into lines of at most [maxChars] characters.
/// Words longer than a line are broken hard. Styles survive the breaks.
List<List<Run>> wrapRuns(List<Run> runs, int maxChars) {
  final lines = <List<Run>>[];
  var line = <Run>[];
  var length = 0;

  void newLine() {
    lines.add(line);
    line = <Run>[];
    length = 0;
  }

  void put(Run run, String text) {
    if (text.isEmpty) return;
    if (line.isNotEmpty && _sameStyle(line.last, run)) {
      line[line.length - 1] = line.last.withText(line.last.text + text);
    } else {
      line.add(run.withText(text));
    }
    length += text.length;
  }

  for (final run in runs) {
    // keep separators so spacing survives: "a b" -> ["a", " ", "b"]
    for (final token in RegExp(r'\s+|\S+').allMatches(run.text)) {
      var word = token.group(0)!;
      final isSpace = word.trim().isEmpty;
      if (isSpace) {
        // spaces at a line start are dropped, except leading indentation
        if (length == 0 && lines.isNotEmpty) continue;
        if (length + word.length > maxChars) {
          newLine();
          continue;
        }
        put(run, word);
        continue;
      }
      if (length + word.length > maxChars && length > 0) {
        _trimTrailingSpace(line);
        newLine();
      }
      while (length + word.length > maxChars) {
        final room = maxChars - length;
        put(run, word.substring(0, room));
        word = word.substring(room);
        newLine();
      }
      put(run, word);
    }
  }
  if (line.isNotEmpty || lines.isEmpty) lines.add(line);
  return lines;
}

bool _sameStyle(Run a, Run b) =>
    a.bold == b.bold && a.italic == b.italic && a.color == b.color;

void _trimTrailingSpace(List<Run> line) {
  if (line.isEmpty) return;
  final last = line.last;
  final trimmed = last.text.trimRight();
  if (trimmed.isEmpty) {
    line.removeLast();
  } else {
    line[line.length - 1] = last.withText(trimmed);
  }
}

String _renderRun(Run run) {
  var text = escapeHtml(run.text);
  if (run.color != null) text = '<FONT COLOR="${run.color}">$text</FONT>';
  if (run.italic) text = '<I>$text</I>';
  if (run.bold) text = '<B>$text</B>';
  return text;
}

/// Renders wrapped [runs] as left-aligned HTML label text.
String renderWrapped(List<Run> runs, int maxChars) => wrapRuns(runs, maxChars)
    .map((line) => line.map(_renderRun).join())
    .join('<BR ALIGN="LEFT"/>');

/// Background colour of the card header for each object type (the colours
/// the PlantUML output uses for whole cards).
String headerColor(UmlObject object, UmlConfig config) =>
    switch (object.objectType) {
      ObjectType.databaseClassType => '#e2f0fb',
      ObjectType.exceptionType => '#ffe6e6',
      ObjectType.enumType => '#ece4ff',
      _ => config.classBackgroundHexColor,
    };

const _keywordColor = '#f44336';
final _relationKeywords = RegExp(r'\b(relation|name|optional|onDelete)\b');

/// The styled runs of one field line, or null when it is not printed.
/// Mirrors the PlantUML field rendering.
List<Run>? fieldRuns(String key, String value, UmlConfig config) {
  if (value.contains('relation')) {
    final parts = value.split(',');
    final rest = parts.sublist(1).join(',');
    final runs = <Run>[
      const Run('→ '),
      Run(key, italic: true),
      const Run(' : '),
      Run(parts.first.trim(), bold: true, color: config.classNameHexColor),
      const Run(','),
    ];
    var last = 0;
    for (final m in _relationKeywords.allMatches(rest)) {
      runs.add(Run(rest.substring(last, m.start)));
      final word = m.group(0)!;
      runs.add(Run(word,
          bold: true,
          color: word == 'relation' ? config.relationHexColor : _keywordColor));
      last = m.end;
    }
    runs.add(Run(rest.substring(last)));
    return runs;
  }
  if (key.contains('##')) {
    return config.printComments
        ? [Run(key.trim(), color: config.commentHexColor)]
        : null;
  }
  if (key.contains('indexes:') || key.contains('idx:')) {
    return [Run(key, bold: true, color: config.relationHexColor)];
  }
  if (key.contains('unique')) {
    return [
      Run(key, bold: true, color: config.relationHexColor),
      const Run(': '),
      Run(value, bold: true, color: config.classNameHexColor),
    ];
  }
  return [
    Run(key, italic: true),
    const Run(': '),
    Run(value, bold: true, color: config.classNameHexColor),
  ];
}

/// Port name of the field row a relation edge starts from.
String fieldPort(String fieldName) =>
    'f_${fieldName.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')}';

/// The HTML-like label of a class, enum or exception card.
String cardLabel(UmlObject object, UmlConfig config) {
  final maxChars = config.classMaxWidth != null
      ? charsForWidth(config.classMaxWidth!)
      : 100000;
  final rows = StringBuffer();

  final header = StringBuffer();
  if (object.objectType == ObjectType.databaseClassType) {
    header.write('<FONT POINT-SIZE="12"><I>«table: '
        '<B>${escapeHtml(object.tableName ?? '')}</B>»</I></FONT><BR/>');
  } else if (object.objectType == ObjectType.enumType) {
    header.write('<FONT POINT-SIZE="12"><I>«enum»</I></FONT><BR/>');
  } else if (object.objectType == ObjectType.exceptionType) {
    header.write('<FONT POINT-SIZE="12"><I>«exception»</I></FONT><BR/>');
  }
  header.write(
      '<B><FONT POINT-SIZE="22">${escapeHtml(object.name ?? '')}</FONT></B>');
  rows.write('<TR><TD BGCOLOR="${headerColor(object, config)}" '
      'CELLPADDING="8">$header</TD></TR>');

  if (object.filepath != null) {
    rows.write('<TR><TD ALIGN="LEFT" BALIGN="LEFT"><FONT POINT-SIZE="10" '
        'COLOR="#666666">${renderWrapped([
          Run(object.filepath!)
        ], charsForWidth(config.classMaxWidth ?? 100000, fontSize: 10))}'
        '</FONT></TD></TR>');
  }
  rows.write('<HR/>');

  final lines = <(List<Run>, String?)>[];
  if (object.objectType == ObjectType.enumType) {
    if (object.enumSerialized != null) {
      lines.add((
        [
          const Run('serialized', italic: true),
          const Run(': '),
          Run(object.enumSerialized!,
              bold: true, color: config.classNameHexColor),
        ],
        null
      ));
    }
    if (object.enumValues != null) {
      lines.add((
        [
          const Run('values', italic: true),
          const Run(': '),
          Run(object.enumValues!, bold: true, color: config.classNameHexColor),
        ],
        null
      ));
    }
  } else {
    for (final entry in (object.fields ?? const <String, String>{}).entries) {
      final runs = fieldRuns(entry.key, entry.value, config);
      if (runs == null) continue;
      final port =
          entry.value.contains('relation') ? fieldPort(entry.key) : null;
      lines.add((runs, port));
    }
  }
  if (lines.isEmpty) {
    rows.write('<TR><TD> </TD></TR>');
  }
  for (final (runs, port) in lines) {
    final portAttr = port != null ? ' PORT="$port"' : '';
    rows.write('<TR><TD ALIGN="LEFT" BALIGN="LEFT"$portAttr>'
        '<FONT POINT-SIZE="${fieldFontSize.toInt()}">'
        '${renderWrapped(runs, maxChars)}</FONT></TD></TR>');
  }

  return '<<TABLE BORDER="2" CELLBORDER="0" CELLSPACING="0" CELLPADDING="4" '
      'COLOR="${config.classBorderHexColor}" '
      'BGCOLOR="${config.classBackgroundHexColor}">$rows</TABLE>>';
}
