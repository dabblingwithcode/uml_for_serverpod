import 'package:uml_for_serverpod/src/models.dart';

// should migrate skinparam to style: https://plantuml.com/en/style
class UmlStyleBlock {
  static String generateUmlStyleBlock(UmlConfig config) {
    final engine = config.layoutEngine;
    if (engine != null && !const {'elk', 'smetana'}.contains(engine)) {
      throw ArgumentError.value(
        engine,
        'layout.engine',
        'must be elk or smetana (omit it for graphviz)',
      );
    }
    return '''
${engine != null ? '!pragma layout $engine' : ''}
${config.flatPackages ? 'set separator none' : ''}
left to right direction
${config.skinparamNodesep != null ? 'skinparam nodesep ${config.skinparamNodesep}' : ''}
${config.skinparamRanksep != null ? 'skinparam ranksep ${config.skinparamRanksep}' : ''}
skinparam attributeFontSize 14
skinparam class {
  BackgroundColor ${config.classBackgroundHexColor}
  BorderColor ${config.classBorderHexColor}
}
<style>
document {
  BackgroundColor #fff
  Margin 100 100 100 100
}
classDiagram {
  RoundCorner 25
  FontSize 13
  FontStyle Regular
  package {
    Padding 20 20 20 20
    LineColor ${config.namespaceBorderHexColor}
    LineThickness 3
    FontSize 12
    BackgroundColor ${config.rootNamespaceBackgroundHexColor}
    title {
      Padding 10 10 10 10
      FontSize 36
      FontStyle bold
    }
  }    
  class {
    Padding 10 10 10 10
    FontSize 12
${config.classMaxWidth != null ? '    MaximumWidth ${config.classMaxWidth}' : ''}
        header {
          FontSize 36
          FontStyle bold
        } 
  }
}

</style>
 ''';
  }
}
