/// Model classes for UML generation
class ObjectRelation {
  String? relatedObject;
  RelationType? type;

  ObjectRelation({
    this.relatedObject,
    this.type,
  });
}

enum RelationType {
  one,
  many,
}

class UmlModel {
  bool? isEnum;
  String? filepath;
  String? tableName;
  String? name;
  Map<String, String>? fields;
  String? enumSerialized;
  String? enumNames;
  String? enumValues;
  List<ObjectRelation>? relations;

  UmlModel({
    this.isEnum,
    this.filepath,
    this.tableName,
    this.name,
    this.fields,
    this.enumSerialized,
    this.enumNames,
    this.enumValues,
    this.relations,
  });
}

// Add this class to models.dart
class UmlConfig {
  final bool printComments;
  final bool colorfullArrows;
  final bool useNameSpace;
  final String modelsDirPath;
  final String? ignoreRootFolder;
  final String commentHexColor;
  final String manyHexColor;
  final String manyString;
  final String oneHexColor;
  final String oneString;
  final String relationHexColor;
  final String classNameHexColor;
  final String classBorderHexColor;
  final String classBackgroundHexColor;
  final String packageBackgroundHexColor;

  UmlConfig({
    this.printComments = true,
    this.colorfullArrows = true,
    this.useNameSpace = true,
    this.modelsDirPath = 'lib',
    this.ignoreRootFolder,
    this.commentHexColor = '#93c47d',
    this.manyHexColor = '#27ae60',
    this.manyString = 'N',
    this.oneHexColor = '#9b59b6',
    this.oneString = '1',
    this.relationHexColor = '#0164aa',
    this.classNameHexColor = '#ff962f',
    this.classBorderHexColor = '#333333',
    this.classBackgroundHexColor = '#EEEEEE',
    this.packageBackgroundHexColor = '#DDDDDD',
  });

  factory UmlConfig.fromMap(Map<String, dynamic> map) {
    return UmlConfig(
      printComments: map['printComments'] ?? true,
      colorfullArrows: map['colorfullArrows'] ?? true,
      useNameSpace: map['useNameSpace'] ?? true,
      modelsDirPath: map['modelsDirPath'] ?? 'lib',
      ignoreRootFolder: map['ignoreRootFolder'],
      commentHexColor: map['commentHexColor'] ?? '#93c47d',
      manyHexColor: map['manyHexColor'] ?? '#27ae60',
      manyString: map['manyString'] ?? 'N',
      oneHexColor: map['oneHexColor'] ?? '#9b59b6',
      oneString: map['oneString'] ?? '1',
      relationHexColor: map['relationHexColor'] ?? '#0164aa',
      classNameHexColor: map['classNameHexColor'] ?? '#ff962f',
      classBorderHexColor: map['classBorderHexColor'] ?? '#333333',
      classBackgroundHexColor: map['classBackgroundHexColor'] ?? '#EEEEEE',
      packageBackgroundHexColor: map['packageBackgroundHexColor'] ?? '#DDDDDD',
    );
  }
}
