import 'dart:io';

import 'package:test/test.dart';
import 'package:uml_for_serverpod/src/graphviz/diagram_graph.dart';
import 'package:uml_for_serverpod/src/graphviz/dot_emitter.dart';
import 'package:uml_for_serverpod/src/graphviz/graphviz_backend.dart';
import 'package:uml_for_serverpod/src/graphviz/grid_layout.dart';
import 'package:uml_for_serverpod/src/graphviz/html_label.dart';
import 'package:uml_for_serverpod/src/models.dart';
import 'package:uml_for_serverpod/src/yaml/spy_yaml_parser.dart';
import 'package:uml_for_serverpod/src/yaml/yaml_config_decoder.dart';

const fixture = '''
filepath: /people/person.spy.yaml
class: Person
table: person
fields:
  ## The full name of the person as it is printed on every official letter
  name: String
  company: Company?, relation(name=company_employees)
  status: PersonStatus

filepath: /people/person_status.spy.yaml
enum: PersonStatus
serialized: byName
values:
  - active
  - retired

filepath: /firms/company.spy.yaml
class: Company
table: company
fields:
  extends: BaseEntity
  employees: List<Person>?, relation(name=company_employees)

filepath: /firms/base_entity.spy.yaml
class: BaseEntity
fields:
  createdAt: DateTime
''';

Map<String, UmlObject> fixtureObjects(UmlConfig config) =>
    SpyYamlParser(config: config).parseModels(fixture).serverpodObjectsMap;

bool overlaps(BlockOffset a, BlockSize as, BlockOffset b, BlockSize bs) =>
    a.x < b.x + bs.width &&
    b.x < a.x + as.width &&
    a.y < b.y + bs.height &&
    b.y < a.y + as.height;

void expectNoOverlaps(List<BlockSize> sizes, GridPlacement placement) {
  for (var i = 0; i < sizes.length; i++) {
    for (var j = i + 1; j < sizes.length; j++) {
      expect(
          overlaps(
              placement.offsets[i], sizes[i], placement.offsets[j], sizes[j]),
          isFalse,
          reason: 'blocks $i and $j overlap');
    }
  }
}

/// A Graphviz bin directory holding dot, or null when Graphviz is absent.
String? graphvizBinDir() {
  final which = Process.runSync('which', ['dot']);
  if (which.exitCode == 0) {
    return File(which.stdout.toString().trim()).parent.path;
  }
  for (final dir in ['/opt/homebrew/bin', '/usr/local/bin', '/usr/bin']) {
    if (File('$dir/dot').existsSync()) return dir;
  }
  return null;
}

