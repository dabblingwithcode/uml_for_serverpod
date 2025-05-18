import 'dart:io';

import 'package:uml_for_serverpod/src/colors.dart';

import 'models.dart';

class UmlGenerator {
  final Directory modelsDir;
  final File yamlOutputFile;
  final File umlOutputFile;

  // Config options
  final bool printComments;
  final bool colorfullArrows;
  final String commentHexColor;
  final String manyHexColor;
  final String manyString;
  final String oneHexColor;
  final String oneString;
  final String relationHexColor;
  final String classHexColor;

  UmlGenerator({
    required this.modelsDir,
    required this.yamlOutputFile,
    required this.umlOutputFile,
    this.printComments = true,
    this.colorfullArrows = true,
    this.commentHexColor = '#93c47d',
    this.manyHexColor = '#27ae60',
    this.manyString = 'N',
    this.oneHexColor = '#9b59b6',
    this.oneString = '1',
    this.relationHexColor = '#0164aa',
    this.classHexColor = '#ff962f',
  });

  Future<void> generate() async {
    // 1. Collect all .spy.yaml files and concatenate their content
    final yamlContent = await collectYamlContent();
    await yamlOutputFile.writeAsString(yamlContent);

    // 2. Parse YAML content to create UmlModel objects
    final parsedData = parseYamlContent(yamlContent);
    final classes = parsedData['classes'] as Map<String, UmlModel>;
    final relations = parsedData['relations'] as List<String>;

    // 3. Generate UML PlantUML content
    final umlContent = generateUml(classes, relations);
    await umlOutputFile.writeAsString(umlContent);
  }

  Future<String> collectYamlContent() async {
    final yamlFiles = <File>[];
    await for (var entity
        in modelsDir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.spy.yaml')) {
        yamlFiles.add(entity);
      }
    }

    final yamlBuffer = StringBuffer();
    for (var file in yamlFiles) {
      yamlBuffer.writeln(
          'filepath: ${file.path.replaceFirst(modelsDir.path, '').replaceAll('\\', '/')}');
      yamlBuffer.writeln(await file.readAsString());
      yamlBuffer.writeln();
    }

