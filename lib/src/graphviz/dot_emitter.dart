import 'dart:math' as math;

import 'package:uml_for_serverpod/src/graphviz/diagram_graph.dart';
import 'package:uml_for_serverpod/src/graphviz/grid_layout.dart';
import 'package:uml_for_serverpod/src/graphviz/html_label.dart';
import 'package:uml_for_serverpod/src/models.dart';

/// Points per inch: Graphviz sizes are in inches, positions in points.
const double pointsPerInch = 72;

/// Space between connected components inside one package.
const double componentGap = 40;

/// Padding between a package box and its content.
const double packagePadding = 24;

/// Font size of package titles.
const double packageTitleFontSize = 28;

/// Height reserved for a package title above the content.
const double packageTitleHeight = 52;

/// Margin around the whole diagram.
const double diagramMargin = 40;

/// Connected objects of one package, laid out together by `dot` in pass 1.
class LayoutComponent {
  final int packageIndex;
  final List<String> names;
  const LayoutComponent(this.packageIndex, this.names);
}

/// A node box from pass 1: centre (y down) and size, in points.
class NodeBox {
  final double cx;
  final double cy;
  final double width;
  final double height;
  const NodeBox(this.cx, this.cy, this.width, this.height);
}

/// One `-Tplain` graph: its extent and node boxes keyed by node id, in points.
class PlainLayout {
  final double width;
  final double height;
  final Map<String, NodeBox> nodes;
  const PlainLayout(this.width, this.height, this.nodes);
}

/// A placed package box, y down, in points.
class PackageBox {
  final double x;
  final double y;
  final double width;
  final double height;
  const PackageBox(this.x, this.y, this.width, this.height);
}

/// The final pinned layout: node centres and package boxes, y down.
class DiagramLayout {
  final double width;
  final double height;
  final Map<String, NodeBox> nodes;

  /// One box per package of the graph; null for the loose objects.
  final List<PackageBox?> packageBoxes;
  final int columns;
  const DiagramLayout({
    required this.width,
    required this.height,
    required this.nodes,
    required this.packageBoxes,
    required this.columns,
  });
}

/// Stable DOT node ids (`n0`, `n1`, …) for every object, in package order.
Map<String, String> nodeIds(DiagramGraph graph) {
  final ids = <String, String>{};
  for (final package in graph.packages) {
    for (final object in package.objects) {
      ids[object.name!] = 'n${ids.length}';
    }
  }
  return ids;
}

/// Splits each package into connected components of its internal edges.
/// Components are ordered largest first, ties by their first object name.
List<LayoutComponent> layoutComponents(DiagramGraph graph) {
  final result = <LayoutComponent>[];
  for (var p = 0; p < graph.packages.length; p++) {
    final names = [for (final o in graph.packages[p].objects) o.name!];
    final parent = {for (final n in names) n: n};
    String find(String n) {
      while (parent[n] != n) {
        parent[n] = parent[parent[n]]!;
        n = parent[n]!;
      }
      return n;
    }

    for (final edge in graph.edges) {
      if (parent.containsKey(edge.from) && parent.containsKey(edge.to)) {
        parent[find(edge.from)] = find(edge.to);
      }
    }
    final groups = <String, List<String>>{};
    for (final n in names) {
      groups.putIfAbsent(find(n), () => []).add(n);
    }
    final components = groups.values.toList()
      ..sort((a, b) => a.length != b.length
          ? b.length.compareTo(a.length)
          : a.first.compareTo(b.first));
    result.addAll(components.map((c) => LayoutComponent(p, c)));
  }
  return result;
}

String _num(double v) => v.toStringAsFixed(2);

/// Pass 1: one `digraph` per component, each to be laid out alone by `dot`.
String pass1Dot(
  DiagramGraph graph,
  List<LayoutComponent> components,
  Map<String, String> ids,
  UmlConfig config,
) {
  final objects = {
    for (final p in graph.packages)
      for (final o in p.objects) o.name!: o
  };
  final nodesep = (config.skinparamNodesep ?? 30) / pointsPerInch;
  final ranksep = (config.skinparamRanksep ?? 80) / pointsPerInch;
  final out = StringBuffer();
  for (var c = 0; c < components.length; c++) {
    final members = components[c].names.toSet();
    out.writeln('digraph c$c {');
    out.writeln('  graph [rankdir=LR, nodesep=${_num(nodesep)}, '
        'ranksep=${_num(ranksep)}, fontname="Helvetica"];');
    out.writeln('  node [shape=plain, fontname="Helvetica"];');
    for (final name in components[c].names) {
      out.writeln(
          '  ${ids[name]} [label=${cardLabel(objects[name]!, config)}];');
    }
    for (final edge in graph.edges) {
      if (members.contains(edge.from) && members.contains(edge.to)) {
        out.writeln('  ${ids[edge.from]} -> ${ids[edge.to]};');
      }
    }
    out.writeln('}');
  }
  return out.toString();
}