void main() {
  group('grid placement', () {
    const sizes = [
      BlockSize(100, 50),
      BlockSize(40, 80),
      BlockSize(60, 60),
      BlockSize(120, 30),
      BlockSize(50, 50),
    ];

    test('places row-major with explicit columns and gaps', () {
      final p = placeWithColumns(sizes, columns: 2, gap: 10);
      expect(p.columns, 2);
      expect(p.offsets.map((o) => (o.x, o.y)).toList(), [
        (0.0, 0.0), (110.0, 0.0), // row 0 is 80 tall
        (0.0, 90.0), (70.0, 90.0), // row 1 is 60 tall
        (0.0, 160.0),
      ]);
      expect(p.width, 190); // 60 + 10 + 120
      expect(p.height, 210); // 80 + 10 + 60 + 10 + 50
      expectNoOverlaps(sizes, p);
    });

    test('cells mode aligns columns to their widest block', () {
      final p =
          placeWithColumns(sizes, columns: 2, gap: 10, mode: GridMode.cells);
      // column 0 holds blocks 0, 2, 4 and is 100 wide; rows mode puts
      // block 3 at 70 (after the 60-wide block 2)
      expect(p.offsets[1].x, 110);
      expect(p.offsets[3].x, 110);
      expectNoOverlaps(sizes, p);
    });

    test('columns beyond the block count collapse to one row', () {
      final p = placeWithColumns(sizes, columns: 9, gap: 5);
      expect(p.columns, 5);
      expect(p.offsets.every((o) => o.y == 0), isTrue);
      expectNoOverlaps(sizes, p);
    });

    test('aspect ratio chooses the column count', () {
      final squares = List.filled(16, const BlockSize(100, 100));
      expect(placeWithAspectRatio(squares, aspectRatio: 1, gap: 0).columns, 4);
      expect(placeWithAspectRatio(squares, aspectRatio: 4, gap: 0).columns, 8);
      final portrait = placeWithAspectRatio(squares, aspectRatio: 0.6, gap: 0);
      expect(portrait.columns, 3);
      expect(portrait.aspectRatio, lessThan(1));
      expectNoOverlaps(squares, portrait);
    });

    test('explicit columns win over the aspect ratio', () {
      final p = placeOnGrid(sizes, columns: 1, aspectRatio: 10, gap: 0);
      expect(p.columns, 1);
    });

    test('empty input and bad arguments', () {
      expect(placeWithColumns([], columns: 3, gap: 1).offsets, isEmpty);
      expect(() => placeWithColumns(sizes, columns: 0, gap: 1),
          throwsArgumentError);
      expect(() => placeWithAspectRatio(sizes, aspectRatio: 0, gap: 1),
          throwsArgumentError);
      expect(() => GridMode.parse('spiral'), throwsArgumentError);
    });
  });

  group('wrapping', () {
    test('wraps words and keeps styles across lines', () {
      final lines = wrapRuns([
        const Run('name', italic: true),
        const Run(': '),
        const Run('Map<String, List<SomethingQuiteLong>>', bold: true),
      ], 16);
      for (final line in lines) {
        expect(line.map((r) => r.text).join().length, lessThanOrEqualTo(16));
      }
      expect(lines.length, greaterThan(1));
      expect(lines.first.first.italic, isTrue);
      expect(lines.skip(1).expand((l) => l).every((r) => r.bold), isTrue);
    });

    test('breaks a token longer than a line', () {
      final lines = wrapRuns([const Run('abcdefghijklmnopqrstuvwxyz')], 10);
      expect(lines.map((l) => l.single.text).toList(),
          ['abcdefghij', 'klmnopqrst', 'uvwxyz']);
    });

    test('escapes label text', () {
      expect(renderWrapped([const Run('List<A> & B')], 100),
          'List&lt;A&gt; &amp; B');
    });
  });

  group('DOT emission', () {
    final config = UmlConfig(classMaxWidth: 200, colorfullTypeLinks: true);
    final graph = DiagramGraph.build(fixtureObjects(config), config);
    final ids = nodeIds(graph);
    final components = layoutComponents(graph);
    // fake pass-1 output: every component a single 100×60 row of nodes
    final plains = [
      for (final c in components)
        PlainLayout(c.names.length * 120.0, 60, {
          for (var i = 0; i < c.names.length; i++)
            ids[c.names[i]]!: NodeBox(60 + i * 120.0, 30, 100, 60)
        })
    ];
    final layout = placeDiagram(graph, components, plains, config);
    final dot = pass2Dot(graph, layout, ids, config);

    test('groups packages by folder, sorted, objects sorted', () {
      expect(graph.packages.map((p) => p.name), ['firms', 'people']);
      expect(graph.packages.first.objects.map((o) => o.name),
          ['BaseEntity', 'Company']);
    });

    test('package order from config comes first', () {
      final ordered = DiagramGraph.build(
          fixtureObjects(config), config.copyWith(gridOrder: ['people']));
      expect(ordered.packages.map((p) => p.name), ['people', 'firms']);
    });

    test('emits clusters with title, colours and explicit boxes', () {
      expect(RegExp('subgraph cluster_').allMatches(dot).length, 2);
      expect(dot, contains('label=<<B>firms</B>>'));
      expect(dot,
          contains('fillcolor="${config.rootNamespaceBackgroundHexColor}"'));
      expect(dot, contains('style="rounded,filled"'));
      expect(RegExp(r'bb="[\d.]+,[\d.]+,[\d.]+,[\d.]+"').allMatches(dot).length,
          3); // graph + two clusters
    });

    test('pins every node', () {
      expect(RegExp(r'pos="[\d.]+,[\d.]+!"').allMatches(dot).length, 4);
    });

    test('draws relations, inheritance and type links', () {
      final company = ids['Company']!;
      final person = ids['Person']!;
      final relation = RegExp('$company:f_employees:[ew] -> $person \\[[^\\n]*')
          .firstMatch(dot)
          ?.group(0);
      expect(relation, isNotNull);
      expect(relation, contains('penwidth=3'));
      expect(relation, contains('dir=back')); // list side carries the arrow
      expect(relation, contains('COLOR="${config.oneHexColor}"><B>1</B>'));
      expect(relation, contains('COLOR="${config.manyHexColor}"><B>N</B>'));
      // the reverse relation (Person.company) is the same edge, drawn once
      expect(RegExp('$person:f_company').hasMatch(dot), isFalse);

      expect(
          dot,
          matches(RegExp('$company -> ${ids['BaseEntity']} '
              r'\[color="#[0-9A-F]{6}", penwidth=1.5, arrowhead=empty')));
      expect(
          dot,
          matches(RegExp('$person -> ${ids['PersonStatus']} '
              r'\[color="#[0-9A-F]{6}", penwidth=1.5, arrowhead=none')));
    });

    test('renders cards with header colours, comments and wrapping', () {
      expect(dot, contains('BGCOLOR="#e2f0fb"')); // table header
      expect(dot, contains('BGCOLOR="#ece4ff"')); // enum header
      expect(dot, contains('«table: <B>person</B>»'));
      expect(dot, contains('COLOR="${config.commentHexColor}"'));
      expect(dot, contains('PORT="f_company"'));
      // the long comment wraps at maxWidth 200 (27 chars at 12 pt)
      final comment = RegExp('COLOR="${config.commentHexColor}">([^<]*)<')
          .allMatches(dot)
          .map((m) => m.group(1)!)
          .toList();
      expect(comment.length, greaterThan(1));
      expect(comment.every((c) => c.length <= charsForWidth(200)), isTrue);
      expect(dot, contains('<BR ALIGN="LEFT"/>'));
    });

    test('rejects an unknown splines value', () {
      expect(
          () =>
              pass2Dot(graph, layout, ids, config.copyWith(splines: 'wiggly')),
          throwsArgumentError);
    });

    test('pass 1 holds one digraph per component with its inner edges', () {
      final pass1 = pass1Dot(graph, components, ids, config);
      expect(
          RegExp(r'^digraph c\d+ \{', multiLine: true).allMatches(pass1).length,
          components.length);
      expect(pass1, contains('rankdir=LR'));
      expect(pass1, contains('${ids['Company']} -> ${ids['BaseEntity']};'));
    });
  });

  group('pass 1 parsing and choice', () {
    test('parses several plain graphs, in points, y down', () {
      final layouts = parsePlain('''
graph 1 2 1
node n0 0.5 0.75 1 0.5 x solid plain black lightgrey
stop
graph 1 1 1
node n1 0.5 0.5 1 1 y solid plain black lightgrey
stop
''');
      expect(layouts.length, 2);
      expect(layouts[0].width, 144);
      final n0 = layouts[0].nodes['n0']!;
      expect(n0.cx, 36);
      expect(n0.cy, 18); // 72 - 54
      expect(n0.width, 72);
      expect(layouts[1].nodes.keys, ['n1']);
    });

    test('keeps the plain layout unless a variant is clearly better', () {
      const plain = [
        PlainLayout(700, 900, {}), // fine already
        PlainLayout(750, 5500, {}), // a tall fan
      ];
      const unflattened = [
        PlainLayout(1400, 600, {}),
        PlainLayout(3800, 3700, {}),
      ];
      final chosen = chooseLayouts([plain, unflattened], 1.0);
      expect(chosen[0], same(plain[0]));
      expect(chosen[1], same(unflattened[1]));
    });
  });

  group('SVG sanitising', () {
    test('strips prolog, doctype, comments and xlink', () {
      final svg = sanitizeSvg('''<?xml version="1.0"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/x.dtd">
<!-- Generated -->
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g><text>href=x onload=y</text></g></svg>''');
      expect(svg, startsWith('<svg'));
      expect(svg, isNot(contains('xlink')));
      expect(svg, isNot(contains('<!')));
    });

    test('refuses links, scripts, foreign objects and active attributes', () {
      for (final bad in [
        '<svg><a><text>x</text></a></svg>',
        '<svg><script>alert(1)</script></svg>',
        '<svg><foreignObject/></svg>',
        '<svg><g onclick="x"/></svg>',
        '<svg><path fill="url(#p)"/></svg>',
        '<svg><image href="http://x"/></svg>',
      ]) {
        expect(() => sanitizeSvg(bad), throwsStateError, reason: bad);
      }
    });
  });

  group('configuration', () {
    test('reads output and grid options', () async {
      final dir = await Directory.systemTemp.createTemp('uml_cfg');
      final file = File('${dir.path}/uml_config.yaml')..writeAsStringSync('''
output:
  format: dot
  graphvizBinDir: /opt/homebrew/bin
layout:
  splines: curved
  grid:
    columns: 4
    aspectRatio: 0.6
    gap: 80
    mode: cells
    order: [people, firms]
''');
      final config = await UmlConfigParser.getYamlConfigFromFile(file);
      await dir.delete(recursive: true);
      expect(config.outputFormat, 'dot');
      expect(config.graphvizBinDir, '/opt/homebrew/bin');
      expect(config.splines, 'curved');
      expect(config.gridColumns, 4);
      expect(config.gridAspectRatio, 0.6);
      expect(config.gridGap, 80);
      expect(config.gridMode, 'cells');
      expect(config.gridOrder, ['people', 'firms']);
    });

    test('defaults keep PlantUML output', () {
      final config = UmlConfig();
      expect(config.outputFormat, 'plantuml');
      expect(config.splines, 'true');
      expect(config.gridColumns, isNull);
    });
  });

  group('Graphviz rendering', () {
    test('fails clearly when the binaries are missing', () async {
      const runner = GraphvizRunner(binDir: '/nonexistent/graphviz');
      await expectLater(
        runner.run('dot', ['-V'], ''),
        throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('/nonexistent/graphviz/dot'),
                contains('graphvizBinDir')))),
      );
    });

    final binDir = graphvizBinDir();
    test('renders a fixture to an inert SVG', () async {
      final config = UmlConfig(
          classMaxWidth: 250, colorfullTypeLinks: true, graphvizBinDir: binDir);
      final result = await renderGraphviz(fixtureObjects(config), config);
      final svg = result.svg;
      expect(svg, startsWith('<svg'));
      final elements = RegExp(r'<\s*([A-Za-z][\w:.-]*)')
          .allMatches(svg)
          .map((m) => m.group(1)!)
          .toSet();
      expect(allowedSvgElements.containsAll(elements), isTrue,
          reason:
              'unexpected elements: ${elements.difference(allowedSvgElements)}');
      expect(svg, isNot(contains('href')));
      expect(svg, isNot(contains('<!')));
      expect(svgViolations(svg), isEmpty);
      // two package boxes and one path per edge
      expect(RegExp('class="cluster"').allMatches(svg).length, 2);
      expect(RegExp('class="edge"').allMatches(svg).length,
          result.graph.edges.length);
      expect(svg, contains('Person'));
    }, skip: binDir == null ? 'Graphviz (dot) is not installed' : false);
  });
}