    return yamlBuffer.toString();
  }

  Map<String, dynamic> parseYamlContent(String content) {
    final classes = <String, UmlModel>{};
    final relations = <String>[];

    final lines = content.split('\n');
    UmlModel? currentModel;
    int? lastArrowIndex;
    Map<String, String> currentFields = {};
    bool collectingEnumValues = false;
    List<String> enumValues = [];

    for (int i = 0; i < lines.length; i++) {
      // First trim the lines
      var line = lines[i].trimRight().trimLeft();

      if (line.startsWith('filepath:')) {
        // We have a new object
        // If current model is not null, we already processed an object
        // and we need to save it
        if (currentModel != null) {
          // collect the enum values
          if (currentModel.isEnum == true && enumValues.isNotEmpty) {
            currentModel.enumValues = enumValues.join(', ');
            enumValues.clear();
          }
          // save the finished model in the classes map
          if (currentFields.isNotEmpty) {
            currentModel.fields = Map.of(currentFields);
          }
          // save the finished model in the classes map
          classes[currentModel.name!] = currentModel;
          collectingEnumValues = false;
          currentFields.clear();
        }
        // reset the current model
        currentModel = UmlModel(
          filepath: line.substring(9).trim(),
          fields: {},
        );
        continue;
      }

      if (line.startsWith('class:')) {
        currentModel!.name = line.substring(6).trim();
        currentModel.isEnum = false;
        continue;
      }

      if (line.startsWith('enum:')) {
        currentModel!.name = line.substring(5).trim();
        currentModel.isEnum = true;
        continue;
      }
      // Check for enum serialized value
      if (currentModel!.isEnum == true && line.startsWith('serialized:')) {
        currentModel.enumSerialized = line.substring(12).trim();
        continue;
      }
      // Check for enum names
      if (currentModel.isEnum == true &&
          line.trimLeft().startsWith('values:')) {
        enumValues.clear();
        collectingEnumValues = true;
        continue;
      }

      if (collectingEnumValues) {
        if (line.trimLeft().startsWith('- ')) {
          enumValues.add(line.trimLeft().substring(2).trim());
          continue;
        } else if (line.trim().isEmpty) {
          collectingEnumValues = false;
          continue;
        }
      }

      if (line.startsWith('##')) {
        // pass comments as key to the fields, we don't need a value
        currentFields[line] = '';
        continue;
      }

      // catch the indexing lines
      if (line.startsWith('indexes:') || line.contains('idx:')) {
        currentFields[line] = '';
        continue;
      }

      // Start of fields block
      if (line.startsWith('fields:')) {
        continue;
      }
      // Check for table name
      if (line.startsWith('table:')) {
        currentModel.tableName = line.substring(6).trim();
        continue;
      }
      // Check for field name and type
      if (line.contains(':') && currentModel.isEnum != true) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final fieldName = parts[0].trim();
          final rest = parts.sublist(1).join(':').trim();
          currentFields[fieldName] = rest;

          if (rest.contains('relation')) {
            final typeMatch =
                RegExp(r'(List<)?([A-Za-z0-9_]+)').firstMatch(rest);
            final type = typeMatch?.group(2);
            if (type != null) {
              bool isList = rest.contains('List<');
              String arrow = '';
              String right = isList
                  ? '"<b><size:20><color:$manyHexColor><back:white>$manyString</back></color></size></b>"'
                  : '"<b><size:20><color:$oneHexColor><back:white>$oneString</back></color></size></b>"';
              String left = isList
                  ? '"<b><size:20><color:$oneHexColor><back:white>$oneString</back></color></size></b>"'
                  : '"<b><size:20><color:$manyHexColor><back:white>$manyString</back></color></size></b>"';
              if (colorfullArrows) {
                final arrowColors = colorPalette;
                lastArrowIndex = lastArrowIndex ?? 0;
                final colorIndex = lastArrowIndex % arrowColors.length;
                final selectedColor = arrowColors.elementAt(colorIndex);
                lastArrowIndex++; // Increment for next use
                arrow = isList
                    ? '<-[$selectedColor,thickness=4]-'
                    : '-[$selectedColor,thickness=4]->';
              } else {
                arrow =
                    isList ? '<-[#6aa84f,thickness=4]-' : '-[thickness=4]->';
              }

              if (!relations.any((r) =>
                  r.contains(' ${currentModel!.name!} ') && r.contains(type))) {
                relations.add(
                    ' ${currentModel.name!}::$fieldName $left $arrow $right $type ');
              }
            }
          }
        }
      }
    }

    // Save the last object
    if (currentModel != null) {
      if (currentModel.isEnum == true && enumValues.isNotEmpty) {
        currentModel.enumValues = enumValues.join(', ');
      }
      if (currentFields.isNotEmpty) {
        currentModel.fields = Map.of(currentFields);
      }
      classes[currentModel.name!] = currentModel;
    }

    return {
      'classes': classes,
      'relations': relations,
    };
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
                  ' ➡️ <i>$k</i> : <b><color:$classHexColor>${v.split(',')[0]}</color></b> ${v.split(',')[1].replaceFirst('relation', '<b><color:$relationHexColor>relation</color></b>')} ';
            } else if (k.contains('##') & printComments) {
              fieldsLine = '<color:$commentHexColor>$k</color>';
            } else if (k.contains('##') & !printComments) {
              return;
            } else if (k.contains('indexes:')) {
              umlBuffer.writeln('--');
              fieldsLine = '<b><color:$relationHexColor>$k</color></b>';
            } else if (k.contains('idx:')) {
              fieldsLine = '<b><color:$relationHexColor>$k</color></b>';
            } else if (k.contains('unique')) {
              fieldsLine =
                  '<b><color:$relationHexColor>$k</color></b>: <b><color:$classHexColor>$v</color></b>';
            } else {
              fieldsLine =
                  '  <i>$k</i>: <b><color:$classHexColor>$v</color></b>';
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