/// Parses `dot -Tplain` output holding one or more graphs, converting inches
/// to points and flipping y so it grows downwards.
List<PlainLayout> parsePlain(String plain) {
  final layouts = <PlainLayout>[];
  double? width;
  double? height;
  var nodes = <String, NodeBox>{};
  for (final line in plain.split('\n')) {
    final t = line.trim().split(RegExp(r'\s+'));
    switch (t.first) {
      case 'graph':
        width = double.parse(t[2]) * pointsPerInch;
        height = double.parse(t[3]) * pointsPerInch;
        nodes = {};
      case 'node':
        final h = height!;
        nodes[t[1]] = NodeBox(
          double.parse(t[2]) * pointsPerInch,
          h - double.parse(t[3]) * pointsPerInch,
          double.parse(t[4]) * pointsPerInch,
          double.parse(t[5]) * pointsPerInch,
        );
      case 'stop':
        layouts.add(PlainLayout(width!, height!, nodes));
    }
  }
  return layouts;
}

/// `unflatten -l` stagger lengths tried in pass 1 besides the plain layout:
/// they spread wide fans (many leaves on one rank) over several ranks.
const unflattenLengths = [2, 3, 5];

/// How far a component layout is from good: distance of its aspect ratio to
/// [aspectRatio] (log scale) plus how much area it grew over [plainArea].
double layoutScore(PlainLayout layout, double aspectRatio, double plainArea) {
  final area = layout.width * layout.height;
  if (area <= 0 || plainArea <= 0) return 0;
  return (math.log(layout.width / layout.height / aspectRatio)).abs() +
      math.log(area / plainArea);
}

/// Picks per component the best of several pass-1 [variants] (each a full
/// list of component layouts; the first is the plain one) by [layoutScore].
List<PlainLayout> chooseLayouts(
    List<List<PlainLayout>> variants, double aspectRatio) {
  final plain = variants.first;
  return [
    for (var c = 0; c < plain.length; c++)
      variants.map((v) => v[c]).reduce((best, next) {
        final plainArea = plain[c].width * plain[c].height;
        return layoutScore(next, aspectRatio, plainArea) <
                layoutScore(best, aspectRatio, plainArea) - 1e-9
            ? next
            : best;
      })
  ];
}

double _titleWidth(String title) =>
    title.length * packageTitleFontSize * averageGlyphWidth + 24;

/// Places components inside their packages and the packages on the grid.
DiagramLayout placeDiagram(
  DiagramGraph graph,
  List<LayoutComponent> components,
  List<PlainLayout> plains,
  UmlConfig config,
) {
  if (plains.length != components.length) {
    throw StateError('dot returned ${plains.length} layouts for '
        '${components.length} components');
  }
  final aspect = config.gridAspectRatio ?? 1.0;
  final mode = GridMode.parse(config.gridMode);

  // inside each package: components on a grid of their own
  final blockSizes = <BlockSize>[];
  final inner = <List<(int, BlockOffset)>>[];
  for (var p = 0; p < graph.packages.length; p++) {
    final indices = [
      for (var c = 0; c < components.length; c++)
        if (components[c].packageIndex == p) c
    ];
    final placement = placeWithAspectRatio(
      [for (final c in indices) BlockSize(plains[c].width, plains[c].height)],
      aspectRatio: aspect,
      gap: componentGap,
    );
    final name = graph.packages[p].name;
    final pad = name == null ? 0.0 : packagePadding;
    final title = name == null ? 0.0 : packageTitleHeight;
    final contentWidth = name == null
        ? placement.width
        : math.max(placement.width, _titleWidth(name));
    blockSizes.add(
        BlockSize(contentWidth + 2 * pad, placement.height + title + 2 * pad));
    inner.add([
      for (var i = 0; i < indices.length; i++)
        (
          indices[i],
          BlockOffset(placement.offsets[i].x + pad,
              placement.offsets[i].y + title + pad)
        )
    ]);
  }

  final grid = placeOnGrid(
    blockSizes,
    columns: config.gridColumns,
    aspectRatio: aspect,
    gap: config.gridGap.toDouble(),
    mode: mode,
  );

  final nodes = <String, NodeBox>{};
  final boxes = <PackageBox?>[];
  for (var p = 0; p < graph.packages.length; p++) {
    final origin = grid.offsets[p];
    final ox = origin.x + diagramMargin;
    final oy = origin.y + diagramMargin;
    boxes.add(graph.packages[p].name == null
        ? null
        : PackageBox(ox, oy, blockSizes[p].width, blockSizes[p].height));
    for (final (c, offset) in inner[p]) {
      for (final entry in plains[c].nodes.entries) {
        final n = entry.value;
        nodes[entry.key] = NodeBox(
            n.cx + ox + offset.x, n.cy + oy + offset.y, n.width, n.height);
      }
    }
  }
  return DiagramLayout(
    width: grid.width + 2 * diagramMargin,
    height: grid.height + 2 * diagramMargin,
    nodes: nodes,
    packageBoxes: boxes,
    columns: grid.columns,
  );
}

