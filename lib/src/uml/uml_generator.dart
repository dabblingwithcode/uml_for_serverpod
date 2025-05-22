import 'dart:io';

import 'package:uml_for_serverpod/src/uml/generate_uml_namespaces_with_objects.dart';
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

  Future<void> generate() async {
    // 1. Collect all .spy.yaml files and concatenate their content
    final yamlContent = await spyYamlParser.collectYamlContent();

    // 2. Parse YAML content to create UmlModel objects

    final serverpodObjectsMap =
        spyYamlParser.parseModels(yamlContent).serverpodObjectsMap;

    // 3. Generate UML PlantUML content
    final umlContent = generateUml(serverpodObjectsMap);

    // 4. Write UML content to output file
    final umlFile = File(config.umlOutputFile);

    await umlFile.writeAsString(umlContent);

    return;
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
    for (var entryA in objectsMap.entries) {
      final modelA = entryA.value;
      if (modelA.fields != null) {
        for (var entryB in objectsMap.entries) {
          final modelB = entryB.value;
          // skip self-references
          if (modelA.name! == modelB.name!) {
            continue;
          }

          final found = modelA.fields!.entries.any((field) {
            final fieldValue = field.value;
            return !fieldValue.contains('relation') &&
                (fieldValue == modelB.name! ||
                    fieldValue.contains(modelB.name!) ||
                    fieldValue.contains('List<${modelB.name!}>'));
          });
          if (found) {
            umlBuffer.writeln('${modelA.name!} - ${modelB.name!}');
          }
        }
      }
    }

    umlBuffer.writeln('@enduml');
    stdout.writeln(
        '📄 ✏️ Wrote ${objectsMap.length} objects and ${relations.length} relations');
    return umlBuffer.toString();
  }
}
