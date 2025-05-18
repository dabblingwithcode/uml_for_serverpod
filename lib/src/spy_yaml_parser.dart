import 'dart:io';

import 'package:uml_for_serverpod/src/spy_yaml_parse_helpers.dart';
import 'package:uml_for_serverpod/uml_for_serverpod.dart';

class SpyYamlParser {
  final UmlConfig config;
  final String modelsDirPath;
  SpyYamlParser({required this.config, required this.modelsDirPath});

  Future<String> collectYamlContent() async {
    final modelsDir = Directory(modelsDirPath);
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
        if (config.useNameSpace) {
          final nameSpaces = SpyYamlParseHelpers.getNameSpacesFromPath(
              currentModel!.filepath!, config.ignoreRootFolder);
          currentModel.name =
              '${nameSpaces.nameSpace != null ? '${nameSpaces.nameSpace}.' : ''}${nameSpaces.subNameSpace != null ? '${nameSpaces.subNameSpace}.' : ''}${line.substring(6).trim()}';
        } else {
          currentModel!.name = line.substring(6).trim();
        }

        currentModel.isEnum = false;
        continue;
      }

      if (line.startsWith('enum:')) {
        if (config.useNameSpace) {
          final nameSpaces = SpyYamlParseHelpers.getNameSpacesFromPath(
              currentModel!.filepath!, config.ignoreRootFolder);
          currentModel.name =
              '${nameSpaces.nameSpace != null ? '${nameSpaces.nameSpace}.' : ''}${nameSpaces.subNameSpace != null ? '${nameSpaces.subNameSpace}.' : ''}${line.substring(5).trim()}';
        } else {
          currentModel!.name = line.substring(5).trim();
        }
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
              final relation = ObjectRelation(
                  relatedObject: type,
                  type: isList ? RelationType.one : RelationType.many);
              if (currentModel.relations == null) {
                currentModel.relations = [relation];
              } else {
                currentModel.relations!.add(relation);
              }

              String arrow = '';
              String right = isList
                  ? '"<b><size:20><color:${config.manyHexColor}><back:white>${config.manyString}</back></color></size></b>"'
                  : '"<b><size:20><color:${config.oneHexColor}><back:white>${config.oneString}</back></color></size></b>"';
              String left = isList
                  ? '"<b><size:20><color:${config.oneHexColor}><back:white>${config.oneString}</back></color></size></b>"'
                  : '"<b><size:20><color:${config.manyHexColor}><back:white>${config.manyString}</back></color></size></b>"';
              if (config.colorfullArrows) {
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
                    isList ? '<-[#333333,thickness=4]-' : '-[thickness=4]->';
              }
              // Check if the relation already exists
              if (!relations.any((r) =>
                  r.contains(' ${currentModel!.name!.split('.').last} ') &&
                  r.contains(type))) {
                relations.add(
                    ' ${currentModel.name!.split('.').last}::$fieldName $left $arrow $right $type ');
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
}
