import 'package:uml_for_serverpod/src/graphviz/html_label.dart';
import 'package:uml_for_serverpod/src/models.dart';
import 'package:uml_for_serverpod/src/uml/colors.dart';
import 'package:uml_for_serverpod/src/uml/implicit_links.dart';

/// What an edge draws.
enum EdgeKind { relation, fieldType, inheritance }

/// One edge between two objects of the diagram.
class DiagramEdge {
  final EdgeKind kind;
  final String from;
  final String to;

  /// Field row of [from] a relation starts at.
  final String? fromPort;
  final String color;

  /// Arrow head at [from] instead of [to] (a list-side relation).
  final bool reversed;

  const DiagramEdge({
    required this.kind,
    required this.from,
    required this.to,
    required this.color,
    this.fromPort,
    this.reversed = false,
  });
}

/// A package (folder) of objects; [name] null holds objects outside packages.
class DiagramPackage {
  final String? name;
  final bool nested;
  final List<UmlObject> objects;
  DiagramPackage(this.name, {this.nested = false, required this.objects});
}

/// Objects grouped into packages, plus every edge between known objects.
class DiagramGraph {
  final List<DiagramPackage> packages;
  final List<DiagramEdge> edges;

  /// Relations whose target is not a model of the diagram (dropped).
  final int droppedEdges;

  DiagramGraph(this.packages, this.edges, {this.droppedEdges = 0});

  /// Builds the graph with the same grouping and edges as the PlantUML output.
  ///
  /// Packages are keyed by the object's folder (as PlantUML packages are);
  /// nested folders become flat packages. Packages are ordered by
  /// [UmlConfig.gridOrder] first, then by name; objects by name.
  factory DiagramGraph.build(
      Map<String, UmlObject> objectsMap, UmlConfig config) {
    final byName = <String, DiagramPackage>{};
    final loose = <UmlObject>[];
    for (final object in objectsMap.values) {
      final parts = object.filepath!.replaceFirst(RegExp('^/'), '').split('/');
      final folder = parts.length >= 2 ? parts[parts.length - 2] : null;
      if (!config.useNameSpace ||
          folder == null ||
          folder == config.ignoreRootFolder) {
        loose.add(object);
        continue;
      }
      final parent = parts.length >= 3 ? parts[parts.length - 3] : null;
      byName
          .putIfAbsent(
              folder,
              () => DiagramPackage(folder,
                  nested: parent != null && parent != config.ignoreRootFolder,
                  objects: []))
          .objects
          .add(object);
    }
    int rank(String name) {
      final i = config.gridOrder.indexOf(name);
      return i < 0 ? config.gridOrder.length : i;
    }

    final packages = byName.values.toList()
      ..sort((a, b) {
        final byRank = rank(a.name!).compareTo(rank(b.name!));
        return byRank != 0 ? byRank : a.name!.compareTo(b.name!);
      });
    if (loose.isNotEmpty) packages.add(DiagramPackage(null, objects: loose));
    for (final package in packages) {
      package.objects.sort((a, b) => a.name!.compareTo(b.name!));
    }

    final ordered = [for (final p in packages) ...p.objects];
    final known = {for (final o in ordered) o.name!};
    final edges = <DiagramEdge>[];
    var dropped = 0;

    // relations, deduplicated as in the PlantUML output
    final relations = <ObjectRelation>[];
    for (final object in ordered) {
      for (final relation in object.relations ?? const <ObjectRelation>[]) {
        if (!relations.any((r) =>
            r.objectName == relation.relatedObject &&
            r.relatedObject == relation.objectName)) {
          relations.add(relation);
        }
      }
    }
    var relationIndex = 0;
    for (final relation in relations) {
      if (!known.contains(relation.relatedObject)) {
        dropped++;
        continue;
      }
      final color = config.colorfullArrows
          ? colorPalette[relationIndex++ % colorPalette.length]
          : '#333333';
      edges.add(DiagramEdge(
        kind: EdgeKind.relation,
        from: relation.objectName!,
        fromPort: fieldPort(relation.fieldName!),
        to: relation.relatedObject!,
        color: color,
        reversed: relation.type == RelationType.one,
      ));
    }

    // implicit field-type and inheritance links
    var linkIndex = 0;
    for (final a in ordered) {
      if (a.fields == null) continue;
      for (final b in ordered) {
        if (a.name == b.name) continue;
        final link = implicitLinkKind(a.fields!, b.name!);
        if (link == null) continue;
        final color = config.colorfullTypeLinks
            ? colorPalette[linkIndex++ % colorPalette.length]
            : '#555555';
        edges.add(switch (link) {
          ImplicitLink.inheritance => DiagramEdge(
              kind: EdgeKind.inheritance,
              from: a.name!,
              to: b.name!,
              color: color),
          ImplicitLink.fieldType => DiagramEdge(
              kind: EdgeKind.fieldType,
              from: a.name!,
              to: b.name!,
              color: color),
        });
      }
    }
    return DiagramGraph(packages, edges, droppedEdges: dropped);
  }
}
