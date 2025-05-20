/// Model classes for UML generation
class ObjectRelation {
  String? objectName;
  String? fieldName;
  String? relatedObject;
  RelationType? type;

  ObjectRelation({
    this.objectName,
    this.fieldName,
    this.relatedObject,
    this.type,
  });
}

enum RelationType {
  one,
  many,
}

enum ClassProperty {
  table,
  serverOnly,
}

enum EnumProperty {
  enumSerialized,
  enumDefault,
}

enum ObjectType {
  classType('class'),
  databaseClassType('class'),
  enumType('enum'),
  exceptionType('exception');

  final String value;
  const ObjectType(this.value);
}

class UmlObject {
  ObjectType? objectType;
  String? filepath;
  String? tableName;

  String? name;
  Map<String, String>? fields;
  String? enumSerialized;
  String? enumNames;
  String? enumValues;
  List<ObjectRelation>? relations;

  UmlObject({
    this.objectType,
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
  // input/output paths
  final String? modelsDirPath;
  final String? umlOutputFile;

  // comments / colorful arrows options
  final bool printComments;
  final bool colorfullArrows;

  // namespace options
  final bool useNameSpace;
  final String? ignoreRootFolder;

  // defain one and many strings for the arrows
  final String oneString;
  final String manyString;

  // custom colors
  final String commentHexColor;
  final String manyHexColor;
  final String oneHexColor;
  final String relationHexColor;
  final String classNameHexColor;
  final String classBorderHexColor;
  final String classBackgroundHexColor;
  final String namespaceBackgroundHexColor;
  final String? namespaceBorderHexColor;

  UmlConfig({
    this.printComments = true,
    this.colorfullArrows = true,
    this.useNameSpace = true,
    this.modelsDirPath = 'lib',
    this.umlOutputFile = 'serverpod_uml_diagram.puml',
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
    this.namespaceBackgroundHexColor = '#DDDDDD',
    this.namespaceBorderHexColor = '#333333',
  });

  // Add this method to your UmlConfig class
  UmlConfig copyWith({
    bool? printComments,
    bool? colorfullArrows,
    bool? useNameSpace,
    String? modelsDirPath,
    String? umlOutputFile,
    String? ignoreRootFolder,
    String? commentHexColor,
    String? manyHexColor,
    String? manyString,
    String? oneHexColor,
    String? oneString,
    String? relationHexColor,
    String? classNameHexColor,
    String? classBorderHexColor,
    String? classBackgroundHexColor,
    String? namespaceBackgroundHexColor,
    String? namespaceBorderHexColor,
  }) {
    return UmlConfig(
      printComments: printComments ?? this.printComments,
      colorfullArrows: colorfullArrows ?? this.colorfullArrows,
      useNameSpace: useNameSpace ?? this.useNameSpace,
      modelsDirPath: modelsDirPath ?? this.modelsDirPath,
      umlOutputFile: umlOutputFile ?? this.umlOutputFile,
      ignoreRootFolder: ignoreRootFolder ?? this.ignoreRootFolder,
      commentHexColor: commentHexColor ?? this.commentHexColor,
      manyHexColor: manyHexColor ?? this.manyHexColor,
      manyString: manyString ?? this.manyString,
      oneHexColor: oneHexColor ?? this.oneHexColor,
      oneString: oneString ?? this.oneString,
      relationHexColor: relationHexColor ?? this.relationHexColor,
      classNameHexColor: classNameHexColor ?? this.classNameHexColor,
      classBorderHexColor: classBorderHexColor ?? this.classBorderHexColor,
      classBackgroundHexColor:
          classBackgroundHexColor ?? this.classBackgroundHexColor,
      namespaceBackgroundHexColor:
          namespaceBackgroundHexColor ?? this.namespaceBackgroundHexColor,
      namespaceBorderHexColor:
          namespaceBorderHexColor ?? this.namespaceBorderHexColor,
    );
  }

  factory UmlConfig.fromMap(Map<String, dynamic> map) {
    return UmlConfig(
      printComments: map['printComments'] ?? true,
      colorfullArrows: map['colorfullArrows'] ?? true,
      useNameSpace: map['useNameSpace'] ?? true,
      modelsDirPath: map['modelsDirPath'] ?? 'lib',
      umlOutputFile: map['umlOutputFile'] ?? 'er_diagram.puml',
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
      namespaceBackgroundHexColor:
          map['namespaceBackgroundHexColor'] ?? '#DDDDDD',
      namespaceBorderHexColor: map['namespaceBorderHexColor'] ?? '#333333',
    );
  }
}
