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

  // layout engine: elk or smetana (PlantUML `!pragma layout`); null keeps graphviz
  final String? layoutEngine;

  // keep dotted package names flat instead of nesting them (`set separator none`)
  final bool flatPackages;

  // class cards wider than this wrap their text (PlantUML MaximumWidth)
  final int? classMaxWidth;

  // output backend: plantuml (default) or dot (Graphviz two-pass SVG)
  final String outputFormat;

  // directory holding the Graphviz dot and neato executables; null uses PATH
  final String? graphvizBinDir;

  // dot backend: package grid columns; null chooses them from gridAspectRatio
  final int? gridColumns;

  // dot backend: target width / height of the package grid (default 1.0)
  final double? gridAspectRatio;

  // dot backend: gap between package blocks, in points
  final int gridGap;

  // dot backend: rows (each block its own width) or cells (aligned columns)
  final String gridMode;

  // dot backend: packages placed first, in this order; the rest by name
  final List<String> gridOrder;

  // dot backend: Graphviz splines for the edges (true routes around cards)
  final String splines;

  // comments / colorful arrows options
  final bool printComments;

  final bool colorfullArrows;

  // colour the implicit field-type and inheritance links as well
  final bool colorfullTypeLinks;

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
    this.classMaxWidth,
    this.layoutEngine,
    this.flatPackages = false,
    this.outputFormat = 'plantuml',
    this.graphvizBinDir,
    this.gridColumns,
    this.gridAspectRatio,
    this.gridGap = 120,
    this.gridMode = 'rows',
    this.gridOrder = const [],
    this.splines = 'true',
    this.printComments = true,
    this.colorfullArrows = true,
    this.colorfullTypeLinks = false,
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
    int? classMaxWidth,
    String? layoutEngine,
    bool? flatPackages,
    String? outputFormat,
    String? graphvizBinDir,
    int? gridColumns,
    double? gridAspectRatio,
    int? gridGap,
    String? gridMode,
    List<String>? gridOrder,
    String? splines,
    bool? printComments,
    bool? colorfullArrows,
    bool? colorfullTypeLinks,
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
      classMaxWidth: classMaxWidth ?? this.classMaxWidth,
      layoutEngine: layoutEngine ?? this.layoutEngine,
      flatPackages: flatPackages ?? this.flatPackages,
      outputFormat: outputFormat ?? this.outputFormat,
      graphvizBinDir: graphvizBinDir ?? this.graphvizBinDir,
      gridColumns: gridColumns ?? this.gridColumns,
      gridAspectRatio: gridAspectRatio ?? this.gridAspectRatio,
      gridGap: gridGap ?? this.gridGap,
      gridMode: gridMode ?? this.gridMode,
      gridOrder: gridOrder ?? this.gridOrder,
      splines: splines ?? this.splines,
      printComments: printComments ?? this.printComments,
      colorfullArrows: colorfullArrows ?? this.colorfullArrows,
      colorfullTypeLinks: colorfullTypeLinks ?? this.colorfullTypeLinks,
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
      classMaxWidth: map['classMaxWidth'],
      layoutEngine: map['layoutEngine'],
      flatPackages: map['flatPackages'] ?? false,
      outputFormat: map['outputFormat'] ?? 'plantuml',
      graphvizBinDir: map['graphvizBinDir'],
      gridColumns: map['gridColumns'],
      gridAspectRatio: (map['gridAspectRatio'] as num?)?.toDouble(),
      gridGap: map['gridGap'] ?? 120,
      gridMode: map['gridMode'] ?? 'rows',
      gridOrder: [...?(map['gridOrder'] as List?)?.map((e) => '$e')],
      splines: map['splines'] ?? 'true',
      printComments: map['printComments'] ?? true,
      colorfullArrows: map['colorfullArrows'] ?? true,
      colorfullTypeLinks: map['colorfullTypeLinks'] ?? false,
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