String _endLabel(String text, String color) =>
    '<<FONT POINT-SIZE="18" COLOR="$color"><B>${escapeHtml(text)}</B></FONT>>';

/// The DOT attributes of one edge.
String edgeAttributes(DiagramEdge edge, UmlConfig config) =>
    switch (edge.kind) {
      EdgeKind.relation => '[color="${edge.color}", penwidth=3, '
          'arrowsize=1.2, ${edge.reversed ? 'dir=back, ' : ''}'
          'taillabel=${_endLabel(config.oneString, config.oneHexColor)}, '
          'headlabel=${_endLabel(config.manyString, config.manyHexColor)}, '
          'labeldistance=2, labelangle=30]',
      EdgeKind.fieldType => '[color="${edge.color}", penwidth=1.5, '
          'arrowhead=none]',
      EdgeKind.inheritance => '[color="${edge.color}", penwidth=1.5, '
          'arrowhead=empty, arrowsize=1.6]',
    };

/// Pass 2: every node pinned at its final position, packages as clusters
/// with explicit boxes, for `neato -n2` to route the edges.
String pass2Dot(
  DiagramGraph graph,
  DiagramLayout layout,
  Map<String, String> ids,
  UmlConfig config,
) {
  if (!const {'true', 'curved', 'spline', 'polyline', 'line'}
      .contains(config.splines)) {
    throw ArgumentError.value(config.splines, 'layout.splines',
        'must be true, curved, spline, polyline or line');
  }
  final h = layout.height;
  final out = StringBuffer();
  out.writeln('digraph uml {');
  out.writeln('  graph [splines=${config.splines}, esep="+10", '
      'outputorder=edgesfirst, '
      'bgcolor="white", fontname="Helvetica", '
      'bb="0,0,${_num(layout.width)},${_num(h)}"];');
  out.writeln('  node [shape=plain, fontname="Helvetica"];');
  out.writeln('  edge [fontname="Helvetica"];');

  void writeNode(UmlObject object, String indent) {
    final id = ids[object.name!]!;
    final box = layout.nodes[id]!;
    out.writeln('$indent$id [pos="${_num(box.cx)},${_num(h - box.cy)}!", '
        'label=${cardLabel(object, config)}];');
  }

  for (var p = 0; p < graph.packages.length; p++) {
    final package = graph.packages[p];
    final box = layout.packageBoxes[p];
    if (box == null) {
      for (final object in package.objects) {
        writeNode(object, '  ');
      }
      continue;
    }
    final fill = package.nested
        ? config.secondLevelNamespaceBackgroundHexColor
        : config.rootNamespaceBackgroundHexColor;
    out.writeln('  subgraph cluster_$p {');
    out.writeln('    graph [bb="${_num(box.x)},${_num(h - box.y - box.height)},'
        '${_num(box.x + box.width)},${_num(h - box.y)}", '
        'label=<<B>${escapeHtml(package.name!)}</B>>, labelloc=t, '
        'labeljust=l, fontsize=${packageTitleFontSize.toInt()}, '
        'style="rounded,filled", fillcolor="$fill", '
        'color="${config.namespaceBorderHexColor}", penwidth=3, '
        'margin=${packagePadding.toInt()}];');
    for (final object in package.objects) {
      writeNode(object, '    ');
    }
    out.writeln('  }');
  }

  for (final edge in graph.edges) {
    // a field port needs a compass side on the card border: a bare port sits
    // inside the card, where the splines=true router cannot start an edge
    final fromBox = layout.nodes[ids[edge.from]]!;
    final toBox = layout.nodes[ids[edge.to]]!;
    final side = toBox.cx >= fromBox.cx ? 'e' : 'w';
    final from = edge.fromPort != null
        ? '${ids[edge.from]}:${edge.fromPort}:$side'
        : ids[edge.from];
    out.writeln('  $from -> ${ids[edge.to]} ${edgeAttributes(edge, config)};');
  }
  out.writeln('}');
  return out.toString();
}
