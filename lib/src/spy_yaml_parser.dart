import 'dart:io';

import 'package:uml_for_serverpod/src/colors.dart';
import 'package:uml_for_serverpod/src/models.dart';

class SpyYamlParser {
  final UmlConfig config;

  SpyYamlParser({required this.config});

  Future<String> collectYamlContent() async {
    final modelsDir = Directory(config.modelsDirPath!);
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

    stdout.writeln(
        '👓️🚀 Read ${yamlFiles.length} Serverpod .spy.yaml files in ${modelsDir.path}');
    return yamlBuffer.toString();
  }

  ({Map<String, UmlObject> serverpodObjects, List<String> relations})
      parseModels(String content) {
    final objetcs = <String, UmlObject>{};
    final relations = <String>[];

    final lines = content.split('\n');
    UmlObject? currentModel;
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
          if (currentModel.objectType == ObjectType.enumType &&
              enumValues.isNotEmpty) {
            currentModel.enumValues = enumValues.join(', ');
            enumValues.clear();
          }
          // collect the fields value
          if (currentFields.isNotEmpty) {
            currentModel.fields = Map.of(currentFields);
          }
          // save the finished model in the classes map
          objetcs[currentModel.name!] = currentModel;
          // reset the current model
          collectingEnumValues = false;
          currentFields.clear();
        }
        // reset the current model
        currentModel = UmlObject(
          filepath: line.substring(9).trim(),
          fields: {},
          relations: [],
        );
        currentFields = {};
        continue;
      }

      if (line.startsWith('class:')) {
        currentModel!.objectType = ObjectType.classType;

        currentModel.name = line.split(':').last.trim();

        continue;
      }
      // Check for table name
      if (line.startsWith('table:')) {
        currentModel!.objectType = ObjectType.databaseClassType;

        currentModel.tableName = line.split(':').last.trim();

        continue;
      }
      if (line.startsWith('enum:')) {
        currentModel!.objectType = ObjectType.enumType;

        currentModel.name = line.split(':').last.trim();

        continue;
      }
      if (line.startsWith('exception:')) {
        currentModel!.objectType = ObjectType.exceptionType;

        currentModel.name = line.split(':').last.trim();

        continue;
      }

      // Check for enum serialized value
      if (currentModel!.objectType == ObjectType.enumType &&
          line.startsWith('serialized:')) {
        currentModel.enumSerialized = line.split(':').last.trim();
        continue;
      }
      // Check for enum names
      if (currentModel.objectType == ObjectType.enumType &&
          line.startsWith('values:')) {
        enumValues.clear();
        collectingEnumValues = true;
        continue;
      }
      if (collectingEnumValues) {
        if (line.trimLeft().startsWith('- ')) {
          enumValues.add(line.trimLeft().substring(2).trim());
          continue;
        }
      }
      if (line.startsWith('##')) {
        // TODO: This might get buggy if two commments have the same string
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

      // We catched all other line options, this should be a field
      // Check for field name and type
      if (line.contains(':') &&
          currentModel.objectType != ObjectType.enumType) {
        final parts = line.split(':');

        final fieldName = parts[0].trim();
        final rest = parts.sublist(1).join(':').trim();
        currentFields[fieldName] = rest;

        if (rest.contains('relation')) {
          final typeMatch = RegExp(r'(List<)?([A-Za-z0-9_]+)').firstMatch(rest);
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
            // TODO: This should be done in the UML generator
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
              arrow = isList ? '<-[#333333,thickness=4]-' : '-[thickness=4]->';
            }
            // Check if the relation already exists

            if (!relations.any(
                (r) => r.contains(currentModel!.name!) && r.contains(type))) {
              relations.add(
                  ' ${currentModel.name!.split('.').last}::$fieldName $left $arrow $right $type ');
            }
          }
        }
      }
    }

    // Save the last object
    if (currentModel != null) {
      if (currentModel.objectType == ObjectType.enumType &&
          enumValues.isNotEmpty) {
        currentModel.enumValues = enumValues.join(', ');
      }
      if (currentFields.isNotEmpty) {
        currentModel.fields = Map.of(currentFields);
      }
      objetcs[currentModel.name!] = currentModel;
    }
    stdout.writeln(
        '⚙️  Parsed ${objetcs.length} classes and ${relations.length} relations');
    return (
      serverpodObjects: objetcs,
      relations: relations,
    );
  }
}
