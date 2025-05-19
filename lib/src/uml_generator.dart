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
    final parsedData = spyYamlParser.parseModels(yamlContent);

    final serverpodObjectsMap = parsedData.serverpodObjects;

    final relations = parsedData.relations;

    // 3. Generate UML PlantUML content
    final umlContent = generateUml(serverpodObjectsMap, relations);

    // 4. Write UML content to output file
    final umlFile = File(config.umlOutputFile!);

    await umlFile.writeAsString(umlContent);

    return;
  }

  String generateUml(
      Map<String, UmlObject> objectsMap, List<String> relations) {
    final umlBuffer = StringBuffer();
    // Add the UML style block
    umlBuffer.writeln('@startuml');
    umlBuffer.writeln(UmlStyleBlock.generateUmlStyleBlock(config));

    // Generate objects

    for (UmlObject object in objectsMap.values) {
      final objectType = object.objectType;
      final filepath = object.filepath!;

      // declare the object type and name
      final objectDeclaration =
          UmlHelpers.getObjectDeclaration(object, config.useNameSpace);
      umlBuffer.writeln(objectDeclaration);

      // Add the filepath
      umlBuffer.writeln('<size:14>📁</size> <b><size:12> $filepath</size></b>');
      // Add a separator
      umlBuffer.writeln('--');

      switch (objectType) {
        case ObjectType.classType:
        case ObjectType.databaseClassType:
        case ObjectType.exceptionType:
          if (object.fields != null) {
            object.fields!.forEach((k, v) {
              String fieldsLine = '';
              if (v.contains('relation')) {
                fieldsLine =
                    ' ➡️ <i>$k</i> : <b><color:${config.classNameHexColor}>${v.split(',')[0]}</color></b> ${v.split(',')[1].replaceFirst('relation', '<b><color:${config.relationHexColor}>relation</color></b>')} ';
              } else if (k.contains('##') & config.printComments) {
                fieldsLine = '<color:${config.commentHexColor}>$k</color>';
              } else if (k.contains('##') & !config.printComments) {
                return;
              } else if (k.contains('indexes:')) {
                umlBuffer.writeln('--');
                fieldsLine =
                    '<b><color:${config.relationHexColor}>$k</color></b>';
              } else if (k.contains('idx:')) {
                fieldsLine =
                    '<b><color:${config.relationHexColor}>$k</color></b>';
              } else if (k.contains('unique')) {
                fieldsLine =
                    '<b><color:${config.relationHexColor}>$k</color></b>: <b><color:${config.classNameHexColor}>$v</color></b>';
              } else {
                fieldsLine =
                    '  <i>$k</i>: <b><color:${config.classNameHexColor}>$v</color></b>';
              }
              umlBuffer.writeln(fieldsLine);
            });
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
    }

    umlBuffer.writeln();

    // Generate relationships

    for (var rel in relations) {
      // TODO: Why is this needed?
      var fixedRel = rel.replaceAllMapped(
        RegExp(r'List<([A-Za-z0-9_]+)>'),
        (m) => m.group(1) as String,
      );

      umlBuffer.writeln(fixedRel);
    }

    // Add implicit relationships
    for (var entryA in objectsMap.entries) {
      final modelA = entryA.value;
      if (modelA.fields != null) {
        for (var entryB in objectsMap.entries) {
          final modelB = entryB.value;
          if (modelA.name!.split('.').last == modelB.name!.split('.').last) {
            continue;
          }
          // skip self
          final found = modelA.fields!.entries.any((field) {
            final fieldValue = field.value;
            return !fieldValue.contains('relation') &&
                (fieldValue == modelB.name!.split('.').last ||
                    fieldValue.contains('${modelB.name!.split('.').last}?') ||
                    fieldValue
                        .contains('List<${modelB.name!.split('.').last}>'));
          });
          if (found) {
            umlBuffer.writeln(
                '${modelA.name!.split('.').last} -- ${modelB.name!.split('.').last}');
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
