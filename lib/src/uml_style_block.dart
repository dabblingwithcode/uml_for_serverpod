import 'package:uml_for_serverpod/src/models.dart';

class UmlStyleBlock {
  static String generateUmlStyleBlock(UmlConfig config) {
    return '''
left to right direction
skinparam ranksep 100
skinparam nodesep 80
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
    FontSize 12
    BackgroundColor ${config.packageBackgroundHexColor}
        title {
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
