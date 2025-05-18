import 'dart:io';

import 'package:uml_for_serverpod/src/yaml_parser.dart';

import 'models.dart';

class UmlGenerator {
  final UmlConfig config;
  final String modelsDirPath;
  late Directory modelsDir;

  final File umlOutputFile;

  SpyYamlParser yamlParser;
  UmlGenerator({
    required this.config,
    required this.modelsDirPath,
    required this.umlOutputFile,
  }) : yamlParser = SpyYamlParser(config: config, modelsDirPath: modelsDirPath);

  Future<void> generate() async {
    // 1. Collect all .spy.yaml files and concatenate their content
    final yamlContent = await yamlParser.collectYamlContent();

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
    skinparam class {
BackgroundColor ${config.classBackgroundHexColor}

BorderColor ${config.classBorderHexColor}

}
    <style>
document {
  BackgroundColor #fff
  Margin 100 100 100 100
}
    classDiagram {
        RoundCorner 25
        FontSize 13
        FontStyle Regular
        package {
          FontSize 12
          BackgroundColor ${config.packageBackgroundHexColor}
              title {
                FontSize 36
                FontStyle bold
              }
        }    
        class {
          Padding 10 10 10 10
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
            ? 'entity ${model.name} <<table: <b>${model.tableName}</b>>> ##[bold] {'
            : 'class ${model.name} ##[bold] {';
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
    return umlBuffer.toString();
  }
}
