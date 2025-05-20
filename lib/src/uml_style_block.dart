import 'package:uml_for_serverpod/src/models.dart';

// should migrate skinparam to style: https://plantuml.com/en/style
class UmlStyleBlock {
  static String generateUmlStyleBlock(UmlConfig config) {
    return '''
left to right direction
skinparam nodesep 10
skinparam ranksep 100
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
    BackgroundColor ${config.namespaceBackgroundHexColor}
    title {
      Padding 10 10 10 10
      FontSize 36
      FontStyle bold
    }
  }    
  class {
    Padding 10 10 10 10
    FontSize 12
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
