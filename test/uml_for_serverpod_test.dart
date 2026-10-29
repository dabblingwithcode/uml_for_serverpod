import 'package:test/test.dart';
import 'package:uml_for_serverpod/src/models.dart';
import 'package:uml_for_serverpod/src/uml/implicit_links.dart';
import 'package:uml_for_serverpod/src/uml/uml_style_block.dart';

void main() {
  group('implicit links', () {
    test('match whole type names, not substrings', () {
      expect(
        implicitLinkKind({'status': 'JobStatus, default=offen'}, 'Job'),
        isNull,
      );
      expect(
        implicitLinkKind({'status': 'JobStatus, default=offen'}, 'JobStatus'),
        ImplicitLink.fieldType,
      );
    });

    test('see through nullability, lists and module prefixes', () {
      expect(implicitLinkKind({'a': 'CivilDate?'}, 'CivilDate'),
          ImplicitLink.fieldType);
      expect(implicitLinkKind({'a': 'List<Passage>?'}, 'Passage'),
          ImplicitLink.fieldType);
      expect(implicitLinkKind({'a': 'module:assistant_shape:Rolle'}, 'Rolle'),
          ImplicitLink.fieldType);
    });

    test('extends is inheritance, relation fields are skipped', () {
      expect(implicitLinkKind({'extends': 'AuditMetadaten'}, 'AuditMetadaten'),
          ImplicitLink.inheritance);
      expect(
        implicitLinkKind({'job': 'Job?, relation(optional)'}, 'Job'),
        isNull,
      );
    });
  });

  group('layout', () {
    test('emits the layout pragma and flat separator when configured', () {
      final block = UmlStyleBlock.generateUmlStyleBlock(
        UmlConfig(layoutEngine: 'elk', flatPackages: true),
      );
      expect(block, contains('!pragma layout elk'));
      expect(block, contains('set separator none'));
    });

    test('keeps graphviz and nested packages by default', () {
      final block = UmlStyleBlock.generateUmlStyleBlock(UmlConfig());
      expect(block, isNot(contains('!pragma layout')));
      expect(block, isNot(contains('set separator')));
    });

    test('rejects an unknown layout engine', () {
      expect(
        () => UmlStyleBlock.generateUmlStyleBlock(
          UmlConfig(layoutEngine: 'dot'),
        ),
        throwsArgumentError,
      );
    });
  });

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
