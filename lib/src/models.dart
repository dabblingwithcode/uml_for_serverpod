/// Model classes for UML generation
class Relation {
  String? name;
  RelationType? type;

  Relation({
    this.name,
    this.type,
  });
}

enum RelationType {
  oneToOne,
  oneToMany,
  manyToOne,
  manyToMany,
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
  List<Relation>? relations;

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
  final String commentHexColor;
  final String manyHexColor;
  final String manyString;
  final String oneHexColor;
  final String oneString;
  final String relationHexColor;
  final String classHexColor;

  UmlConfig({
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

  factory UmlConfig.fromMap(Map<String, dynamic> map) {
    return UmlConfig(
      printComments: map['printComments'] ?? true,
      colorfullArrows: map['colorfullArrows'] ?? true,
      commentHexColor: map['commentHexColor'] ?? '#93c47d',
      manyHexColor: map['manyHexColor'] ?? '#27ae60',
      manyString: map['manyString'] ?? 'N',
      oneHexColor: map['oneHexColor'] ?? '#9b59b6',
      oneString: map['oneString'] ?? '1',
      relationHexColor: map['relationHexColor'] ?? '#0164aa',
      classHexColor: map['classHexColor'] ?? '#ff962f',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'printComments': printComments,
      'colorfullArrows': colorfullArrows,
      'commentHexColor': commentHexColor,
      'manyHexColor': manyHexColor,
      'manyString': manyString,
      'oneHexColor': oneHexColor,
      'oneString': oneString,
      'relationHexColor': relationHexColor,
      'classHexColor': classHexColor,
    };
  }
}
