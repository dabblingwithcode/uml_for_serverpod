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
  databaseClassType('entity'),
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
  final bool printComments;
  final bool colorfullArrows;
  final bool useNameSpace;
  final String? modelsDirPath;
  final String? umlOutputFile;

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
    this.packageBackgroundHexColor = '#DDDDDD',
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
    String? packageBackgroundHexColor,
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
      packageBackgroundHexColor:
          packageBackgroundHexColor ?? this.packageBackgroundHexColor,
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
      packageBackgroundHexColor: map['packageBackgroundHexColor'] ?? '#DDDDDD',
    );
  }
}
