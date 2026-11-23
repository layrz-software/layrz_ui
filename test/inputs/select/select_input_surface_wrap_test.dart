import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/select/select_input_surface.dart';

import '../../helpers/pump_themed.dart';

const _longLabel =
    '[AllTank Systems] Acesso à exportação do relatório de fechamento de balsa '
    'com todas as colunas e filtros aplicados';

Future<void> _pumpSurface(WidgetTester tester, List<LayrzSelectItem<String>> items) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await pumpThemed(
    tester,
    Center(
      child: SizedBox(
        width: 320,
        height: 600,
        child: LayrzSelectInputSurface<String>(
          itemExtent: 40,
          items: items,
          enableSearch: true,
          canUnselect: false,
          onItemSelected: (_) {},
        ),
      ),
    ),
  );
}

Size _rowSizeOf(WidgetTester tester, Finder content) =>
    tester.getSize(find.ancestor(of: content, matching: find.byType(LayrzTappable)).first);

RenderParagraph _paragraphOf(WidgetTester tester, String text) => tester.renderObject<RenderParagraph>(find.text(text));

void main() {
  group('LayrzSelectInputSurface rows show their full content', () {
    testWidgets('a long text item wraps and its row grows past itemExtent', (tester) async {
      await _pumpSurface(tester, const [
        LayrzSelectItem(value: 'long', child: Text(_longLabel)),
      ]);

      expect(tester.takeException(), isNull);
      final paragraph = _paragraphOf(tester, _longLabel);
      expect(paragraph.didExceedMaxLines, isFalse);
      final rowSize = _rowSizeOf(tester, find.text(_longLabel));
      expect(rowSize.height, greaterThan(40));
      expect(paragraph.size.height, lessThanOrEqualTo(rowSize.height));
    });

    testWidgets('a short item keeps itemExtent as its row height', (tester) async {
      await _pumpSurface(tester, const [
        LayrzSelectItem(value: 'short', child: Text('Universal')),
      ]);

      expect(tester.takeException(), isNull);
      expect(_rowSizeOf(tester, find.text('Universal')).height, 40);
    });

    testWidgets('an icon + flexible text item wraps without overflow', (tester) async {
      await _pumpSurface(tester, [
        LayrzSelectItem(
          value: 'icon',
          child: Row(
            children: [
              Icon(MdiIcons.shieldAccount, size: 18),
              const SizedBox(width: 8),
              const Flexible(child: Text(_longLabel)),
            ],
          ),
        ),
      ]);

      expect(tester.takeException(), isNull);
      expect(_rowSizeOf(tester, find.text(_longLabel)).height, greaterThan(40));
      expect(_paragraphOf(tester, _longLabel).didExceedMaxLines, isFalse);
    });
  });
}
