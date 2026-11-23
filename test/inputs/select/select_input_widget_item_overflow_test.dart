import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// Regression coverage for [LayrzSelectInput]'s closed (idle) field overflowing
/// when the selected item's `child` is a widget wider than the field — e.g. a
/// `Row` with an icon and an unbounded `Text`.
///
/// The closed field overlays `selectedItem.child` on the editable field via a
/// `Stack`, which passes LOOSE constraints, so a `Row` with an unbounded `Text`
/// used to lay out at its intrinsic width and overflow horizontally. The fix
/// bounds the overlay to the field width (`Positioned.fill` + `ClipRect`), so a
/// wide child is clipped to the field rather than throwing a `RenderFlex`
/// overflow. These tests assert on the absence of a render exception, not on
/// reading the source.
int _lineCount(RenderParagraph p) => (p.size.height / p.getFullHeightForCaret(const TextPosition(offset: 0))).round();

void main() {
  group('LayrzSelectInput closed field — wide widget item does not overflow', () {
    // The selected item's presentation is a Row with an icon and a long label,
    // the exact shape that previously overflowed.
    List<LayrzSelectItem<String>> items() => [
      LayrzSelectItem<String>(
        value: 'a',
        searchableStrings: const {'Alpha'},
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MdiIcons.truckOutline, size: 16),
            const SizedBox(width: 4),
            const Text('A very long selected item label that easily exceeds a narrow field width'),
          ],
        ),
      ),
    ];

    testWidgets('a narrow field with a wide Row+text selected item renders without overflow', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 800);

      await pumpThemedApp(
        tester,
        Center(
          // Constrain the field to a narrow width so the wide selected-item Row
          // would overflow it if unbounded.
          child: SizedBox(
            width: 180,
            child: LayrzSelectInput<String>(
              itemExtent: 40,
              items: items(),
              value: 'a',
              labelText: 'Vehicle',
            ),
          ),
        ),
      );

      // The selected item's Row is shown in the closed field; it must NOT
      // overflow (no RenderFlex overflow exception).
      expect(tester.takeException(), isNull);
      // The overlaid child is present.
      expect(find.byIcon(MdiIcons.truckOutline), findsOneWidget);
    });

    testWidgets('the wide selected item is clipped to the field (ClipRect present)', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 800);

      await pumpThemedApp(
        tester,
        Center(
          child: SizedBox(
            width: 180,
            child: LayrzSelectInput<String>(
              itemExtent: 40,
              items: items(),
              value: 'a',
              labelText: 'Vehicle',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // The overlay bounds the selected item to the field via a ClipRect, so a
      // wide child paints clipped rather than overflowing.
      expect(find.byType(ClipRect), findsWidgets);
    });
  });

  group('LayrzSelectInput — Row + Flexible label item works in field and picker', () {
    const longLabel = '[AllTank Systems] Acesso à exportação do relatório de fechamento de balsa com todas as colunas';

    final shapes = <String, Widget Function(String)>{
      'min Row + Flexible': (text) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Icon(MdiIcons.shieldAccount, size: 20),
          Flexible(child: Text(text)),
        ],
      ),
      'Row + Expanded': (text) => Row(
        spacing: 8,
        children: [
          Icon(MdiIcons.shieldAccount, size: 20),
          Expanded(child: Text(text)),
        ],
      ),
    };

    for (final MapEntry(key: shape, value: flexibleChild) in shapes.entries) {
      for (final size in const [Size(1600, 1200), Size(400, 800)]) {
        testWidgets('$shape renders without error and wraps only in the picker at $size', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await pumpThemedApp(
            tester,
            Center(
              child: SizedBox(
                width: 300,
                child: LayrzSelectInput<String>(
                  itemExtent: 52,
                  labelText: 'Categoria',
                  value: 'long',
                  items: [
                    LayrzSelectItem<String>(
                      value: 'long',
                      searchableStrings: const {longLabel},
                      child: flexibleChild(longLabel),
                    ),
                    LayrzSelectItem<String>(
                      value: 'u',
                      searchableStrings: const {'Universal'},
                      child: flexibleChild('Universal'),
                    ),
                  ],
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          final fieldParagraph = tester.renderObject<RenderParagraph>(find.text(longLabel));
          expect(_lineCount(fieldParagraph), 1, reason: 'the closed field keeps the label on one line');

          await tester.tap(find.byType(LayrzSelectInput<String>));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          final pickerParagraphs = tester
              .renderObjectList<RenderParagraph>(find.text(longLabel))
              .where((p) => _lineCount(p) > 1);
          expect(pickerParagraphs, isNotEmpty, reason: 'the picker wraps the label to show it in full');
          expect(pickerParagraphs.first.didExceedMaxLines, isFalse);
        });
      }
    }
  });
}
