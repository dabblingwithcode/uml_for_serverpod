import 'package:uml_for_serverpod/src/uml/colors.dart';
import 'package:uml_for_serverpod/src/models.dart';
import 'package:uml_for_serverpod/src/yaml/spy_yaml_parser.dart';

class UmlObjectHelpers {
  static String getObjectNameWithNameSpace(UmlObject object, UmlConfig config) {
    final pathParts = object.filepath?.split('/') ?? [];
    final firstNameSpace = pathParts.isNotEmpty
        ? pathParts[pathParts.length - 3] != config.ignoreRootFolder
            ? pathParts[pathParts.length - 3]
            : null
        : null;

    final secondNameSpace = pathParts.isNotEmpty
        ? pathParts[pathParts.length - 2] != config.ignoreRootFolder
            ? pathParts[pathParts.length - 2]
            : null
        : null;

    final result = [
      if (firstNameSpace != null && firstNameSpace != '') firstNameSpace,
      if (secondNameSpace != null) secondNameSpace,
      object.name,
    ].join('.');

    return result;
  }

  static String renderUmlObjectDeclaration(UmlObject object, UmlConfig config) {
    // final objectName = config.useNameSpace
    //     ? getObjectNameWithNameSpace(object, config)
    //     : object.name;
    final objectName = object.name;
    final objectType = object.objectType;
    if (objectType == null) {
      throw Exception('Object type is null');
    }
    switch (objectType) {
      case ObjectType.classType:
        return '${objectType.value} $objectName ##[bold]  {';
      case ObjectType.databaseClassType:
        return '${objectType.value} $objectName <<table: <b>${object.tableName}</b>>> #e2f0fb##[bold] {';

      case ObjectType.exceptionType:
        return '${objectType.value} $objectName #ffe6e6##[bold]  {';
      case ObjectType.enumType:
        return '${objectType.value} $objectName #ece4ff ##[bold] {';
    }
  }

  static String? renderUmlObjectFieldLine(
      String key, String value, UmlConfig config) {
    if (value.contains('relation')) {
      return SpyYamlParser.renderUmlObjectFieldRelationLine(
          key: key, value: value, config: config);
    } else if (key.contains('##')) {
      return config.printComments
          ? '<color:${config.commentHexColor}>$key</color>'
          : null;
    } else if (key.contains('indexes:')) {
      return '<b><color:${config.relationHexColor}>$key</color></b>';
    } else if (key.contains('idx:')) {
      return '<b><color:${config.relationHexColor}>$key</color></b>';
    } else if (key.contains('unique')) {
      return '<b><color:${config.relationHexColor}>$key</color></b>: <b><color:${config.classNameHexColor}>$value</color></b>';
    } else {
      return '  <i>$key</i>: <b><color:${config.classNameHexColor}>$value</color></b>';
    }
  }

  static List<String> renderUmlObjectRelationLines(
      UmlConfig config, List<ObjectRelation> relations) {
    final relationLines = <String>[];
    int? lastArrowIndex;
    for (final relation in relations) {
      final relatedObject = relation.relatedObject;
      String left = '';
      String right = '';
      String arrow = '';
      switch (relation.type) {
        case RelationType.one:
          left =
              '"<b><size:20><color:${config.oneHexColor}><back:white>${config.oneString}</back></color></size></b>"';
          right =
              '"<b><size:20><color:${config.manyHexColor}><back:white>${config.manyString}</back></color></size></b>"';
          break;
        case RelationType.many:
          left =
              '"<b><size:20><color:${config.oneHexColor}><back:white>${config.oneString}</back></color></size></b>"';
          right =
              '"<b><size:20><color:${config.manyHexColor}><back:white>${config.manyString}</back></color></size></b>"';
          break;
        case null:
          throw Exception('Relation type is null');
      }

      if (config.colorfullArrows) {
        final arrowColors = colorPalette;
        lastArrowIndex = lastArrowIndex ?? 0;
        final colorIndex = lastArrowIndex % arrowColors.length;
        final selectedColor = arrowColors.elementAt(colorIndex);
        lastArrowIndex++;
        arrow = relation.type == RelationType.one
            ? '<-[$selectedColor,thickness=4]-'
            : '-[$selectedColor,thickness=4]->';
      } else {
        arrow = relation.type == RelationType.one
            ? '<-[#333333,thickness=4]-'
            : '-[thickness=4]->';
      }
      if (relatedObject != null) {
        final line =
            ' ${relation.objectName!}::${relation.fieldName} $left $arrow $right ${relation.relatedObject} ';
        // '$arrow <i>${relation.fieldName}</i> : <b><color:${config.classNameHexColor}>$relatedObject</color></b>';
        relationLines.add(line);
      }
    }
    return relationLines;
  }
}
