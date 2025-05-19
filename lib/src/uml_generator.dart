import 'dart:io';

import 'package:uml_for_serverpod/src/spy_yaml_parser.dart';
import 'package:uml_for_serverpod/src/uml_helpers.dart';
import 'package:uml_for_serverpod/src/uml_style_block.dart';

import 'models.dart';

class UmlGenerator {
  final UmlConfig config;

  late Directory modelsDir;

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
    final umlFile = File(config.umlOutputFile!);

    await umlFile.writeAsString(umlContent);

    return;
  }

  String generateUml(Map<String, UmlObject> objectsMap) {
    final umlBuffer = StringBuffer();
    // Add the UML style block
    umlBuffer.writeln('@startuml');
    umlBuffer.writeln(UmlStyleBlock.generateUmlStyleBlock(config));

    List<ObjectRelation> relations = [];
    // Generate objects

    for (UmlObject object in objectsMap.values) {
      final objectType = object.objectType;
      final filepath = object.filepath!;

      // declare the object type and name
      final objectDeclaration = UmlHelpers.getObjectDeclaration(object, config);
      umlBuffer.writeln(objectDeclaration);

      // Add the filepath
      umlBuffer.writeln('<size:14>📁</size> <b><size:12> $filepath</size></b>');
      // Add a separator
      umlBuffer.writeln('--');

      // Add fields
      switch (objectType) {
        case ObjectType.classType:
        case ObjectType.databaseClassType:
        case ObjectType.exceptionType:
          if (object.fields != null) {
            for (var entry in object.fields!.entries) {
              final key = entry.key;
              final value = entry.value;
              final fieldLine = UmlHelpers.formatFieldLine(key, value, config);
              if (fieldLine != null) {
                umlBuffer.writeln(fieldLine);
              }
            }
          }

          umlBuffer.writeln('}');

          break;

        case ObjectType.enumType:
          if (object.enumSerialized != null) {
            umlBuffer.writeln('  serialized: ${object.enumSerialized}');
          }
          if (object.enumValues != null) {
            umlBuffer.writeln('  values: ${object.enumValues}');
          }
          umlBuffer.writeln('}');
          break;

        case null:
          throw Exception('Object type is null for object: ${object.name}');
      }
      // Add relations

      for (final ObjectRelation relation in object.relations ?? []) {
        // If the other side of the relation is not in the list, add it
        if (!relations.any((r) =>
            r.objectName == relation.relatedObject &&
            r.relatedObject == relation.objectName)) {
          relations.add(relation);
        }
      }
    }

    // Generate relationships

    final umlObjectRelationLines = UmlHelpers.getUmlObjectRelationLines(
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
            umlBuffer.writeln('${modelA.name!} -- ${modelB.name!}');
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
