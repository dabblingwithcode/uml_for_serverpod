import 'dart:io';

import 'package:uml_for_serverpod/src/graphviz/graphviz_backend.dart';
import 'package:uml_for_serverpod/src/uml/colors.dart';
import 'package:uml_for_serverpod/src/uml/generate_uml_namespaces_with_objects.dart';
import 'package:uml_for_serverpod/src/uml/implicit_links.dart';
import 'package:uml_for_serverpod/src/uml/generate_uml_object.dart';
import 'package:uml_for_serverpod/src/uml/uml_object_helpers.dart';
import 'package:uml_for_serverpod/src/uml/uml_style_block.dart';
import 'package:uml_for_serverpod/src/yaml/spy_yaml_parser.dart';

import '../models.dart';

class UmlGenerator {
  final UmlConfig config;

  SpyYamlParser spyYamlParser;
  UmlGenerator({
    required this.config,
  }) : spyYamlParser = SpyYamlParser(config: config);

  /// Generates the diagram and returns the path(s) written.
  Future<String> generate() async {
    if (!const {'plantuml', 'dot'}.contains(config.outputFormat)) {
      throw ArgumentError.value(
          config.outputFormat, 'output.format', 'must be plantuml or dot');
    }
    // 1. Collect all .spy.yaml files and concatenate their content
    final yamlContent = await spyYamlParser.collectYamlContent();

    // 2. Parse YAML content to create UmlModel objects

    final serverpodObjectsMap =
        spyYamlParser.parseModels(yamlContent).serverpodObjectsMap;

    if (config.outputFormat == 'dot') {
      return generateGraphvizFiles(serverpodObjectsMap);
    }

    // 3. Generate UML PlantUML content
    final umlContent = generateUml(serverpodObjectsMap);

    // 4. Write UML content to output file
    final umlFile = File(config.umlOutputFile);

    await umlFile.writeAsString(umlContent);

    return config.umlOutputFile;
  }

  /// The Graphviz backend writes `<stem>.svg` and the pinned `<stem>.dot`,
  /// where the stem is the output path without its extension.
  Future<String> generateGraphvizFiles(
      Map<String, UmlObject> objectsMap) async {
    final stem =
        config.umlOutputFile.replaceFirst(RegExp(r'\.(puml|svg|dot)$'), '');
    final result = await renderGraphviz(objectsMap, config);
    await File('$stem.dot').writeAsString(result.dot);
    await File('$stem.svg').writeAsString(result.svg);
    stdout.writeln('📄 ✏️ Wrote ${objectsMap.length} objects in '
        '${result.graph.packages.length} package blocks '
        '(${result.layout.columns} columns), ${result.graph.edges.length} edges'
        '${result.graph.droppedEdges > 0 ? ', dropped ${result.graph.droppedEdges} relations to unknown models' : ''}');
    if (result.unroutedEdges.isNotEmpty) {
      stdout
          .writeln('⚠️ Graphviz could not route ${result.unroutedEdges.length} '
              'edge(s) around the cards and drew them directly: '
              '${result.unroutedEdges.join(', ')}');
    }
    return '$stem.svg (+ $stem.dot)';
  }

  String generateUml(Map<String, UmlObject> objectsMap) {
    final umlBuffer = StringBuffer();
    final Directory currentDir = Directory.current;
    final String projectPath = currentDir.path.split(RegExp(r'[/\\]')).last;
    List<ObjectRelation> relations = [];

    umlBuffer.writeln('@startuml $projectPath');

    // Add the UML style block
    umlBuffer.writeln(UmlStyleBlock.generateUmlStyleBlock(config));
    umlBuffer.writeln();

    if (config.useNameSpace) {
      final namespacesAndRelations = generateNameSpacesAndRelationsFromObjects(
          objectsMap.values.toList(), config);
      relations = namespacesAndRelations
          .relations; // Get the relations from the namespaces
      // Add the namespaces to the UML buffer
      umlBuffer.writeln(namespacesAndRelations.renderedNamespaces);
    } else {
      // Generate objects
      for (UmlObject object in objectsMap.values) {
        final generatedUmlObject = generateUmlObject(object, config);
        umlBuffer.writeln(generatedUmlObject);

        // Add the object to the list of relations
        for (final ObjectRelation relation in object.relations ?? []) {
          // If the other side of the relation is not in the list, add it
          if (!relations.any((r) =>
              r.objectName == relation.relatedObject &&
              r.relatedObject == relation.objectName)) {
            relations.add(relation);
          }
        }
      }
    }

    // Generate relationships

    final umlObjectRelationLines =
        UmlObjectHelpers.renderUmlObjectRelationLines(
      config,
      relations,
    );
    for (final line in umlObjectRelationLines) {
      umlBuffer.writeln(line);
    }
    umlBuffer.writeln();

    // Add implicit relationships
    var typeLinkIndex = 0;
    for (var entryA in objectsMap.entries) {
      final modelA = entryA.value;
      if (modelA.fields != null) {
        for (var entryB in objectsMap.entries) {
          final modelB = entryB.value;
          // skip self-references
          if (modelA.name! == modelB.name!) {
            continue;
          }
          final link = implicitLinkKind(modelA.fields!, modelB.name!);
          if (link == null) continue;
          final style = config.colorfullTypeLinks
              ? '[${colorPalette[typeLinkIndex++ % colorPalette.length]}]'
              : '';
          umlBuffer.writeln(switch (link) {
            ImplicitLink.inheritance =>
              '${modelB.name!} <|-$style- ${modelA.name!}',
            ImplicitLink.fieldType => '${modelA.name!} -$style ${modelB.name!}',
          });
        }
      }
    }

    umlBuffer.writeln('@enduml');
    stdout.writeln(
        '📄 ✏️ Wrote ${objectsMap.length} objects and ${relations.length} relations');
    return umlBuffer.toString();
  }
}
