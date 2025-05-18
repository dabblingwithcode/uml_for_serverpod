import 'dart:io';

import 'package:uml_for_serverpod/src/yaml_parser.dart';

import 'models.dart';

class UmlGenerator {
  final UmlConfig config;
  final String modelsDirPath;
  late Directory modelsDir;
  final File yamlOutputFile;
  final File umlOutputFile;

  YamlParser yamlParser;
  UmlGenerator({
    required this.config,
    required this.modelsDirPath,
    required this.yamlOutputFile,
    required this.umlOutputFile,
  }) : yamlParser = YamlParser(config: config, modelsDirPath: modelsDirPath);

  Future<void> generate() async {
    // 1. Collect all .spy.yaml files and concatenate their content
    final yamlContent = await yamlParser.collectYamlContent();
    await yamlOutputFile.writeAsString(yamlContent);

    // 2. Parse YAML content to create UmlModel objects
    final parsedData = yamlParser.parseYamlContent(yamlContent);
    final classes = parsedData['classes'] as Map<String, UmlModel>;
    final relations = parsedData['relations'] as List<String>;

    // 3. Generate UML PlantUML content
    final umlContent = generateUml(classes, relations);
    await umlOutputFile.writeAsString(umlContent);
  }

  String generateUml(Map<String, UmlModel> classes, List<String> relations) {
    final umlBuffer = StringBuffer();
    umlBuffer.writeln('''@startuml
    ' Layout control
    left to right direction
    skinparam ranksep 100
    skinparam nodesep 80
    skinparam attributeFontSize 14
    <style>
    classDiagram {
        RoundCorner 15
        FontSize 13
        FontStyle Regular
    
        class {
          FontSize 12
              header {
                FontSize 36
                FontStyle bold
              }
        }
    }
    </style>
        ''');

    // Generate classes/entities
    for (UmlModel model in classes.values) {
      final className = model.name;
      final filepath = model.filepath!;
      final isEnum = model.isEnum;
      final isDatabaseObject = model.tableName != null;

      if (isEnum == true) {
        umlBuffer.writeln('enum $className {');
        umlBuffer
            .writeln('<size:14>📁</size> <b><size:12> $filepath</size></b>');
        umlBuffer.writeln('--');

        if (model.enumSerialized != null) {
          umlBuffer.writeln('  serialized: ${model.enumSerialized}');
        }
        if (model.enumValues != null) {
          umlBuffer.writeln('  values: ${model.enumValues}');
        }
        umlBuffer.writeln('}');
      } else {
        final umlTypeLine = isDatabaseObject
            ? 'entity $className <<${model.tableName}>> ##[bold]black{'
            : 'class $className ##[bold]black {';
        umlBuffer.writeln(umlTypeLine);

        if (filepath.isNotEmpty) {
          umlBuffer
              .writeln('<size:14>📁</size> <b><size:12> $filepath</size></b>');
          umlBuffer.writeln('--');
        }

        if (model.fields != null) {
          model.fields!.forEach((k, v) {
            String fieldsLine = '';
            if (v.contains('relation')) {
              fieldsLine =
                  ' ➡️ <i>$k</i> : <b><color:${config.classHexColor}>${v.split(',')[0]}</color></b> ${v.split(',')[1].replaceFirst('relation', '<b><color:${config.relationHexColor}>relation</color></b>')} ';
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
                  '<b><color:${config.relationHexColor}>$k</color></b>: <b><color:${config.classHexColor}>$v</color></b>';
            } else {
              fieldsLine =
                  '  <i>$k</i>: <b><color:${config.classHexColor}>$v</color></b>';
            }
            umlBuffer.writeln(fieldsLine);
          });
        }
        umlBuffer.writeln('}');
      }
    }

    umlBuffer.writeln();

    // Generate relationships
    for (var rel in relations) {
      var fixedRel = rel.replaceAllMapped(
        RegExp(r'List<([A-Za-z0-9_]+)>'),
        (m) => m.group(1) as String,
      );
      umlBuffer.writeln(fixedRel);
    }

    // Add implicit relationships
    for (var entryA in classes.entries) {
      final modelA = entryA.value;
      if (modelA.fields != null) {
        for (var entryB in classes.entries) {
          final modelB = entryB.value;
          if (modelA.name == modelB.name) continue; // skip self
          final found = modelA.fields!.entries.any((field) {
            final fieldValue = field.value;
            return !fieldValue.contains('relation') &&
                (fieldValue == modelB.name ||
                    fieldValue.contains('${modelB.name}?') ||
                    fieldValue.contains('List<${modelB.name}>'));
          });
          if (found) {
            umlBuffer.writeln('${modelA.name} -- ${modelB.name}');
          }
        }
      }
    }

    umlBuffer.writeln('@enduml');
    return umlBuffer.toString();
  }
}
