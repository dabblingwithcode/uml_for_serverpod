import 'package:test/test.dart';
import 'package:uml_for_serverpod/src/models.dart';
import 'package:uml_for_serverpod/src/uml/uml_style_block.dart';

void main() {
  group('class max width', () {
    test('emits MaximumWidth in the class style when configured', () {
      final block = UmlStyleBlock.generateUmlStyleBlock(
        UmlConfig(classMaxWidth: 400),
      );
      expect(block, contains('MaximumWidth 400'));
    });

    test('emits no MaximumWidth by default', () {
      final block = UmlStyleBlock.generateUmlStyleBlock(UmlConfig());
      expect(block, isNot(contains('MaximumWidth')));
    });

    test('copyWith carries the max width', () {
      expect(UmlConfig().copyWith(classMaxWidth: 300).classMaxWidth, 300);
    });
  });
}
