import 'dart:convert';
import 'dart:io';

import 'package:uml_for_serverpod/src/graphviz/diagram_graph.dart';
import 'package:uml_for_serverpod/src/graphviz/dot_emitter.dart';
import 'package:uml_for_serverpod/src/models.dart';

/// The only SVG elements a rendered diagram may contain.
const allowedSvgElements = {
  'svg', 'g', 'path', 'polygon', 'ellipse', 'rect', 'line', 'polyline', //
  'text', 'tspan', 'title', 'desc', 'defs', 'marker', 'clipPath',
};

final _prolog = RegExp(r'<\?xml[^>]*\?>');
final _doctype = RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false);
final _comment = RegExp(r'<!--.*?-->', dotAll: true);
final _xlinkNamespace = RegExp(r'\s+xmlns:xlink="[^"]*"');
final _tag = RegExp(r'<\s*/?\s*([A-Za-z][\w:.-]*)([^>]*)>');
final _activeAttribute = RegExp(
    r'(?:^|\s)(href|xlink:[a-z]+|on[a-z]+|style|src)\s*=',
    caseSensitive: false);

/// Elements and active attributes in [svg] outside the inert allowlist.
/// Text content is escaped by Graphviz, so `<` only starts real markup.
List<String> svgViolations(String svg) => [
      for (final m in _tag.allMatches(svg)) ...[
        if (!allowedSvgElements.contains(m.group(1))) '<${m.group(1)}>',
        for (final a in _activeAttribute.allMatches(m.group(2)!))
          '${a.group(1)}=',
        if (m.group(2)!.contains('url(')) 'url()',
      ],
      if (svg.contains('<!') || svg.contains('<?')) 'markup declaration',
    ];

/// Strips the XML prolog, DOCTYPE (an external DTD reference), comments and
/// the xlink namespace, then refuses anything outside the inert allowlist.
String sanitizeSvg(String svg) {
  final clean = svg
      .replaceAll(_prolog, '')
      .replaceAll(_doctype, '')
      .replaceAll(_comment, '')
      .replaceAll(_xlinkNamespace, '')
      .trimLeft();
  final violations = svgViolations(clean);
  if (violations.isNotEmpty) {
    throw StateError('Graphviz SVG contains non-inert content: '
        '${violations.toSet().join(', ')}');
  }
  return clean;
}

/// Runs Graphviz executables from [binDir] (or the PATH when null).
class GraphvizRunner {
  final String? binDir;
  const GraphvizRunner({this.binDir});

  String executable(String tool) => binDir == null
      ? tool
      : '${binDir!.replaceFirst(RegExp(r'[/\\]$'), '')}${Platform.pathSeparator}$tool';

  /// Runs [tool] with [args], feeding [input] on stdin; returns stdout and
  /// stderr (Graphviz prints warnings there on success).
  Future<({String out, String err})> run(
      String tool, List<String> args, String input) async {
    final path = executable(tool);
    final Process process;
    try {
      process = await Process.start(path, args);
    } on ProcessException catch (e) {
      throw StateError('Graphviz `$tool` not found at `$path` (${e.message}). '
          'Install Graphviz (https://graphviz.org/download/) or set '
          'output.graphvizBinDir to the directory holding dot and neato.');
    }
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    process.stdin.write(input);
    await process.stdin.close();
    final code = await process.exitCode;
    final out = await stdoutFuture;
    final err = await stderrFuture;
    if (code != 0) {
      throw StateError('`$path ${args.join(' ')}` failed ($code): $err');
    }
    return (out: out, err: err);
  }
}

/// The two-pass Graphviz rendering of a model and what went into it.
class GraphvizResult {
  final String dot;
  final String svg;
  final DiagramGraph graph;
  final DiagramLayout layout;

  /// Edges the `splines=true` router could not route around the cards;
  /// Graphviz draws them as direct lines instead.
  final List<String> unroutedEdges;
  const GraphvizResult(
      this.dot, this.svg, this.graph, this.layout, this.unroutedEdges);
}

/// Pass 1 lays out each package's components with `dot -Tplain` (plain and
/// through `unflatten`, keeping the most balanced per component); the blocks
/// are placed on a grid in Dart; pass 2 renders one pinned graph with
/// `neato -n2 -Tsvg`, which routes the edges between the fixed blocks.
Future<GraphvizResult> renderGraphviz(
  Map<String, UmlObject> objectsMap,
  UmlConfig config, {
  GraphvizRunner? runner,
}) async {
  final gv = runner ?? GraphvizRunner(binDir: config.graphvizBinDir);
  final graph = DiagramGraph.build(objectsMap, config);
  final ids = nodeIds(graph);
  final components = layoutComponents(graph);

  final pass1 = pass1Dot(graph, components, ids, config);
  final variants = <List<PlainLayout>>[];
  for (final length in [null, ...unflattenLengths]) {
    final input = length == null
        ? pass1
        : (await gv.run('unflatten', ['-f', '-l', '$length'], pass1)).out;
    variants.add(parsePlain((await gv.run('dot', ['-Tplain'], input)).out));
  }
  final layout = placeDiagram(graph, components,
      chooseLayouts(variants, config.gridAspectRatio ?? 1.0), config);

  final dot = pass2Dot(graph, layout, ids, config);
  final rendered = await gv.run('neato', ['-n2', '-Tsvg'], dot);
  final unrouted = [
    for (final m in RegExp(r'for edge \(([^)]*)\)').allMatches(rendered.err))
      m.group(1)!
  ];
  return GraphvizResult(
      dot, sanitizeSvg(rendered.out), graph, layout, unrouted);
}
