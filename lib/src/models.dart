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

class UmlNamespace {
  final String name;
  final String? parentNameSpace;
  List<UmlObject> children;

  UmlNamespace({
    required this.name,
    required this.parentNameSpace,
    required this.children,
  });
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

class UmlConfig {
  // input/output paths
  final String modelsDirPath;

  final String umlOutputFile;

  // layout options
  final int? skinparamNodesep;

  final int? skinparamRanksep;

  // comments / colorful arrows options
  final bool printComments;

  final bool colorfullArrows;

  // namespace options
  final bool useNameSpace;

  final String? ignoreRootFolder;

  // define one and many strings for the arrows relation labelling
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
  final String rootNamespaceBackgroundHexColor;
  final String namespaceBorderHexColor;
  final String secondLevelNamespaceBackgroundHexColor;
  final String thirdLevelNamespaceBackgroundHexColor;

  UmlConfig({
    this.skinparamNodesep,
    this.skinparamRanksep,
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
    // class styling
    this.classNameHexColor = '#ff962f',
    this.classBorderHexColor = '#333333',
    this.classBackgroundHexColor = '#EEEEEE',
    // namespace styling
    this.namespaceBorderHexColor = '#333333',
    this.rootNamespaceBackgroundHexColor = '#fff2cc',
    this.secondLevelNamespaceBackgroundHexColor = '#ffe9a7',
    this.thirdLevelNamespaceBackgroundHexColor = '#ffdb72',
  });

  // Add this method to your UmlConfig class
  UmlConfig copyWith({
    int? skinparamNodesep,
    int? skinparamRanksep,
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
    String? rootNamespaceBackgroundHexColor,
    String? secondLevelNamespaceBackgroundHexColor,
    String? thirdLevelNamespaceBackgroundHexColor,
    String? namespaceBorderHexColor,
  }) {
    return UmlConfig(
      skinparamNodesep: skinparamNodesep ?? this.skinparamNodesep,
      skinparamRanksep: skinparamRanksep ?? this.skinparamRanksep,
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
      rootNamespaceBackgroundHexColor: rootNamespaceBackgroundHexColor ??
          this.rootNamespaceBackgroundHexColor,
      secondLevelNamespaceBackgroundHexColor:
          secondLevelNamespaceBackgroundHexColor ??
              this.secondLevelNamespaceBackgroundHexColor,
      thirdLevelNamespaceBackgroundHexColor:
          thirdLevelNamespaceBackgroundHexColor ??
              this.thirdLevelNamespaceBackgroundHexColor,
      namespaceBorderHexColor:
          namespaceBorderHexColor ?? this.namespaceBorderHexColor,
    );
  }

  factory UmlConfig.fromMap(Map<String, dynamic> map) {
    return UmlConfig(
      skinparamNodesep: map['skinparamNodesep'],
      skinparamRanksep: map['skinparamRanksep'],
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
      rootNamespaceBackgroundHexColor:
          map['rootNamespaceBackgroundHexColor'] ?? '#DDDDDD',
      secondLevelNamespaceBackgroundHexColor:
          map['secondLevelNamespaceBackgroundHexColor'] ?? '#FFE9A7',
      thirdLevelNamespaceBackgroundHexColor:
          map['thirdLevelNamespaceBackgroundHexColor'] ?? '#FFDB72',
      namespaceBorderHexColor: map['namespaceBorderHexColor'] ?? '#333333',
    );
  }
}
